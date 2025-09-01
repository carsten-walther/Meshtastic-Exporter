#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.RANGE_TEST_APP)
class RangeTestAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received RANGE_TEST_APP packet")
        # Node configuration update is now handled by the database timestamps
        pass  # NOTE: This portnum traffic is not sent to the public MQTT starting at firmware version 2.2.9
