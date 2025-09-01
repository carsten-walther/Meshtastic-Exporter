#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.portnums_pb2 import PortNum
from meshtastic.protobuf.storeforward_pb2 import StoreAndForward

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.STORE_FORWARD_APP)
class StoreForwardAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received STORE_FORWARD_APP packet")
        store_and_forward = StoreAndForward()
        try:
            store_and_forward.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse STORE_FORWARD_APP packet: {e}")
            return
