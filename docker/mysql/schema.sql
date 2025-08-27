-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: mysql:3306
-- Erstellungszeit: 26. Aug 2025 um 17:46
-- Server-Version: 9.4.0
-- PHP-Version: 8.2.29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Datenbank: `meshtastic`
--
CREATE DATABASE IF NOT EXISTS `meshtastic` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `meshtastic`;

DELIMITER $$
--
-- Prozeduren
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `calculate_update_intervals` ()   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `expire_old_messages` ()   BEGIN
    IF @trigger_flag IS NULL THEN
    SET @trigger_flag = 1;
    DELETE FROM messages WHERE received_at < DATE_SUB(NOW(), INTERVAL 1 MINUTE);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_node_configurations` (IN `p_node_id` VARCHAR(255), IN `p_time` TIMESTAMP, IN `p_table_name` VARCHAR(50))   BEGIN
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

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `air_quality_metrics`
--

CREATE TABLE `air_quality_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `pm10_standard` float DEFAULT NULL,
  `pm25_standard` float DEFAULT NULL,
  `pm100_standard` float DEFAULT NULL,
  `pm10_environmental` float DEFAULT NULL,
  `pm25_environmental` float DEFAULT NULL,
  `pm100_environmental` float DEFAULT NULL,
  `particles_03um` float DEFAULT NULL,
  `particles_05um` float DEFAULT NULL,
  `particles_10um` float DEFAULT NULL,
  `particles_25um` float DEFAULT NULL,
  `particles_50um` float DEFAULT NULL,
  `particles_100um` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Trigger `air_quality_metrics`
--
DELIMITER $$
CREATE TRIGGER `trigger_air_quality_metrics_insert` AFTER INSERT ON `air_quality_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'air_quality_metrics');
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `device_metrics`
--

CREATE TABLE `device_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `battery_level` float DEFAULT NULL,
  `voltage` float DEFAULT NULL,
  `channel_utilization` float DEFAULT NULL,
  `air_util_tx` float DEFAULT NULL,
  `uptime_seconds` bigint DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Trigger `device_metrics`
--
DELIMITER $$
CREATE TRIGGER `trigger_device_metrics_insert` AFTER INSERT ON `device_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'device_metrics');
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `environment_metrics`
--

CREATE TABLE `environment_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `temperature` float DEFAULT NULL,
  `relative_humidity` float DEFAULT NULL,
  `barometric_pressure` float DEFAULT NULL,
  `gas_resistance` float DEFAULT NULL,
  `iaq` float DEFAULT NULL,
  `distance` float DEFAULT NULL,
  `lux` float DEFAULT NULL,
  `white_lux` float DEFAULT NULL,
  `ir_lux` float DEFAULT NULL,
  `uv_lux` float DEFAULT NULL,
  `wind_direction` float DEFAULT NULL,
  `wind_speed` float DEFAULT NULL,
  `weight` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Trigger `environment_metrics`
--
DELIMITER $$
CREATE TRIGGER `trigger_environment_metrics_insert` AFTER INSERT ON `environment_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'environment_metrics');
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `mesh_packet_metrics`
--

CREATE TABLE `mesh_packet_metrics` (
  `time` timestamp NOT NULL,
  `source_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `destination_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `portnum` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `packet_id` bigint DEFAULT NULL,
  `channel` int DEFAULT NULL,
  `rx_time` int DEFAULT NULL,
  `rx_snr` float DEFAULT NULL,
  `rx_rssi` float DEFAULT NULL,
  `hop_limit` int DEFAULT NULL,
  `hop_start` int DEFAULT NULL,
  `want_ack` tinyint(1) DEFAULT NULL,
  `via_mqtt` tinyint(1) DEFAULT NULL,
  `message_size_bytes` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `messages`
--

CREATE TABLE `messages` (
  `id` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `received_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Trigger `messages`
--
DELIMITER $$
CREATE TRIGGER `trigger_expire_old_messages` AFTER INSERT ON `messages` FOR EACH ROW BEGIN
    CALL expire_old_messages();
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `node_configurations`
--

CREATE TABLE `node_configurations` (
  `node_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `last_updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `environment_update_interval_sec` int NOT NULL DEFAULT '0',
  `environment_update_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `device_update_interval_sec` int NOT NULL DEFAULT '0',
  `device_update_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `air_quality_update_interval_sec` int NOT NULL DEFAULT '0',
  `air_quality_update_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `power_update_interval_sec` int NOT NULL DEFAULT '0',
  `power_update_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `range_test_interval_sec` int NOT NULL DEFAULT '0',
  `range_test_packets_total` int DEFAULT '0',
  `range_test_first_packet_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `range_test_last_packet_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `pax_counter_interval_sec` int NOT NULL DEFAULT '0',
  `pax_counter_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `neighbor_info_interval_sec` int NOT NULL DEFAULT '0',
  `neighbor_info_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `mqtt_encryption_enabled` tinyint(1) DEFAULT '0',
  `mqtt_json_enabled` tinyint(1) DEFAULT '0',
  `mqtt_json_message_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `mqtt_configured_root_topic` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `mqtt_info_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `map_broadcast_interval_sec` int NOT NULL DEFAULT '0',
  `map_broadcast_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `node_details`
--

CREATE TABLE `node_details` (
  `node_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `short_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `long_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `hardware_model` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `role` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `mqtt_status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'none',
  `longitude` int DEFAULT NULL,
  `latitude` int DEFAULT NULL,
  `altitude` int DEFAULT NULL,
  `precision_bits` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `node_neighbors`
--

CREATE TABLE `node_neighbors` (
  `id` int NOT NULL,
  `node_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `neighbor_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `snr` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stellvertreter-Struktur des Views `node_telemetry`
-- (Siehe unten für die tatsächliche Ansicht)
--
CREATE TABLE `node_telemetry` (
`air_quality_time` timestamp
,`air_util_tx` float
,`barometric_pressure` float
,`battery_level` float
,`ch1_current` float
,`ch1_voltage` float
,`ch2_current` float
,`ch2_voltage` float
,`ch3_current` float
,`ch3_voltage` float
,`channel_utilization` float
,`device_time` timestamp
,`distance` float
,`environment_time` timestamp
,`gas_resistance` float
,`hardware_model` varchar(255)
,`iaq` float
,`ir_lux` float
,`long_name` varchar(255)
,`lux` float
,`node_id` varchar(255)
,`particles_03um` float
,`particles_05um` float
,`particles_100um` float
,`particles_10um` float
,`particles_25um` float
,`particles_50um` float
,`pm100_environmental` float
,`pm100_standard` float
,`pm10_environmental` float
,`pm10_standard` float
,`pm25_environmental` float
,`pm25_standard` float
,`power_time` timestamp
,`relative_humidity` float
,`role` varchar(255)
,`short_name` varchar(255)
,`temperature` float
,`uptime_seconds` bigint
,`uv_lux` float
,`voltage` float
,`weight` float
,`white_lux` float
,`wind_direction` float
,`wind_speed` float
);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `pax_counter_metrics`
--

CREATE TABLE `pax_counter_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `wifi_stations` bigint DEFAULT NULL,
  `ble_beacons` bigint DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Trigger `pax_counter_metrics`
--
DELIMITER $$
CREATE TRIGGER `trigger_pax_counter_metrics_insert` AFTER INSERT ON `pax_counter_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'pax_counter_metrics');
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `power_metrics`
--

CREATE TABLE `power_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `ch1_voltage` float DEFAULT NULL,
  `ch1_current` float DEFAULT NULL,
  `ch2_voltage` float DEFAULT NULL,
  `ch2_current` float DEFAULT NULL,
  `ch3_voltage` float DEFAULT NULL,
  `ch3_current` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Trigger `power_metrics`
--
DELIMITER $$
CREATE TRIGGER `trigger_power_metrics_insert` AFTER INSERT ON `power_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'power_metrics');
END
$$
DELIMITER ;

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `air_quality_metrics`
--
ALTER TABLE `air_quality_metrics`
  ADD PRIMARY KEY (`node_id`,`time`),
  ADD KEY `idx_air_quality_metrics_time` (`time`);

--
-- Indizes für die Tabelle `device_metrics`
--
ALTER TABLE `device_metrics`
  ADD PRIMARY KEY (`node_id`,`time`),
  ADD KEY `idx_device_metrics_time` (`time`);

--
-- Indizes für die Tabelle `environment_metrics`
--
ALTER TABLE `environment_metrics`
  ADD PRIMARY KEY (`node_id`,`time`),
  ADD KEY `idx_environment_metrics_time` (`time`);

--
-- Indizes für die Tabelle `mesh_packet_metrics`
--
ALTER TABLE `mesh_packet_metrics`
  ADD KEY `idx_mesh_packet_metrics_source` (`source_id`,`time`),
  ADD KEY `idx_mesh_packet_metrics_dest` (`destination_id`,`time`),
  ADD KEY `idx_mesh_packet_metrics_time` (`time`);

--
-- Indizes für die Tabelle `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`(255));

--
-- Indizes für die Tabelle `node_configurations`
--
ALTER TABLE `node_configurations`
  ADD PRIMARY KEY (`node_id`);

--
-- Indizes für die Tabelle `node_details`
--
ALTER TABLE `node_details`
  ADD PRIMARY KEY (`node_id`);

--
-- Indizes für die Tabelle `node_neighbors`
--
ALTER TABLE `node_neighbors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_unique_node_neighbor` (`node_id`,`neighbor_id`),
  ADD KEY `neighbor_id` (`neighbor_id`);

--
-- Indizes für die Tabelle `pax_counter_metrics`
--
ALTER TABLE `pax_counter_metrics`
  ADD PRIMARY KEY (`node_id`,`time`),
  ADD KEY `idx_pax_counter_metrics_time` (`time`);

--
-- Indizes für die Tabelle `power_metrics`
--
ALTER TABLE `power_metrics`
  ADD PRIMARY KEY (`node_id`,`time`),
  ADD KEY `idx_power_metrics_time` (`time`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `node_neighbors`
--
ALTER TABLE `node_neighbors`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------

--
-- Struktur des Views `node_telemetry`
--
DROP TABLE IF EXISTS `node_telemetry`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `node_telemetry`  AS SELECT `d`.`node_id` AS `node_id`, `d`.`short_name` AS `short_name`, `d`.`long_name` AS `long_name`, `d`.`hardware_model` AS `hardware_model`, `d`.`role` AS `role`, `dm`.`time` AS `device_time`, `dm`.`battery_level` AS `battery_level`, `dm`.`voltage` AS `voltage`, `dm`.`channel_utilization` AS `channel_utilization`, `dm`.`air_util_tx` AS `air_util_tx`, `dm`.`uptime_seconds` AS `uptime_seconds`, `em`.`time` AS `environment_time`, `em`.`temperature` AS `temperature`, `em`.`relative_humidity` AS `relative_humidity`, `em`.`barometric_pressure` AS `barometric_pressure`, `em`.`gas_resistance` AS `gas_resistance`, `em`.`iaq` AS `iaq`, `em`.`distance` AS `distance`, `em`.`lux` AS `lux`, `em`.`white_lux` AS `white_lux`, `em`.`ir_lux` AS `ir_lux`, `em`.`uv_lux` AS `uv_lux`, `em`.`wind_direction` AS `wind_direction`, `em`.`wind_speed` AS `wind_speed`, `em`.`weight` AS `weight`, `aq`.`time` AS `air_quality_time`, `aq`.`pm10_standard` AS `pm10_standard`, `aq`.`pm25_standard` AS `pm25_standard`, `aq`.`pm100_standard` AS `pm100_standard`, `aq`.`pm10_environmental` AS `pm10_environmental`, `aq`.`pm25_environmental` AS `pm25_environmental`, `aq`.`pm100_environmental` AS `pm100_environmental`, `aq`.`particles_03um` AS `particles_03um`, `aq`.`particles_05um` AS `particles_05um`, `aq`.`particles_10um` AS `particles_10um`, `aq`.`particles_25um` AS `particles_25um`, `aq`.`particles_50um` AS `particles_50um`, `aq`.`particles_100um` AS `particles_100um`, `pm`.`time` AS `power_time`, `pm`.`ch1_voltage` AS `ch1_voltage`, `pm`.`ch1_current` AS `ch1_current`, `pm`.`ch2_voltage` AS `ch2_voltage`, `pm`.`ch2_current` AS `ch2_current`, `pm`.`ch3_voltage` AS `ch3_voltage`, `pm`.`ch3_current` AS `ch3_current` FROM ((((`node_details` `d` left join (select `dm1`.`time` AS `time`,`dm1`.`node_id` AS `node_id`,`dm1`.`battery_level` AS `battery_level`,`dm1`.`voltage` AS `voltage`,`dm1`.`channel_utilization` AS `channel_utilization`,`dm1`.`air_util_tx` AS `air_util_tx`,`dm1`.`uptime_seconds` AS `uptime_seconds` from (`device_metrics` `dm1` join (select `device_metrics`.`node_id` AS `node_id`,max(`device_metrics`.`time`) AS `max_time` from `device_metrics` group by `device_metrics`.`node_id`) `dm2` on(((`dm1`.`node_id` = `dm2`.`node_id`) and (`dm1`.`time` = `dm2`.`max_time`))))) `dm` on((`d`.`node_id` = `dm`.`node_id`))) left join (select `em1`.`time` AS `time`,`em1`.`node_id` AS `node_id`,`em1`.`temperature` AS `temperature`,`em1`.`relative_humidity` AS `relative_humidity`,`em1`.`barometric_pressure` AS `barometric_pressure`,`em1`.`gas_resistance` AS `gas_resistance`,`em1`.`iaq` AS `iaq`,`em1`.`distance` AS `distance`,`em1`.`lux` AS `lux`,`em1`.`white_lux` AS `white_lux`,`em1`.`ir_lux` AS `ir_lux`,`em1`.`uv_lux` AS `uv_lux`,`em1`.`wind_direction` AS `wind_direction`,`em1`.`wind_speed` AS `wind_speed`,`em1`.`weight` AS `weight` from (`environment_metrics` `em1` join (select `environment_metrics`.`node_id` AS `node_id`,max(`environment_metrics`.`time`) AS `max_time` from `environment_metrics` group by `environment_metrics`.`node_id`) `em2` on(((`em1`.`node_id` = `em2`.`node_id`) and (`em1`.`time` = `em2`.`max_time`))))) `em` on((`d`.`node_id` = `em`.`node_id`))) left join (select `aq1`.`time` AS `time`,`aq1`.`node_id` AS `node_id`,`aq1`.`pm10_standard` AS `pm10_standard`,`aq1`.`pm25_standard` AS `pm25_standard`,`aq1`.`pm100_standard` AS `pm100_standard`,`aq1`.`pm10_environmental` AS `pm10_environmental`,`aq1`.`pm25_environmental` AS `pm25_environmental`,`aq1`.`pm100_environmental` AS `pm100_environmental`,`aq1`.`particles_03um` AS `particles_03um`,`aq1`.`particles_05um` AS `particles_05um`,`aq1`.`particles_10um` AS `particles_10um`,`aq1`.`particles_25um` AS `particles_25um`,`aq1`.`particles_50um` AS `particles_50um`,`aq1`.`particles_100um` AS `particles_100um` from (`air_quality_metrics` `aq1` join (select `air_quality_metrics`.`node_id` AS `node_id`,max(`air_quality_metrics`.`time`) AS `max_time` from `air_quality_metrics` group by `air_quality_metrics`.`node_id`) `aq2` on(((`aq1`.`node_id` = `aq2`.`node_id`) and (`aq1`.`time` = `aq2`.`max_time`))))) `aq` on((`d`.`node_id` = `aq`.`node_id`))) left join (select `pm1`.`time` AS `time`,`pm1`.`node_id` AS `node_id`,`pm1`.`ch1_voltage` AS `ch1_voltage`,`pm1`.`ch1_current` AS `ch1_current`,`pm1`.`ch2_voltage` AS `ch2_voltage`,`pm1`.`ch2_current` AS `ch2_current`,`pm1`.`ch3_voltage` AS `ch3_voltage`,`pm1`.`ch3_current` AS `ch3_current` from (`power_metrics` `pm1` join (select `power_metrics`.`node_id` AS `node_id`,max(`power_metrics`.`time`) AS `max_time` from `power_metrics` group by `power_metrics`.`node_id`) `pm2` on(((`pm1`.`node_id` = `pm2`.`node_id`) and (`pm1`.`time` = `pm2`.`max_time`))))) `pm` on((`d`.`node_id` = `pm`.`node_id`))) ;

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `air_quality_metrics`
--
ALTER TABLE `air_quality_metrics`
  ADD CONSTRAINT `air_quality_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `device_metrics`
--
ALTER TABLE `device_metrics`
  ADD CONSTRAINT `device_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `environment_metrics`
--
ALTER TABLE `environment_metrics`
  ADD CONSTRAINT `environment_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `mesh_packet_metrics`
--
ALTER TABLE `mesh_packet_metrics`
  ADD CONSTRAINT `mesh_packet_metrics_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `mesh_packet_metrics_ibfk_2` FOREIGN KEY (`destination_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `node_configurations`
--
ALTER TABLE `node_configurations`
  ADD CONSTRAINT `node_configurations_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `node_neighbors`
--
ALTER TABLE `node_neighbors`
  ADD CONSTRAINT `node_neighbors_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `node_neighbors_ibfk_2` FOREIGN KEY (`neighbor_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `pax_counter_metrics`
--
ALTER TABLE `pax_counter_metrics`
  ADD CONSTRAINT `pax_counter_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints der Tabelle `power_metrics`
--
ALTER TABLE `power_metrics`
  ADD CONSTRAINT `power_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE;

DELIMITER $$
--
-- Ereignisse
--
CREATE DEFINER=`root`@`localhost` EVENT `cleanup_device_metrics` ON SCHEDULE EVERY 1 DAY STARTS '2025-08-26 17:43:47' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DELETE FROM device_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE DEFINER=`root`@`localhost` EVENT `cleanup_environment_metrics` ON SCHEDULE EVERY 1 DAY STARTS '2025-08-26 17:43:47' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DELETE FROM environment_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE DEFINER=`root`@`localhost` EVENT `cleanup_air_quality_metrics` ON SCHEDULE EVERY 1 DAY STARTS '2025-08-26 17:43:47' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DELETE FROM air_quality_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE DEFINER=`root`@`localhost` EVENT `cleanup_power_metrics` ON SCHEDULE EVERY 1 DAY STARTS '2025-08-26 17:43:47' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DELETE FROM power_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE DEFINER=`root`@`localhost` EVENT `cleanup_pax_counter_metrics` ON SCHEDULE EVERY 1 DAY STARTS '2025-08-26 17:43:47' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DELETE FROM pax_counter_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE DEFINER=`root`@`localhost` EVENT `cleanup_mesh_packet_metrics` ON SCHEDULE EVERY 1 DAY STARTS '2025-08-26 17:43:47' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DELETE FROM mesh_packet_metrics WHERE time < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE DEFINER=`root`@`localhost` EVENT `calculate_intervals_hourly` ON SCHEDULE EVERY 1 HOUR STARTS '2025-08-26 17:43:47' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    CALL calculate_update_intervals();
END$$

DELIMITER ;
COMMIT;


-- LÖSUNG 1: Event Scheduler verwenden (Empfohlen)
-- Entfernen Sie den Trigger und verwenden Sie stattdessen ein Event

-- Trigger löschen
DROP TRIGGER IF EXISTS trigger_expire_old_messages;

-- Event erstellen, das jede Minute alte Nachrichten löscht
DELIMITER $$
CREATE EVENT IF NOT EXISTS cleanup_old_messages
ON SCHEDULE EVERY 1 MINUTE
ON COMPLETION PRESERVE
ENABLE
DO BEGIN
    DELETE FROM messages WHERE received_at < DATE_SUB(NOW(), INTERVAL 1 MINUTE);
END$$
DELIMITER ;

-- Event Scheduler aktivieren (falls nicht bereits aktiv)
SET GLOBAL event_scheduler = ON;