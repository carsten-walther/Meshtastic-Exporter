#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.mesh_pb2 import NeighborInfo
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.NEIGHBORINFO_APP)
class NeighborInfoAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received NEIGHBORINFO_APP packet")
        neighbor_info = NeighborInfo()
        try:
            neighbor_info.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse NEIGHBORINFO_APP packet: {e}")
            return
        self.update_node_neighbors(neighbor_info, client_details)

    def update_node_neighbors(self, neighbor_info: NeighborInfo, client_details: ClientDetails):
        def operation(cur, conn):
            new_neighbor_ids = [str(neighbor.node_id) for neighbor in neighbor_info.neighbors]
            if new_neighbor_ids:
                placeholders = ','.join(['%s'] * len(new_neighbor_ids))
                cur.execute(f"""
                    DELETE FROM node_neighbors 
                    WHERE node_id = %s AND neighbor_id NOT IN ({placeholders})
                """, (client_details.node_id, *new_neighbor_ids))
            else:
                cur.execute("DELETE FROM node_neighbors WHERE node_id = %s", (client_details.node_id,))

            for neighbor in neighbor_info.neighbors:
                cur.execute("""
                    WITH upsert AS (
                        INSERT INTO node_neighbors (node_id, neighbor_id, snr)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (node_id, neighbor_id)
                        DO UPDATE SET snr = EXCLUDED.snr
                        RETURNING node_id, neighbor_id
                    )
                    INSERT INTO node_details (node_id)
                    SELECT node_id FROM upsert
                    WHERE NOT EXISTS (SELECT 1 FROM node_details WHERE node_id = upsert.node_id)
                    UNION
                    SELECT neighbor_id FROM upsert
                    WHERE NOT EXISTS (SELECT 1 FROM node_details WHERE node_id = upsert.neighbor_id)
                    ON CONFLICT (node_id) DO NOTHING;
                """, (str(client_details.node_id), str(neighbor.node_id), float(neighbor.snr)))

            conn.commit()

        self.db_handler.execute_db_operation(operation)
