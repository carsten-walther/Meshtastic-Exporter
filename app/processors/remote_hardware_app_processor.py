#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.portnums_pb2 import PortNum
from meshtastic.protobuf.remote_hardware_pb2 import HardwareMessage

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.REMOTE_HARDWARE_APP)
class RemoteHardwareAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received REMOTE_HARDWARE_APP packet")
        hardware_message = HardwareMessage()
        try:
            hardware_message.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse REMOTE_HARDWARE_APP packet: {e}")
            return
