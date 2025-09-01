#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.AUDIO_APP)
class AudioAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received AUDIO_APP packet")
        pass  # NOTE: Audio packet. should probably be processed
