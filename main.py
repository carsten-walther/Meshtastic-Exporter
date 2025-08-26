#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
import time
import os

from meshtastic.protobuf.mesh_pb2 import MeshPacket, Data
from meshtastic.protobuf.portnums_pb2 import PortNum

from mysql.connector.pooling import MySQLConnectionPool
from dotenv import load_dotenv
from pubsub import pub

from app.utilities.interface import Interface

#
# https://github.com/tcivie/meshtastic-metrics-exporter
#

def string_to_portnum(portnum_string):
    """Konvertiert einen PortNum-String zu einem PortNum-Enum"""
    try:
        # Versuche direkten Zugriff auf das Enum
        if hasattr(PortNum, portnum_string):
            return getattr(PortNum, portnum_string)

        # Falls der String bereits numerisch ist
        if portnum_string.isdigit():
            return int(portnum_string)

        # Mapping für häufige String-Varianten
        portnum_mapping = {
            'TEXT_MESSAGE_APP': PortNum.TEXT_MESSAGE_APP,
            'NODEINFO_APP': PortNum.NODEINFO_APP,
            'POSITION_APP': PortNum.POSITION_APP,
            'TELEMETRY_APP': PortNum.TELEMETRY_APP,
            'ROUTING_APP': PortNum.ROUTING_APP,
            'ADMIN_APP': PortNum.ADMIN_APP,
            'WAYPOINT_APP': PortNum.WAYPOINT_APP,
            'AUDIO_APP': PortNum.AUDIO_APP,
            'DETECTION_SENSOR_APP': PortNum.DETECTION_SENSOR_APP,
            'REPLY_APP': PortNum.REPLY_APP,
            'IP_TUNNEL_APP': PortNum.IP_TUNNEL_APP,
            'PAXCOUNTER_APP': PortNum.PAXCOUNTER_APP,
            'SERIAL_APP': PortNum.SERIAL_APP,
            'STORE_FORWARD_APP': PortNum.STORE_FORWARD_APP,
            'RANGE_TEST_APP': PortNum.RANGE_TEST_APP,
            'TRACEROUTE_APP': PortNum.TRACEROUTE_APP,
            'NEIGHBORINFO_APP': PortNum.NEIGHBORINFO_APP,
            'ATAK_PLUGIN': PortNum.ATAK_PLUGIN,
            'MAP_REPORT_APP': PortNum.MAP_REPORT_APP,
            'PRIVATE_APP': PortNum.PRIVATE_APP,
            'ATAK_FORWARDER': PortNum.ATAK_FORWARDER,
        }

        return portnum_mapping.get(portnum_string.upper(), PortNum.UNKNOWN_APP)

    except Exception as e:
        logging.warning(f"Failed to convert portnum '{portnum_string}': {e}")
        return PortNum.UNKNOWN_APP

def dict_to_mesh_packet(packet_dict):
    mesh_packet = MeshPacket()

    field_mapping = {
        'to': ('to', int, 0),
        'from': ('from', int, 0),
        'id': ('id', int, 0),
        'rx_time': ('rx_time', int, 0),
        'rx_snr': ('rx_snr', float, 0.0),
        'hop_limit': ('hop_limit', int, 0),
        'rx_rssi': ('rx_rssi', int, 0),
        'hop_start': ('hop_start', int, 0),
        'channel': ('channel', int, 0),
        'want_ack': ('want_ack', bool, False),
        'via_mqtt': ('via_mqtt', bool, False),
    }

    for key, (attr, type_func, default) in field_mapping.items():
        if key in packet_dict:
            try:
                if attr == 'from':
                    setattr(mesh_packet, 'from', type_func(packet_dict[key]))
                else:
                    setattr(mesh_packet, attr, type_func(packet_dict[key]))
            except (ValueError, TypeError) as e:
                logging.warning(f"Failed to set {attr}: {e}")
                setattr(mesh_packet, attr, default)

    if 'decoded' in packet_dict and packet_dict['decoded']:
        data = Data()
        decoded = packet_dict['decoded']

        if 'portnum' in decoded:
            data.portnum = string_to_portnum(decoded['portnum'])
        if 'payload' in decoded:
            payload = decoded['payload']
            if isinstance(payload, str):
                data.payload = payload.encode('utf-8')
            elif isinstance(payload, bytes):
                data.payload = payload

        mesh_packet.decoded.CopyFrom(data)

    # Encrypted-Daten
    if 'encrypted' in packet_dict and packet_dict['encrypted']:
        if isinstance(packet_dict['encrypted'], str):
            mesh_packet.encrypted = packet_dict['encrypted'].encode('utf-8')
        else:
            mesh_packet.encrypted = bytes(packet_dict['encrypted'])

    print(mesh_packet)
    return mesh_packet


def connection_established():
    logging.info(f"Connection established")

def connection_lost():
    logging.error(f"Connection lost")

def node_updated():
    logging.info(f"Node updated")

def receive(packet, interface):
    logging.info(f"New packet received")
    try:
        mesh_packet = dict_to_mesh_packet(packet)
        with connection_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                cur.execute("""
                            SELECT id FROM messages WHERE id = %s
                            """, (str(mesh_packet.id),))
                if cur.fetchone() is not None:
                    logging.debug(f"Packet {mesh_packet.id} already processed")
                    return

                cur.execute("""
                            INSERT INTO messages (id, received_at) 
                            VALUES (%s, NOW()) ON DUPLICATE KEY UPDATE id=id
                            """, (str(mesh_packet.id),))
                conn.commit()
        processor.process(mesh_packet)
    except Exception as e:
        logging.error(f"Failed to handle message: {e}")
        return
    pass

if __name__ == '__main__':
    load_dotenv()

    logging.basicConfig(
        level=logging.INFO,
        format='[%(asctime)s] %(levelname)s - %(message)s - p%(process)s {%(pathname)s:%(lineno)d}',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # We have to load_dotenv before we can import MessageProcessor to allow filtering of message types
    from app.processors.message_processor import MessageProcessor

    # Setup a connection pool
    connection_pool = MySQLConnectionPool(
        host=os.environ.get("MYSQL_HOST"),
        port=os.environ.get("MYSQL_PORT"),
        database=os.environ.get("MYSQL_TABLE"),
        user=os.environ.get("MYSQL_USER"),
        password=os.environ.get("MYSQL_PASSWORD")
    )

    # Node configuration is now handled by the database timestamps
    # No need for Prometheus exporter anymore

    # Configure the Processor
    processor = MessageProcessor(connection_pool)

    # Load interface and connect
    interface = Interface()
    interface.connect()

    def on_connection_established(interface, topic=pub.AUTO_TOPIC):
        connection_established()
    pub.subscribe(on_connection_established, "meshtastic.connection.established")

    def on_connection_lost(interface, topic=pub.AUTO_TOPIC):
        connection_lost()
    pub.subscribe(on_connection_lost, "meshtastic.connection.lost")

    def on_node_updated(interface, topic=pub.AUTO_TOPIC):
        node_updated()
    pub.subscribe(on_node_updated, "meshtastic.node.updated(node=NodeInfo)")

    def on_receive(packet, interface):
        receive(packet, interface)
    pub.subscribe(on_receive, "meshtastic.receive")

    try:
        while True:
            time.sleep(1)

    except KeyboardInterrupt:
        logging.info("Shutting down")
        interface.disconnect()
