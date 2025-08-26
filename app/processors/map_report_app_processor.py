#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.mqtt_pb2 import MapReport
from meshtastic.protobuf.portnums_pb2 import PortNum

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.MAP_REPORT_APP)
class MapReportAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received MAP_REPORT_APP packet")
        # Node configuration update is now handled by the database timestamps
        map_report = MapReport()
        try:
            map_report.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse MAP_REPORT_APP packet: {e}")
            return
