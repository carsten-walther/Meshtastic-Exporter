#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
import os

from meshtastic.protobuf.portnums_pb2 import PortNum


class ProcessorRegistry:
    _registry = {}
    _initialized = False

    @classmethod
    def register_processor(cls, port_num):
        def inner_wrapper(wrapped_class):
            if PortNum.DESCRIPTOR.values_by_number[port_num].name in os.getenv('EXPORTER_MESSAGE_TYPES_TO_FILTER',
                                                                               '').split(','):
                logging.info(f"Processor for port_num {port_num} is filtered out")
                return wrapped_class

            cls._registry[port_num] = wrapped_class
            return wrapped_class

        return inner_wrapper

    @classmethod
    def get_processor(cls, port_num):
        # Lazy initialization
        if not cls._initialized:
            cls._initialize_processors()
            cls._initialized = True

        from app.processors.unknown_app_processor import UnknownAppProcessor
        return cls._registry.get(port_num, UnknownAppProcessor)

    @classmethod
    def _initialize_processors(cls):
        pass
