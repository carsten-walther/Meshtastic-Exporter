#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.paxcount_pb2 import Paxcount
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.PAXCOUNTER_APP)
class PaxCounterAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received PAXCOUNTER_APP packet")
        # Node configuration update is now handled by the database timestamps
        paxcounter = Paxcount()
        try:
            paxcounter.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse PAXCOUNTER_APP packet: {e}")
            return

        # Store PAX counter metrics in TimescaleDB
        self.db_handler.store_pax_counter_metrics(client_details.node_id, {
            'wifi_stations': getattr(paxcounter, 'wifi', 0),
            'ble_beacons': getattr(paxcounter, 'ble', 0)
        })
