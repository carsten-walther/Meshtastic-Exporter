-- MySQL Schema für Meshtastic Metrics Exporter
-- Ersetzt TimescaleDB PostgreSQL Schema

-- Enable Event Scheduler für automatische Bereinigung
SET GLOBAL event_scheduler = ON;

-- Create basic tables
CREATE TABLE IF NOT EXISTS messages
(
    id          TEXT,
    received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id(255))  -- TEXT als PRIMARY KEY benötigt Längenbegrenzung
);

-- Stored Procedure für Message Expiration (ersetzt PostgreSQL Function)
DELIMITER $$
CREATE PROCEDURE expire_old_messages()
BEGIN
    DELETE FROM messages WHERE received_at < DATE_SUB(NOW(), INTERVAL 1 MINUTE);
END$$
DELIMITER ;

-- Trigger für Message Expiration
DELIMITER $$
CREATE TRIGGER trigger_expire_old_messages
    AFTER INSERT ON messages
    FOR EACH ROW
BEGIN
    CALL expire_old_messages();
END$$
DELIMITER ;

-- Node Details Table
CREATE TABLE IF NOT EXISTS node_details
(
    node_id        VARCHAR(255) PRIMARY KEY,
    -- Base Data
    short_name     VARCHAR(255),
    long_name      VARCHAR(255),
    hardware_model VARCHAR(255),
    role           VARCHAR(255),
    mqtt_status    VARCHAR(255) DEFAULT 'none',
    -- Location Data
    longitude      INT,
    latitude       INT,
    altitude       INT,
    precision_val  INT,  -- 'precision' ist reserviertes Wort in MySQL
    -- SQL Data
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL
);

-- Node Neighbors Table
CREATE TABLE IF NOT EXISTS node_neighbors
(
    id          INT AUTO_INCREMENT PRIMARY KEY,  -- SERIAL = AUTO_INCREMENT
    node_id     VARCHAR(255),
    neighbor_id VARCHAR(255),
    snr         FLOAT,
    FOREIGN KEY (node_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (neighbor_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY idx_unique_node_neighbor (node_id, neighbor_id)
);

-- Node Configurations Table
CREATE TABLE IF NOT EXISTS node_configurations
(
    node_id                           VARCHAR(255) PRIMARY KEY,
    last_updated                      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Configuration (Telemetry) - INTERVAL ersetzt durch INT (Sekunden)
    environment_update_interval_sec   INT DEFAULT 0 NOT NULL,
    environment_update_last_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    device_update_interval_sec        INT DEFAULT 0 NOT NULL,
    device_update_last_timestamp      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    air_quality_update_interval_sec   INT DEFAULT 0 NOT NULL,
    air_quality_update_last_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    power_update_interval_sec         INT DEFAULT 0 NOT NULL,
    power_update_last_timestamp       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Configuration (Range Test)
    range_test_interval_sec           INT DEFAULT 0 NOT NULL,
    range_test_packets_total          INT DEFAULT 0,
    range_test_first_packet_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    range_test_last_packet_timestamp  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Configuration (PAX Counter)
    pax_counter_interval_sec          INT DEFAULT 0 NOT NULL,
    pax_counter_last_timestamp        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Configuration (Neighbor Info)
    neighbor_info_interval_sec        INT DEFAULT 0 NOT NULL,
    neighbor_info_last_timestamp      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Configuration (MQTT)
    mqtt_encryption_enabled           BOOLEAN DEFAULT FALSE,
    mqtt_json_enabled                 BOOLEAN DEFAULT FALSE,
    mqtt_json_message_timestamp       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    mqtt_configured_root_topic        TEXT,
    mqtt_info_last_timestamp          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Configuration (Map)
    map_broadcast_interval_sec        INT DEFAULT 0 NOT NULL,
    map_broadcast_last_timestamp      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (node_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Device Metrics (partitioniert für bessere Performance)
CREATE TABLE device_metrics
(
    time                TIMESTAMP NOT NULL,
    node_id             VARCHAR(255) NOT NULL,
    battery_level       FLOAT,
    voltage             FLOAT,
    channel_utilization FLOAT,
    air_util_tx         FLOAT,
    uptime_seconds      BIGINT,

    PRIMARY KEY (node_id, time),
    FOREIGN KEY (node_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_device_metrics_time ON device_metrics (time);

-- Environment Metrics
CREATE TABLE environment_metrics
(
    time                TIMESTAMP NOT NULL,
    node_id             VARCHAR(255) NOT NULL,
    temperature         FLOAT,
    relative_humidity   FLOAT,
    barometric_pressure FLOAT,
    gas_resistance      FLOAT,
    iaq                 FLOAT,
    distance            FLOAT,
    lux                 FLOAT,
    white_lux           FLOAT,
    ir_lux              FLOAT,
    uv_lux              FLOAT,
    wind_direction      FLOAT,
    wind_speed          FLOAT,
    weight              FLOAT,

    PRIMARY KEY (node_id, time),
    FOREIGN KEY (node_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_environment_metrics_time ON environment_metrics (time);

-- Air Quality Metrics
CREATE TABLE air_quality_metrics
(
    time                TIMESTAMP NOT NULL,
    node_id             VARCHAR(255) NOT NULL,
    pm10_standard       FLOAT,
    pm25_standard       FLOAT,
    pm100_standard      FLOAT,
    pm10_environmental  FLOAT,
    pm25_environmental  FLOAT,
    pm100_environmental FLOAT,
    particles_03um      FLOAT,
    particles_05um      FLOAT,
    particles_10um      FLOAT,
    particles_25um      FLOAT,
    particles_50um      FLOAT,
    particles_100um     FLOAT,

    PRIMARY KEY (node_id, time),
    FOREIGN KEY (node_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_air_quality_metrics_time ON air_quality_metrics (time);

-- Power Metrics
CREATE TABLE power_metrics
(
    time        TIMESTAMP NOT NULL,
    node_id     VARCHAR(255) NOT NULL,
    ch1_voltage FLOAT,
    ch1_current FLOAT,
    ch2_voltage FLOAT,
    ch2_current FLOAT,
    ch3_voltage FLOAT,
    ch3_current FLOAT,

    PRIMARY KEY (node_id, time),
    FOREIGN KEY (node_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_power_metrics_time ON power_metrics (time);

-- PAX Counter Metrics
CREATE TABLE pax_counter_metrics
(
    time          TIMESTAMP NOT NULL,
    node_id       VARCHAR(255) NOT NULL,
    wifi_stations BIGINT,
    ble_beacons   BIGINT,

    PRIMARY KEY (node_id, time),
    FOREIGN KEY (node_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_pax_counter_metrics_time ON pax_counter_metrics (time);

-- Mesh Packet Metrics
CREATE TABLE mesh_packet_metrics
(
    time               TIMESTAMP NOT NULL,
    source_id          VARCHAR(255) NOT NULL,
    destination_id     VARCHAR(255) NOT NULL,
    portnum            VARCHAR(255),
    packet_id          BIGINT,
    channel            INT,
    rx_time            BIGINT,
    rx_snr             FLOAT,
    rx_rssi            FLOAT,
    hop_limit          INT,
    hop_start          INT,
    want_ack           BOOLEAN,
    via_mqtt           BOOLEAN,
    message_size_bytes INT,

    INDEX idx_mesh_packet_metrics_source (source_id, time),
    INDEX idx_mesh_packet_metrics_dest (destination_id, time),
    INDEX idx_mesh_packet_metrics_time (time),

    FOREIGN KEY (source_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (destination_id) REFERENCES node_details (node_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Stored Procedure für Node Configuration Updates (ersetzt PostgreSQL Function)
DELIMITER $$
CREATE PROCEDURE update_node_configurations(IN p_node_id VARCHAR(255), IN p_time TIMESTAMP, IN p_table_name VARCHAR(50))
BEGIN
    -- Insert node_id into node_configurations if it doesn't exist
    INSERT IGNORE INTO node_configurations (node_id) VALUES (p_node_id);

    -- Update the last_updated timestamp
    UPDATE node_configurations
    SET last_updated = NOW()
    WHERE node_id = p_node_id;

    -- Update the specific metric timestamp based on the table
    CASE p_table_name
        WHEN 'device_metrics' THEN
            UPDATE node_configurations
            SET device_update_last_timestamp = p_time
            WHERE node_id = p_node_id;
        WHEN 'environment_metrics' THEN
            UPDATE node_configurations
            SET environment_update_last_timestamp = p_time
            WHERE node_id = p_node_id;
        WHEN 'air_quality_metrics' THEN
            UPDATE node_configurations
            SET air_quality_update_last_timestamp = p_time
            WHERE node_id = p_node_id;
        WHEN 'power_metrics' THEN
            UPDATE node_configurations
            SET power_update_last_timestamp = p_time
            WHERE node_id = p_node_id;
        WHEN 'pax_counter_metrics' THEN
            UPDATE node_configurations
            SET pax_counter_last_timestamp = p_time
            WHERE node_id = p_node_id;
    END CASE;
END$$
DELIMITER ;

-- Stored Procedure für Update Interval Berechnung
DELIMITER $$
CREATE PROCEDURE calculate_update_intervals()
BEGIN
    -- Update device_update_interval_sec
    UPDATE node_configurations nc
    SET device_update_interval_sec = COALESCE((
        SELECT CASE
            WHEN COUNT(time) > 1 THEN
                TIMESTAMPDIFF(SECOND, MIN(time), MAX(time)) / (COUNT(time) - 1)
            ELSE 0
        END
        FROM device_metrics
        WHERE node_id = nc.node_id
    ), 0);

    -- Update environment_update_interval_sec
    UPDATE node_configurations nc
    SET environment_update_interval_sec = COALESCE((
        SELECT CASE
            WHEN COUNT(time) > 1 THEN
                TIMESTAMPDIFF(SECOND, MIN(time), MAX(time)) / (COUNT(time) - 1)
            ELSE 0
        END
        FROM environment_metrics
        WHERE node_id = nc.node_id
    ), 0);

    -- Update air_quality_update_interval_sec
    UPDATE node_configurations nc
    SET air_quality_update_interval_sec = COALESCE((
        SELECT CASE
            WHEN COUNT(time) > 1 THEN
                TIMESTAMPDIFF(SECOND, MIN(time), MAX(time)) / (COUNT(time) - 1)
            ELSE 0
        END
        FROM air_quality_metrics
        WHERE node_id = nc.node_id
    ), 0);

    -- Update power_update_interval_sec
    UPDATE node_configurations nc
    SET power_update_interval_sec = COALESCE((
        SELECT CASE
            WHEN COUNT(time) > 1 THEN
                TIMESTAMPDIFF(SECOND, MIN(time), MAX(time)) / (COUNT(time) - 1)
            ELSE 0
        END
        FROM power_metrics
        WHERE node_id = nc.node_id
    ), 0);

    -- Update pax_counter_interval_sec
    UPDATE node_configurations nc
    SET pax_counter_interval_sec = COALESCE((
        SELECT CASE
            WHEN COUNT(time) > 1 THEN
                TIMESTAMPDIFF(SECOND, MIN(time), MAX(time)) / (COUNT(time) - 1)
            ELSE 0
        END
        FROM pax_counter_metrics
        WHERE node_id = nc.node_id
    ), 0);
END$$
DELIMITER ;

-- Triggers für automatische Node Configuration Updates
DELIMITER $$
CREATE TRIGGER trigger_device_metrics_insert
    AFTER INSERT ON device_metrics
    FOR EACH ROW
BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'device_metrics');
END$$

CREATE TRIGGER trigger_environment_metrics_insert
    AFTER INSERT ON environment_metrics
    FOR EACH ROW
BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'environment_metrics');
END$$

CREATE TRIGGER trigger_air_quality_metrics_insert
    AFTER INSERT ON air_quality_metrics
    FOR EACH ROW
BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'air_quality_metrics');
END$$

CREATE TRIGGER trigger_power_metrics_insert
    AFTER INSERT ON power_metrics
    FOR EACH ROW
BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'power_metrics');
END$$

CREATE TRIGGER trigger_pax_counter_metrics_insert
    AFTER INSERT ON pax_counter_metrics
    FOR EACH ROW
BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'pax_counter_metrics');
END$$
DELIMITER ;

-- Event Scheduler für Retention Policies (ersetzt TimescaleDB retention policies)
DELIMITER $$
CREATE EVENT IF NOT EXISTS cleanup_device_metrics
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM device_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE EVENT IF NOT EXISTS cleanup_environment_metrics
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM environment_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE EVENT IF NOT EXISTS cleanup_air_quality_metrics
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM air_quality_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE EVENT IF NOT EXISTS cleanup_power_metrics
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM power_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE EVENT IF NOT EXISTS cleanup_pax_counter_metrics
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM pax_counter_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE EVENT IF NOT EXISTS cleanup_mesh_packet_metrics
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM mesh_packet_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

-- Event für stündliche Update Interval Berechnung
CREATE EVENT IF NOT EXISTS calculate_intervals_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CALL calculate_update_intervals();
END$$
DELIMITER ;

-- View für Node Telemetry (ersetzt LATERAL JOINs)
CREATE OR REPLACE VIEW node_telemetry AS
SELECT d.node_id,
       d.short_name,
       d.long_name,
       d.hardware_model,
       d.role,
       dm.time as device_time,
       dm.battery_level,
       dm.voltage,
       dm.channel_utilization,
       dm.air_util_tx,
       dm.uptime_seconds,
       em.time as environment_time,
       em.temperature,
       em.relative_humidity,
       em.barometric_pressure,
       em.gas_resistance,
       em.iaq,
       em.distance,
       em.lux,
       em.white_lux,
       em.ir_lux,
       em.uv_lux,
       em.wind_direction,
       em.wind_speed,
       em.weight,
       aq.time as air_quality_time,
       aq.pm10_standard,
       aq.pm25_standard,
       aq.pm100_standard,
       aq.pm10_environmental,
       aq.pm25_environmental,
       aq.pm100_environmental,
       aq.particles_03um,
       aq.particles_05um,
       aq.particles_10um,
       aq.particles_25um,
       aq.particles_50um,
       aq.particles_100um,
       pm.time as power_time,
       pm.ch1_voltage,
       pm.ch1_current,
       pm.ch2_voltage,
       pm.ch2_current,
       pm.ch3_voltage,
       pm.ch3_current
FROM node_details d
         LEFT JOIN (
             SELECT dm1.*
             FROM device_metrics dm1
             INNER JOIN (
                 SELECT node_id, MAX(time) as max_time
                 FROM device_metrics
                 GROUP BY node_id
             ) dm2 ON dm1.node_id = dm2.node_id AND dm1.time = dm2.max_time
         ) dm ON d.node_id = dm.node_id
         LEFT JOIN (
             SELECT em1.*
             FROM environment_metrics em1
             INNER JOIN (
                 SELECT node_id, MAX(time) as max_time
                 FROM environment_metrics
                 GROUP BY node_id
             ) em2 ON em1.node_id = em2.node_id AND em1.time = em2.max_time
         ) em ON d.node_id = em.node_id
         LEFT JOIN (
             SELECT aq1.*
             FROM air_quality_metrics aq1
             INNER JOIN (
                 SELECT node_id, MAX(time) as max_time
                 FROM air_quality_metrics
                 GROUP BY node_id
             ) aq2 ON aq1.node_id = aq2.node_id AND aq1.time = aq2.max_time
         ) aq ON d.node_id = aq.node_id
         LEFT JOIN (
             SELECT pm1.*
             FROM power_metrics pm1
             INNER JOIN (
                 SELECT node_id, MAX(time) as max_time
                 FROM power_metrics
                 GROUP BY node_id
             ) pm2 ON pm1.node_id = pm2.node_id AND pm1.time = pm2.max_time
         ) pm ON d.node_id = pm.node_id;

-- Initialize node_configurations mit bestehenden node_ids
INSERT IGNORE INTO node_configurations (node_id)
SELECT node_id FROM node_details;

-- Initiale Update Interval Berechnung
CALL calculate_update_intervals();
