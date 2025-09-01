#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.mesh_pb2 import Routing
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.ROUTING_APP)
class RoutingAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received ROUTING_APP packet")
        routing = Routing()
        try:
            routing.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse ROUTING_APP packet: {e}")
            return
        # No need to store routing metrics in TimescaleDB
        pass

    @staticmethod
    def get_error_name_from_routing(error_code):
        for name, value in Routing.Error.__dict__.items():
            if isinstance(value, int) and value == error_code:
                return name
        return 'UNKNOWN_ERROR'
