#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging
import time
import os

from mysql.connector.pooling import MySQLConnectionPool
from dotenv import load_dotenv

#
# https://github.com/tcivie/meshtastic-metrics-exporter
#

if __name__ == '__main__':
    load_dotenv()

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # We have to load_dotenv before we can import MessageProcessor to allow filtering of message types
    from app.processors.message_processor import MessageProcessor

    # Setup a connection pool
    connection_pool = MySQLConnectionPool(
        pool_name="mysql_pool",
        pool_size=1,
        pool_reset_session=True,
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

    try:
        while True:
            time.sleep(1)

    except KeyboardInterrupt:
        logging.info("Shutting down")
