#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.portnums_pb2 import PortNum

from app.processors.unknown_app_processor import UnknownAppProcessor


class ProcessorRegistry:
    _registry = {}
    _initialized = False

    def __init__(self):
        if not self._initialized:
            self._initialize_processors()
            self._initialized = True

    @classmethod
    def register_processor(cls, port_num):
        def inner_wrapper(wrapped_class):
            cls._registry[PortNum.DESCRIPTOR.values_by_number[port_num].name] = wrapped_class
            return wrapped_class

        return inner_wrapper

    @classmethod
    def get_processor(cls, port_num):
        return cls._registry.get(port_num, UnknownAppProcessor)

    @classmethod
    def _initialize_processors(cls):
        """Import all processor modules to trigger decorator registration"""
        try:
            from app.processors import admin_app_processor
            from app.processors import atak_forwarder_processor
            from app.processors import atak_plugin_processor
            from app.processors import audio_app_processor
            from app.processors import detection_sensor_app_processor
            from app.processors import ip_tunnel_app_processor
            from app.processors import max_processor
            from app.processors import map_report_app_processor
            from app.processors import neighbor_info_app_processor
            from app.processors import node_info_app_processor
            from app.processors import pax_aounter_app_processor
            from app.processors import position_app_processor
            from app.processors import private_app_processor
            from app.processors import range_test_app_processor
            from app.processors import remote_hardware_app_processor
            from app.processors import reply_app_processor
            from app.processors import routing_app_processor
            from app.processors import serial_app_processor
            from app.processors import simulator_app_processor
            from app.processors import store_forward_app_processor
            from app.processors import telemetry_app_processor
            from app.processors import text_message_app_rocessor
            from app.processors import text_message_compressed_app_processor
            from app.processors import trace_route_app_processor
            from app.processors import waypoint_app_processor
            from app.processors import zps_app_processor

            logging.info(f"Initialized {len(cls._registry)} processors: {list(cls._registry.keys())}")
        except ImportError as e:
            logging.error(f"Failed to import processors: {e}")
