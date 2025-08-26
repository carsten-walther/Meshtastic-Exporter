#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.mesh_pb2 import RouteDiscovery
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.TRACEROUTE_APP)
class TraceRouteAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received TRACEROUTE_APP packet")
        traceroute = RouteDiscovery()
        try:
            traceroute.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse TRACEROUTE_APP packet: {e}")
            return
        # No need to store route discovery metrics in TimescaleDB
        pass
