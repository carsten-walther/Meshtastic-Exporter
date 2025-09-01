#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.ATAK_PLUGIN)
class AtakPluginProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received ATAK_PLUGIN packet")
        pass  # NOTE: ATAK Plugin
