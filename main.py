#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
import os
import time

from dotenv import load_dotenv
from mysql.connector.pooling import MySQLConnectionPool
from pubsub import pub

from app.utilities.database_handler import DatabaseHandler
from app.utilities.interface import Interface


#
# https://github.com/tcivie/meshtastic-metrics-exporter
#

def handle_message(packet):
    try:
        packet = interface.packet(packet)
        logging.info(f"Received packet from node: {packet.nodeFrom} with portnum: {packet.decoded.portnum}")
        with connection_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                cur.execute("""
                            SELECT id FROM messages WHERE id = %s
                            """, (str(packet.id),))
                if cur.fetchone() is not None:
                    logging.debug(f"Packet {packet.id} already processed")
                    return
                cur.execute("""
                            INSERT INTO messages (id, received_at) 
                            VALUES (%s, NOW()) ON DUPLICATE KEY UPDATE id=id
                            """, (str(packet.id),))
                conn.commit()
        processor.process(packet)
    except Exception as e:
        logging.error(f"Failed to handle message: {e}")
        return
    pass


if __name__ == '__main__':
    load_dotenv()

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s | %(levelname)s\t| %(message)s - %(pathname)s:%(lineno)d',
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

    # Update database with discovered nodes from device
    db_handler = DatabaseHandler(connection_pool)
    db_handler.update_from_device(interface.discover_nodes())


    def on_connection_established(interface, topic=pub.AUTO_TOPIC):
        logging.info(f"Connection established")
    pub.subscribe(on_connection_established, "meshtastic.connection.established")


    def on_connection_lost(interface, topic=pub.AUTO_TOPIC):
        logging.error(f"Connection lost")
    pub.subscribe(on_connection_lost, "meshtastic.connection.lost")


    def on_node_updated(interface, topic=pub.AUTO_TOPIC):
        logging.info(f"Node updated")
    pub.subscribe(on_node_updated, "meshtastic.node.updated(node=NodeInfo)")


    def on_receive(packet, interface):
        handle_message(packet)
    pub.subscribe(on_receive, "meshtastic.receive")

    try:
        while True:
            time.sleep(1)

    except KeyboardInterrupt:
        logging.info("Shutting down")
        interface.disconnect()
