#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
import sys

from meshtastic.protobuf.mesh_pb2 import MeshPacket, HardwareModel
from meshtastic.protobuf.portnums_pb2 import PortNum
from mysql.connector.pooling import MySQLConnectionPool

from app.client.client_details import ClientDetails
from app.processors.processor_registry import ProcessorRegistry
from app.utilities.database_handler import DatabaseHandler


class MessageProcessor:
    def __init__(self, db_pool: MySQLConnectionPool):
        self.db_pool = db_pool
        self.db_handler = DatabaseHandler(db_pool)
        self.processor_registry = ProcessorRegistry()

    def process(self, mesh_packet: MeshPacket):
        try:

            print(mesh_packet)

        except Exception as e:
            logging.warning(f"Failed to process message: {e}")
            return

    @staticmethod
    def get_port_name_from_portnum(port_num):
        descriptor = PortNum.DESCRIPTOR
        for enum_value in descriptor.values:
            if enum_value.number == port_num:
                return enum_value.name
        return 'UNKNOWN_PORT'

    def process_simple_packet_details(self, destination_client_details, mesh_packet: MeshPacket, port_num,
                                      source_client_details):
        # Store mesh packet metrics
        self.db_handler.store_mesh_packet_metrics(
            source_client_details.node_id,
            destination_client_details.node_id,
            {
                'portnum': self.get_port_name_from_portnum(port_num),
                'packet_id': mesh_packet.id,
                'channel': mesh_packet.channel,
                'rx_time': mesh_packet.rx_time,
                'rx_snr': mesh_packet.rx_snr,
                'rx_rssi': mesh_packet.rx_rssi,
                'hop_limit': mesh_packet.hop_limit,
                'hop_start': mesh_packet.hop_start,
                'want_ack': mesh_packet.want_ack,
                'via_mqtt': mesh_packet.via_mqtt,
                'message_size_bytes': sys.getsizeof(mesh_packet)
            }
        )

    def _get_client_details(self, node_id: int) -> ClientDetails:
        if node_id == 4294967295 or node_id == 1:  # FFFFFFFF or 1 (Broadcast)
            node_id_str = str(node_id)
            # Insert the broadcast node into node_details if it doesn't exist
            with self.db_pool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                                INSERT INTO node_details (node_id, short_name, long_name, hardware_model, role)
                                VALUES (%s, %s, %s, %s, %s)
                                ON CONFLICT (node_id) DO NOTHING
                                """, (node_id_str, 'Broadcast', 'Broadcast', 'BROADCAST', 'BROADCAST'))
                    conn.commit()
            return ClientDetails(node_id=node_id_str, short_name='Broadcast', long_name='Broadcast')
        node_id_str = str(node_id)  # Convert the integer to a string
        with self.db_pool.get_connection() as conn:
            with conn.cursor() as cur:
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
                        VALUES (%s, %s, %s, %s, %s)
                        RETURNING node_id, short_name, long_name, hardware_model, role;
                    """, (node_id_str, 'Unknown', 'Unknown', HardwareModel.UNSET, None))
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
