#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
from datetime import datetime

from meshtastic.protobuf.mesh_pb2 import Position
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.POSITION_APP)
class PositionAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received POSITION_APP packet")
        position = Position()
        try:
            position.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse POSITION_APP packet: {e}")
            return
        if position.latitude_i != 0 and position.longitude_i != 0:
            def db_operation(cur, conn):
                cur.execute("""
                            UPDATE node_details
                            SET latitude = %s,
                                longitude = %s,
                                altitude = %s,
                                precision_bits = %s,
                                updated_at = %s
                            WHERE node_id = %s
                            """, (position.latitude_i, position.longitude_i, position.altitude, position.precision_bits,
                                  datetime.now().isoformat(), client_details.node_id))
                conn.commit()

            self.db_handler.execute_db_operation(db_operation)
        pass
