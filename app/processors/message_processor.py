#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
import sys

from meshtastic.protobuf.mesh_pb2 import HardwareModel
from mysql.connector.pooling import MySQLConnectionPool

from app.client.client_details import ClientDetails
from app.processors.processor_registry import ProcessorRegistry
from app.utilities.database_handler import DatabaseHandler
from app.utilities.packet import Packet


class MessageProcessor:
    def __init__(self, db_pool: MySQLConnectionPool):
        self.db_pool = db_pool
        self.db_handler = DatabaseHandler(db_pool)
        self.processor_registry = ProcessorRegistry()

    def process(self, mesh_packet: Packet):
        try:
            port_num = mesh_packet.decoded.portnum
            payload = mesh_packet.decoded.payload

            source_node_id = getattr(mesh_packet, 'nodeFrom')
            source_client_details = self._get_client_details(source_node_id)

            destination_node_id = getattr(mesh_packet, 'nodeTo')
            destination_client_details = self._get_client_details(destination_node_id)

            self.process_simple_packet_details(destination_client_details, mesh_packet, port_num, source_client_details)

            processor = ProcessorRegistry.get_processor(port_num)(self.db_pool)
            processor.process(payload, client_details=source_client_details)
        except Exception as e:
            logging.warning(f"Failed to process message: {e}")
            return

    def process_simple_packet_details(self, destination_client_details, mesh_packet: Packet, port_num,
                                      source_client_details):
        # Store mesh packet metrics
        self.db_handler.store_mesh_packet_metrics(
            source_client_details.node_id,
            destination_client_details.node_id,
            {
                'portnum': port_num,
                'packet_id': mesh_packet.id,
                'channel': mesh_packet.channel,
                'rx_time': mesh_packet.rxTime,
                'rx_snr': mesh_packet.rxSnr,
                'rx_rssi': mesh_packet.rxRssi,
                'hop_limit': mesh_packet.hopLimit,
                'hop_start': mesh_packet.hopStart,
                'want_ack': mesh_packet.wantAck,
                'via_mqtt': mesh_packet.viaMqtt,
                'message_size_bytes': sys.getsizeof(mesh_packet)
            }
        )

    def _get_client_details(self, node_id: int) -> ClientDetails:
        if node_id == 4294967295 or node_id == 1:  # FFFFFFFF or 1 (Broadcast)
            node_id_str = str(node_id)
            # Insert the broadcast node into node_details if it doesn't exist
            with self.db_pool.get_connection() as conn:
                with conn.cursor(buffered=True) as cur:
                    cur.execute("""
                                INSERT INTO node_details (node_id, short_name, long_name, hardware_model, role)
                                VALUES (%s, %s, %s, %s, %s)
                                ON DUPLICATE KEY UPDATE node_id=node_id
                                """, (node_id_str, 'Broadcast', 'Broadcast', 'BROADCAST', 'BROADCAST'))
                    conn.commit()
            return ClientDetails(node_id=node_id_str, short_name='Broadcast', long_name='Broadcast')
        node_id_str = str(node_id)  # Convert the integer to a string
        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                # First, try to select the existing record
                cur.execute("""
                            SELECT node_id, short_name, long_name, hardware_model, role 
                            FROM node_details 
                            WHERE node_id = %s;
                            """, (node_id_str,))
                result = cur.fetchone()

                if not result:
                    # If the client is not found, insert a new record
                    cur.execute("""
                                INSERT INTO node_details (node_id, short_name, long_name, hardware_model, role) 
                                VALUES (%s, %s, %s, %s, %s);
                                """, (node_id_str, 'Unknown', 'Unknown', HardwareModel.UNSET, None))
                    conn.commit()
                    # Return the new record
                    cur.execute("""
                                SELECT node_id, short_name, long_name, hardware_model, role FROM node_details 
                                WHERE node_id = %s;
                                """, (node_id_str,))
                    conn.commit()
                    result = cur.fetchone()

        # At this point, we should always have a result, either from SELECT or INSERT
        return ClientDetails(
            node_id=result[0],
            short_name=result[1],
            long_name=result[2],
            hardware_model=result[3],
            role=result[4]
        )
