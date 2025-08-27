# !/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
import os
import time
from datetime import datetime, timezone
from typing import Optional

import meshtastic
import meshtastic.ble_interface
import meshtastic.serial_interface
import meshtastic.tcp_interface

from app.utilities.node_info import NodeInfo, NodeInfoUser, NodeInfoPosition, NodeInfoDeviceMetrics
from app.utilities.packet import Packet, PacketDecoded


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

    @staticmethod
    def node_info(node_data: dict) -> Optional[NodeInfo]:
        try:
            def safe_timestamp(timestamp):
                if timestamp and timestamp != 0:
                    return datetime.fromtimestamp(timestamp)
                return None

            return NodeInfo(
                num=int(node_data.get('num', 0)),
                user=NodeInfoUser(
                    id=node_data.get('user', {}).get('id', 'Unknown'),
                    longName=node_data.get('user', {}).get('longName', 'Unknown'),
                    shortName=node_data.get('user', {}).get('shortName', 'Unknown'),
                    macaddr=node_data.get('user', {}).get('macaddr'),
                    hwModel=node_data.get('user', {}).get('hwModel'),
                    role=node_data.get('user', {}).get('role'),
                    publicKey=node_data.get('user', {}).get('publicKey'),
                    isUnmessagable=node_data.get('user', {}).get('isUnmessagable'),
                ),
                position=NodeInfoPosition(
                    latitudeI=node_data.get('position', {}).get('latitudeI'),
                    longitudeI=node_data.get('position', {}).get('longitudeI'),
                    altitude=node_data.get('position', {}).get('altitude'),
                    time=safe_timestamp(node_data.get('position', {}).get('time')),
                    locationSource=node_data.get('position', {}).get('locationSource'),
                    latitude=node_data.get('position', {}).get('latitude'),
                    longitude=node_data.get('position', {}).get('longitude'),
                ),
                deviceMetrics=NodeInfoDeviceMetrics(
                    batteryLevel=node_data.get('deviceMetrics', {}).get('batteryLevel'),
                    voltage=node_data.get('deviceMetrics', {}).get('voltage'),
                    channelUtilization=node_data.get('deviceMetrics', {}).get('channelUtilization'),
                    airUtilTx=node_data.get('deviceMetrics', {}).get('airUtilTx'),
                    uptimeSeconds=node_data.get('deviceMetrics', {}).get('uptimeSeconds'),
                ),
                snr=node_data.get('snr'),
                lastHeard=safe_timestamp(node_data.get('lastHeard')),
                hopsAway=node_data.get('hopsAway'),
            )

        except Exception as e:
            logging.error(f"Error parsing node info: {str(e)}")
            return None

    @staticmethod
    def packet(packet: dict):
        try:
            def safe_int(value):
                if value is not None:
                    return int(value)
                return None

            rx_time = packet.get('rxTime')
            if rx_time and rx_time != 0:
                rx_time_dt = datetime.fromtimestamp(rx_time, timezone.utc)
            else:
                rx_time_dt = datetime.now(timezone.utc)

            return Packet(
                id=int(packet.get('id', 0)),
                nodeFrom=packet.get('from', 'Unknown'),
                fromId=packet.get('fromId', 'Unknown'),
                nodeTo=packet.get('to', 'Unknown'),
                toId=packet.get('toId', 'Unknown'),
                decoded=PacketDecoded(
                    portnum=packet.get('decoded', {}).get('portnum', 'UNKNOWN_APP'),
                    payload=packet.get('decoded', {}).get('payload', ''),
                    text=packet.get('decoded', {}).get('text', ''),
                    bitfield=safe_int(packet.get('decoded', {}).get('bitfield')),
                ),
                rxTime=rx_time_dt,
                rxSnr=float(packet.get('rxSnr', 0.0)),
                rxRssi=int(packet.get('rxRssi', 0)),
                channel=packet.get('channel'),
                wantAck=packet.get('wantAck'),
                hopLimit=safe_int(packet.get('hopLimit')),
                hopStart=safe_int(packet.get('hopStart')),
                publicKey=packet.get('publicKey'),
                pkiEncrypted=packet.get('pkiEncrypted'),
                nextHop=packet.get('nextHop'),
                relayNode=packet.get('relayNode'),
            )

        except Exception as e:
            logging.error(f"Error processing packet: {str(e)}")
            return None
