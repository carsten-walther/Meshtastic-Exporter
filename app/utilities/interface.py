# !/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
import os
import meshtastic
import time

import meshtastic.ble_interface
import meshtastic.serial_interface
import meshtastic.tcp_interface


class Interface:

    def __init__(self):
        self.interface = None

    def connect(self):
        while True:
            try:
                if os.environ.get("INTERFACE") == 'serial':
                    self.interface = meshtastic.serial_interface.SerialInterface(os.environ.get("INTERFACE_PORT"))
                    logging.info(f"Connecting via {os.environ.get("INTERFACE")} on {os.environ.get("INTERFACE_PORT")}")

                elif os.environ.get("INTERFACE") == 'tcp':
                    self.interface = meshtastic.tcp_interface.TCPInterface(os.environ.get("INTERFACE_HOST"))
                    logging.info(f"Connecting via {os.environ.get("INTERFACE")} on {os.environ.get("INTERFACE_HOST")}")

                elif os.environ.get("INTERFACE") == 'ble':
                    self.interface = meshtastic.ble_interface.BLEInterface(os.environ.get("INTERFACE_ADDR"))
                    logging.info(f"Connecting via {os.environ.get("INTERFACE")} on {os.environ.get("INTERFACE_ADDR")}")

                return self.interface

            except PermissionError as e:
                logging.info(f"PermissionError: {e}. Retrying in 5 seconds...")
                time.sleep(5)

    def disconnect(self):
        if self.interface:
            try:
                self.interface.close()
                logging.info(f"Connection closed")
            except:
                pass
