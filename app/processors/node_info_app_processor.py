#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
from datetime import datetime

from meshtastic.protobuf.mesh_pb2 import User, HardwareModel
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.NODEINFO_APP)
class NodeInfoAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received NODEINFO_APP packet")
        user = User()
        try:
            user.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse NODEINFO_APP packet: {e}")
            return

        def db_operation(cur, conn):
            # First, try to select the existing record
            cur.execute("""
                SELECT short_name, long_name, hardware_model, role
                FROM node_details
                WHERE node_id = %s;
            """, (client_details.node_id,))
            existing_record = cur.fetchone()

            if existing_record:
                # If record exists, update only the fields that are provided in the new data
                update_fields = []
                update_values = []
                if user.short_name:
                    update_fields.append("short_name = %s")
                    update_values.append(user.short_name)
                if user.long_name:
                    update_fields.append("long_name = %s")
                    update_values.append(user.long_name)
                if user.hw_model != HardwareModel.UNSET:
                    update_fields.append("hardware_model = %s")
                    update_values.append(ClientDetails.get_hardware_model_name_from_code(user.hw_model))
                if user.role is not None:
                    update_fields.append("role = %s")
                    update_values.append(ClientDetails.get_role_name_from_role(user.role))

                if update_fields:
                    update_fields.append("updated_at = %s")
                    update_query = f"""
                        UPDATE node_details
                        SET {", ".join(update_fields)}
                        WHERE node_id = %s
                    """
                    cur.execute(update_query, update_values + [datetime.now().isoformat(), client_details.node_id])
            else:
                # If record doesn't exist, insert a new one
                cur.execute("""
                    INSERT INTO node_details (node_id, short_name, long_name, hardware_model, role)
                    VALUES (%s, %s, %s, %s, %s)
                """, (client_details.node_id, user.short_name, user.long_name,
                      ClientDetails.get_hardware_model_name_from_code(user.hw_model),
                      ClientDetails.get_role_name_from_role(user.role)))

            conn.commit()

        self.db_handler.execute_db_operation(db_operation)
