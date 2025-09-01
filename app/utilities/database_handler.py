#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

from datetime import datetime
from typing import Dict, Any

from mysql.connector.pooling import MySQLConnectionPool


class DatabaseHandler:
    def __init__(self, db_pool: MySQLConnectionPool):
        self.db_pool = db_pool

    def get_connection(self):
        return self.db_pool.get_connection()

    def release_connection(self, conn):
        self.db_pool.get_connection().close()

    def execute_db_operation(self, operation):
        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                return operation(cur, conn)

    def store_device_metrics(self, node_id: str, metrics: Dict[str, Any]):
        """Store device metrics"""
        if not metrics:
            return

        # Get column names (excluding time and node_id which are always present)
        columns = ["time", "node_id"]
        values = [datetime.now(), node_id]

        # Add all metrics dynamically
        for key, value in metrics.items():
            columns.append(key)
            values.append(value)

        # Build the SQL query dynamically
        columns_str = ", ".join(columns)
        placeholders = ", ".join(["%s"] * len(values))

        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                cur.execute(f"""
                    INSERT INTO device_metrics (
                        {columns_str}
                    ) VALUES (
                        {placeholders}
                    )
                """, values)
                conn.commit()

    def store_environment_metrics(self, node_id: str, metrics: Dict[str, Any]):
        """Store environment metrics"""
        if not metrics:
            return

        # Get column names (excluding time and node_id which are always present)
        columns = ["time", "node_id"]
        values = [datetime.now(), node_id]

        # Add all metrics dynamically
        for key, value in metrics.items():
            columns.append(key)
            values.append(value)

        # Build the SQL query dynamically
        columns_str = ", ".join(columns)
        placeholders = ", ".join(["%s"] * len(values))

        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                cur.execute(f"""
                    INSERT INTO environment_metrics (
                        {columns_str}
                    ) VALUES (
                        {placeholders}
                    )
                """, values)
                conn.commit()

    def store_air_quality_metrics(self, node_id: str, metrics: Dict[str, Any]):
        """Store air quality metrics"""
        if not metrics:
            return

        # Get column names (excluding time and node_id which are always present)
        columns = ["time", "node_id"]
        values = [datetime.now(), node_id]

        # Add all metrics dynamically
        for key, value in metrics.items():
            columns.append(key)
            values.append(value)

        # Build the SQL query dynamically
        columns_str = ", ".join(columns)
        placeholders = ", ".join(["%s"] * len(values))

        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                cur.execute(f"""
                    INSERT INTO air_quality_metrics (
                        {columns_str}
                    ) VALUES (
                        {placeholders}
                    )
                """, values)
                conn.commit()

    def store_power_metrics(self, node_id: str, metrics: Dict[str, Any]):
        """Store power metrics"""
        if not metrics:
            return

        # Get column names (excluding time and node_id which are always present)
        columns = ["time", "node_id"]
        values = [datetime.now(), node_id]

        # Add all metrics dynamically
        for key, value in metrics.items():
            columns.append(key)
            values.append(value)

        # Build the SQL query dynamically
        columns_str = ", ".join(columns)
        placeholders = ", ".join(["%s"] * len(values))

        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                cur.execute(f"""
                    INSERT INTO power_metrics (
                        {columns_str}
                    ) VALUES (
                        {placeholders}
                    )
                """, values)
                conn.commit()

    def store_pax_counter_metrics(self, node_id: str, metrics: Dict[str, Any]):
        """Store PAX counter metrics"""
        if not metrics:
            return

        # Get column names (excluding time and node_id which are always present)
        columns = ["time", "node_id"]
        values = [datetime.now(), node_id]

        # Add all metrics dynamically
        for key, value in metrics.items():
            columns.append(key)
            values.append(value)

        # Build the SQL query dynamically
        columns_str = ", ".join(columns)
        placeholders = ", ".join(["%s"] * len(values))

        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                cur.execute(f"""
                    INSERT INTO pax_counter_metrics (
                        {columns_str}
                    ) VALUES (
                        {placeholders}
                    )
                """, values)
                conn.commit()

    def store_mesh_packet_metrics(self, source_id: str, destination_id: str, metrics: Dict[str, Any]):
        """Store mesh packet metrics"""
        if not metrics:
            return

        # Get column names (excluding time, source_id, and destination_id which are always present)
        columns = ["time", "source_id", "destination_id"]
        values = [datetime.now(), source_id, destination_id]

        # Add all metrics dynamically
        for key, value in metrics.items():
            columns.append(key)
            values.append(value)

        # Build the SQL query dynamically
        columns_str = ", ".join(columns)
        placeholders = ", ".join(["%s"] * len(values))

        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                # Check if source_id exists in node_details, if not insert it
                cur.execute("SELECT 1 FROM node_details WHERE node_id = %s", (source_id,))
                if not cur.fetchone():
                    # Insert broadcast node for source_id
                    if source_id == "4294967295" or source_id == "1":  # Broadcast addresses
                        cur.execute("""
                                    INSERT INTO node_details (node_id, short_name, long_name, hardware_model, role)
                                    VALUES (%s, %s, %s, %s, %s)
                                    ON DUPLICATE KEY UPDATE node_id=node_id
                                    """, (source_id, 'Broadcast', 'Broadcast', 'BROADCAST', 'BROADCAST'))
                    else:
                        # Insert unknown node for source_id
                        cur.execute("""
                                    INSERT INTO node_details (node_id, short_name, long_name)
                                    VALUES (%s, %s, %s)
                                    ON DUPLICATE KEY UPDATE node_id=node_id
                                    """, (source_id, 'Unknown', 'Unknown'))

                # Check if destination_id exists in node_details, if not insert it
                cur.execute("SELECT 1 FROM node_details WHERE node_id = %s", (destination_id,))
                if not cur.fetchone():
                    # Insert broadcast node for destination_id
                    if destination_id == "4294967295" or destination_id == "1":  # Broadcast addresses
                        cur.execute("""
                                    INSERT INTO node_details (node_id, short_name, long_name, hardware_model, role)
                                    VALUES (%s, %s, %s, %s, %s)
                                    ON DUPLICATE KEY UPDATE node_id=node_id
                                    """, (destination_id, 'Broadcast', 'Broadcast', 'BROADCAST', 'BROADCAST'))
                    else:
                        # Insert unknown node for destination_id
                        cur.execute("""
                                    INSERT INTO node_details (node_id, short_name, long_name)
                                    VALUES (%s, %s, %s)
                                    ON DUPLICATE KEY UPDATE node_id=node_id
                                    """, (destination_id, 'Unknown', 'Unknown'))

                # Now insert into mesh_packet_metrics
                cur.execute(f"""
                    INSERT INTO mesh_packet_metrics (
                        {columns_str}
                    ) VALUES (
                        {placeholders}
                    )
                """, values)
                conn.commit()

    def get_latest_metrics(self, node_id: str) -> Dict[str, Any]:
        """Get the latest metrics for a node from the node_telemetry view"""
        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                cur.execute("""
                            SELECT *
                            FROM node_telemetry
                            WHERE node_id = %s
                            """, (node_id,))

                columns = [desc[0] for desc in cur.description]
                result = cur.fetchone()

                if result:
                    return dict(zip(columns, result))
                return {}

    def update_from_device(self, nodes):
        if not nodes:
            return None

        with self.db_pool.get_connection() as conn:
            with conn.cursor(buffered=True) as cur:
                for node in nodes:
                    # Check if source_id exists in node_details, if not insert it
                    cur.execute("SELECT 1 FROM node_details WHERE node_id = %s", (node.num,))

                    #longitude = 0
                    #if node.position.longitude:
                    #    longitude = int(node.position.longitude / 10e-7)

                    #latitude = 0
                    #if node.position.latitude:
                    #    latitude = int(node.position.latitude / 10e-7)

                    #altitude = 0
                    #if node.position.altitude:
                    #    altitude = node.position.altitude

                    if not cur.fetchone():
                        # Insert unknown node for node.num
                        cur.execute("""
                                    INSERT INTO node_details (node_id, short_name, long_name, hardware_model, role, longitude, latitude, altitude)
                                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                                    ON DUPLICATE KEY UPDATE node_id=node_id
                                    """, (node.num, node.user.shortName, node.user.longName, node.user.hwModel,
                                          node.user.role, node.position.longitude, node.position.latitude, node.position.altitude,))
                    else:
                        cur.execute("""
                                    UPDATE node_details
                                    SET short_name = %s, 
                                        long_name = %s, 
                                        hardware_model = %s, 
                                        role = %s, 
                                        longitude = %s, 
                                        latitude = %s, 
                                        altitude = %s,
                                        updated_at = %s
                                    WHERE node_id = %s
                                    """, (node.user.shortName, node.user.longName, node.user.hwModel,
                                          node.user.role, node.position.longitude, node.position.latitude, node.position.altitude, datetime.now().isoformat(), node.num))
                    conn.commit()
