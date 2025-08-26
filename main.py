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

def connection_established():
    logging.info(f"Connection established")

def connection_lost():
    logging.error(f"Connection lost")

def node_updated():
    logging.info(f"Node updated")

def receive(packet, interface):
    logging.info(f"New packet received")
    try:
        mesh_packet = MeshPacket()

        mesh_packet.to = int(packet.get('to', 0))
        mesh_packet.channel = int(packet.get('channel', 0))
        #mesh_packet.decoded = packet['decoded']
        mesh_packet.encrypted = bytes(packet.get('encrypted', b""))
        mesh_packet.id = int(packet.get('id', 0))
        mesh_packet.rx_time = int(packet.get('rx_time', 0))
        mesh_packet.rx_snr = float(packet.get('rx_snr', .0))
        mesh_packet.hop_limit = int(packet.get('hop_limit', 0))
        mesh_packet.want_ack = bool(packet.get('want_ack', True))
        #mesh_packet.priority = packet['priority']
        mesh_packet.rx_rssi = int(packet.get('rx_rssi', 0))
        #mesh_packet.delayed = packet['delayed']
        mesh_packet.via_mqtt = bool(packet.get('via_mqtt', False))
        mesh_packet.hop_start = int(packet.get('hop_start', 0))
        mesh_packet.public_key = bytes(packet.get('public_key', b""))
        mesh_packet.pki_encrypted = bool(packet.get('pki_encrypted', False))
        mesh_packet.next_hop = int(packet.get('next_hop', 0))
        mesh_packet.relay_node = int(packet.get('relay_node', 0))
        mesh_packet.tx_after = int(packet.get('tx_after', 0))
        #mesh_packet.transport_mechanism = packet['transport_mechanism']

        print(mesh_packet)

        with connection_pool.get_connection() as conn:
            with conn.cursor() as cur:
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
