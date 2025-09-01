#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.mesh_pb2 import Waypoint
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.WAYPOINT_APP)
class WaypointAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received WAYPOINT_APP packet")
        waypoint = Waypoint()
        try:
            waypoint.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse WAYPOINT_APP packet: {e}")
            return
