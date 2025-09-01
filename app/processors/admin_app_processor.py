#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.admin_pb2 import AdminMessage
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.ADMIN_APP)
class AdminAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received ADMIN_APP packet")
        admin_message = AdminMessage()
        try:
            admin_message.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse ADMIN_APP packet: {e}")
            return
