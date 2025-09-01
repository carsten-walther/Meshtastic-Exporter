#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

from abc import ABC, abstractmethod

from mysql.connector.pooling import MySQLConnectionPool

from app.client.client_details import ClientDetails
from app.utilities.database_handler import DatabaseHandler


class Processor(ABC):
    def __init__(self, db_pool: MySQLConnectionPool):
        self.db_pool = db_pool
        self.db_handler = DatabaseHandler(db_pool)

    @abstractmethod
    def process(self, payload: bytes, client_details: ClientDetails):
        pass
