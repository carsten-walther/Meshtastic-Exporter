#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.TEXT_MESSAGE_APP)
class TextMessageAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received TEXT_MESSAGE_APP packet")
        decoded_message = payload.decode('utf-8')
        pass
