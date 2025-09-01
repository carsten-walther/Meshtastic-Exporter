#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

from app.client.client_details import ClientDetails
from app.processors.processor import Processor


class UnknownAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        return None
