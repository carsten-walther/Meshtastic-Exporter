/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
SET NAMES utf8mb4;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE='NO_AUTO_VALUE_ON_ZERO', SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Tabellen-Dump air_quality_metrics
# ------------------------------------------------------------

DROP TABLE IF EXISTS `air_quality_metrics`;

CREATE TABLE `air_quality_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) NOT NULL,
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
  `particles_100um` float DEFAULT NULL,
  PRIMARY KEY (`node_id`,`time`),
  KEY `idx_air_quality_metrics_time` (`time`),
  CONSTRAINT `air_quality_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;


DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`root`@`%` */ /*!50003 TRIGGER `trigger_air_quality_metrics_insert` AFTER INSERT ON `air_quality_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'air_quality_metrics');
END */;;
DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;


# Tabellen-Dump device_metrics
# ------------------------------------------------------------

DROP TABLE IF EXISTS `device_metrics`;

CREATE TABLE `device_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) NOT NULL,
  `battery_level` float DEFAULT NULL,
  `voltage` float DEFAULT NULL,
  `channel_utilization` float DEFAULT NULL,
  `air_util_tx` float DEFAULT NULL,
  `uptime_seconds` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`node_id`,`time`),
  KEY `idx_device_metrics_time` (`time`),
  CONSTRAINT `device_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;


DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`root`@`%` */ /*!50003 TRIGGER `trigger_device_metrics_insert` AFTER INSERT ON `device_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'device_metrics');
END */;;
DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;


# Tabellen-Dump environment_metrics
# ------------------------------------------------------------

DROP TABLE IF EXISTS `environment_metrics`;

CREATE TABLE `environment_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) NOT NULL,
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
  `weight` float DEFAULT NULL,
  PRIMARY KEY (`node_id`,`time`),
  KEY `idx_environment_metrics_time` (`time`),
  CONSTRAINT `environment_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;


DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`root`@`%` */ /*!50003 TRIGGER `trigger_environment_metrics_insert` AFTER INSERT ON `environment_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'environment_metrics');
END */;;
DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;


# Tabellen-Dump mesh_packet_metrics
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mesh_packet_metrics`;

CREATE TABLE `mesh_packet_metrics` (
  `time` timestamp NOT NULL,
  `source_id` varchar(255) NOT NULL,
  `destination_id` varchar(255) NOT NULL,
  `portnum` varchar(255) DEFAULT NULL,
  `packet_id` bigint(20) DEFAULT NULL,
  `channel` int(11) DEFAULT NULL,
  `rx_time` int(11) DEFAULT NULL,
  `rx_snr` float DEFAULT NULL,
  `rx_rssi` float DEFAULT NULL,
  `hop_limit` int(11) DEFAULT NULL,
  `hop_start` int(11) DEFAULT NULL,
  `want_ack` tinyint(1) DEFAULT NULL,
  `via_mqtt` tinyint(1) DEFAULT NULL,
  `message_size_bytes` int(11) DEFAULT NULL,
  KEY `idx_mesh_packet_metrics_source` (`source_id`,`time`),
  KEY `idx_mesh_packet_metrics_dest` (`destination_id`,`time`),
  KEY `idx_mesh_packet_metrics_time` (`time`),
  CONSTRAINT `mesh_packet_metrics_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `mesh_packet_metrics_ibfk_2` FOREIGN KEY (`destination_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;



# Tabellen-Dump messages
# ------------------------------------------------------------

DROP TABLE IF EXISTS `messages`;

CREATE TABLE `messages` (
  `id` text NOT NULL,
  `received_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;



# Tabellen-Dump node_configurations
# ------------------------------------------------------------

DROP TABLE IF EXISTS `node_configurations`;

CREATE TABLE `node_configurations` (
  `node_id` varchar(255) NOT NULL,
  `last_updated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `environment_update_interval_sec` int(11) NOT NULL DEFAULT 0,
  `environment_update_last_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `device_update_interval_sec` int(11) NOT NULL DEFAULT 0,
  `device_update_last_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `air_quality_update_interval_sec` int(11) NOT NULL DEFAULT 0,
  `air_quality_update_last_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `power_update_interval_sec` int(11) NOT NULL DEFAULT 0,
  `power_update_last_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `range_test_interval_sec` int(11) NOT NULL DEFAULT 0,
  `range_test_packets_total` int(11) DEFAULT 0,
  `range_test_first_packet_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `range_test_last_packet_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `pax_counter_interval_sec` int(11) NOT NULL DEFAULT 0,
  `pax_counter_last_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `neighbor_info_interval_sec` int(11) NOT NULL DEFAULT 0,
  `neighbor_info_last_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `mqtt_encryption_enabled` tinyint(1) DEFAULT 0,
  `mqtt_json_enabled` tinyint(1) DEFAULT 0,
  `mqtt_json_message_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `mqtt_configured_root_topic` text DEFAULT NULL,
  `mqtt_info_last_timestamp` timestamp NULL DEFAULT current_timestamp(),
  `map_broadcast_interval_sec` int(11) NOT NULL DEFAULT 0,
  `map_broadcast_last_timestamp` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`node_id`),
  CONSTRAINT `node_configurations_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;



# Tabellen-Dump node_details
# ------------------------------------------------------------

DROP TABLE IF EXISTS `node_details`;

CREATE TABLE `node_details` (
  `node_id` varchar(255) NOT NULL,
  `short_name` varchar(255) DEFAULT NULL,
  `long_name` varchar(255) DEFAULT NULL,
  `hardware_model` varchar(255) DEFAULT NULL,
  `role` varchar(255) DEFAULT NULL,
  `mqtt_status` varchar(255) DEFAULT NULL,
  `longitude` float DEFAULT NULL,
  `latitude` float DEFAULT NULL,
  `altitude` int(11) DEFAULT NULL,
  `precision_bits` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`node_id`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;



# Tabellen-Dump node_neighbors
# ------------------------------------------------------------

DROP TABLE IF EXISTS `node_neighbors`;

CREATE TABLE `node_neighbors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `node_id` varchar(255) DEFAULT NULL,
  `neighbor_id` varchar(255) DEFAULT NULL,
  `snr` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_unique_node_neighbor` (`node_id`,`neighbor_id`),
  KEY `neighbor_id` (`neighbor_id`),
  CONSTRAINT `node_neighbors_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `node_neighbors_ibfk_2` FOREIGN KEY (`neighbor_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;





# Tabellen-Dump pax_counter_metrics
# ------------------------------------------------------------

DROP TABLE IF EXISTS `pax_counter_metrics`;

CREATE TABLE `pax_counter_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) NOT NULL,
  `wifi_stations` bigint(20) DEFAULT NULL,
  `ble_beacons` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`node_id`,`time`),
  KEY `idx_pax_counter_metrics_time` (`time`),
  CONSTRAINT `pax_counter_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;


DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`root`@`%` */ /*!50003 TRIGGER `trigger_pax_counter_metrics_insert` AFTER INSERT ON `pax_counter_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'pax_counter_metrics');
END */;;
DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;


# Tabellen-Dump power_metrics
# ------------------------------------------------------------

DROP TABLE IF EXISTS `power_metrics`;

CREATE TABLE `power_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) NOT NULL,
  `ch1_voltage` float DEFAULT NULL,
  `ch1_current` float DEFAULT NULL,
  `ch2_voltage` float DEFAULT NULL,
  `ch2_current` float DEFAULT NULL,
  `ch3_voltage` float DEFAULT NULL,
  `ch3_current` float DEFAULT NULL,
  PRIMARY KEY (`node_id`,`time`),
  KEY `idx_power_metrics_time` (`time`),
  CONSTRAINT `power_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;


DELIMITER ;;
/*!50003 SET SESSION SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;;
/*!50003 CREATE */ /*!50017 DEFINER=`root`@`%` */ /*!50003 TRIGGER `trigger_power_metrics_insert` AFTER INSERT ON `power_metrics` FOR EACH ROW BEGIN
    CALL update_node_configurations(NEW.node_id, NEW.time, 'power_metrics');
END */;;
DELIMITER ;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;


# Dump of view node_telemetry
# ------------------------------------------------------------

DROP TABLE IF EXISTS `node_telemetry`; DROP VIEW IF EXISTS `node_telemetry`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `node_telemetry`
AS SELECT
   `d`.`node_id` AS `node_id`,
   `d`.`short_name` AS `short_name`,
   `d`.`long_name` AS `long_name`,
   `d`.`hardware_model` AS `hardware_model`,
   `d`.`role` AS `role`,
   `dm`.`time` AS `device_time`,
   `dm`.`battery_level` AS `battery_level`,
   `dm`.`voltage` AS `voltage`,
   `dm`.`channel_utilization` AS `channel_utilization`,
   `dm`.`air_util_tx` AS `air_util_tx`,
   `dm`.`uptime_seconds` AS `uptime_seconds`,
   `em`.`time` AS `environment_time`,
   `em`.`temperature` AS `temperature`,
   `em`.`relative_humidity` AS `relative_humidity`,
   `em`.`barometric_pressure` AS `barometric_pressure`,
   `em`.`gas_resistance` AS `gas_resistance`,
   `em`.`iaq` AS `iaq`,
   `em`.`distance` AS `distance`,
   `em`.`lux` AS `lux`,
   `em`.`white_lux` AS `white_lux`,
   `em`.`ir_lux` AS `ir_lux`,
   `em`.`uv_lux` AS `uv_lux`,
   `em`.`wind_direction` AS `wind_direction`,
   `em`.`wind_speed` AS `wind_speed`,
   `em`.`weight` AS `weight`,
   `aq`.`time` AS `air_quality_time`,
   `aq`.`pm10_standard` AS `pm10_standard`,
   `aq`.`pm25_standard` AS `pm25_standard`,
   `aq`.`pm100_standard` AS `pm100_standard`,
   `aq`.`pm10_environmental` AS `pm10_environmental`,
   `aq`.`pm25_environmental` AS `pm25_environmental`,
   `aq`.`pm100_environmental` AS `pm100_environmental`,
   `aq`.`particles_03um` AS `particles_03um`,
   `aq`.`particles_05um` AS `particles_05um`,
   `aq`.`particles_10um` AS `particles_10um`,
   `aq`.`particles_25um` AS `particles_25um`,
   `aq`.`particles_50um` AS `particles_50um`,
   `aq`.`particles_100um` AS `particles_100um`,
   `pm`.`time` AS `power_time`,
   `pm`.`ch1_voltage` AS `ch1_voltage`,
   `pm`.`ch1_current` AS `ch1_current`,
   `pm`.`ch2_voltage` AS `ch2_voltage`,
   `pm`.`ch2_current` AS `ch2_current`,
   `pm`.`ch3_voltage` AS `ch3_voltage`,
   `pm`.`ch3_current` AS `ch3_current`
FROM ((((`node_details` `d` left join (select `dm1`.`time` AS `time`,`dm1`.`node_id` AS `node_id`,`dm1`.`battery_level` AS `battery_level`,`dm1`.`voltage` AS `voltage`,`dm1`.`channel_utilization` AS `channel_utilization`,`dm1`.`air_util_tx` AS `air_util_tx`,`dm1`.`uptime_seconds` AS `uptime_seconds` from (`device_metrics` `dm1` join (select `device_metrics`.`node_id` AS `node_id`,max(`device_metrics`.`time`) AS `max_time` from `device_metrics` group by `device_metrics`.`node_id`) `dm2` on(`dm1`.`node_id` = `dm2`.`node_id` and `dm1`.`time` = `dm2`.`max_time`))) `dm` on(`d`.`node_id` = `dm`.`node_id`)) left join (select `em1`.`time` AS `time`,`em1`.`node_id` AS `node_id`,`em1`.`temperature` AS `temperature`,`em1`.`relative_humidity` AS `relative_humidity`,`em1`.`barometric_pressure` AS `barometric_pressure`,`em1`.`gas_resistance` AS `gas_resistance`,`em1`.`iaq` AS `iaq`,`em1`.`distance` AS `distance`,`em1`.`lux` AS `lux`,`em1`.`white_lux` AS `white_lux`,`em1`.`ir_lux` AS `ir_lux`,`em1`.`uv_lux` AS `uv_lux`,`em1`.`wind_direction` AS `wind_direction`,`em1`.`wind_speed` AS `wind_speed`,`em1`.`weight` AS `weight` from (`environment_metrics` `em1` join (select `environment_metrics`.`node_id` AS `node_id`,max(`environment_metrics`.`time`) AS `max_time` from `environment_metrics` group by `environment_metrics`.`node_id`) `em2` on(`em1`.`node_id` = `em2`.`node_id` and `em1`.`time` = `em2`.`max_time`))) `em` on(`d`.`node_id` = `em`.`node_id`)) left join (select `aq1`.`time` AS `time`,`aq1`.`node_id` AS `node_id`,`aq1`.`pm10_standard` AS `pm10_standard`,`aq1`.`pm25_standard` AS `pm25_standard`,`aq1`.`pm100_standard` AS `pm100_standard`,`aq1`.`pm10_environmental` AS `pm10_environmental`,`aq1`.`pm25_environmental` AS `pm25_environmental`,`aq1`.`pm100_environmental` AS `pm100_environmental`,`aq1`.`particles_03um` AS `particles_03um`,`aq1`.`particles_05um` AS `particles_05um`,`aq1`.`particles_10um` AS `particles_10um`,`aq1`.`particles_25um` AS `particles_25um`,`aq1`.`particles_50um` AS `particles_50um`,`aq1`.`particles_100um` AS `particles_100um` from (`air_quality_metrics` `aq1` join (select `air_quality_metrics`.`node_id` AS `node_id`,max(`air_quality_metrics`.`time`) AS `max_time` from `air_quality_metrics` group by `air_quality_metrics`.`node_id`) `aq2` on(`aq1`.`node_id` = `aq2`.`node_id` and `aq1`.`time` = `aq2`.`max_time`))) `aq` on(`d`.`node_id` = `aq`.`node_id`)) left join (select `pm1`.`time` AS `time`,`pm1`.`node_id` AS `node_id`,`pm1`.`ch1_voltage` AS `ch1_voltage`,`pm1`.`ch1_current` AS `ch1_current`,`pm1`.`ch2_voltage` AS `ch2_voltage`,`pm1`.`ch2_current` AS `ch2_current`,`pm1`.`ch3_voltage` AS `ch3_voltage`,`pm1`.`ch3_current` AS `ch3_current` from (`power_metrics` `pm1` join (select `power_metrics`.`node_id` AS `node_id`,max(`power_metrics`.`time`) AS `max_time` from `power_metrics` group by `power_metrics`.`node_id`) `pm2` on(`pm1`.`node_id` = `pm2`.`node_id` and `pm1`.`time` = `pm2`.`max_time`))) `pm` on(`d`.`node_id` = `pm`.`node_id`));


--
-- Dumping routines (PROCEDURE) for database 'meshtastic'
--
DELIMITER ;;

# Dump of PROCEDURE calculate_update_intervals
# ------------------------------------------------------------

/*!50003 DROP PROCEDURE IF EXISTS `calculate_update_intervals` */;;
/*!50003 SET SESSION SQL_MODE="NO_AUTO_VALUE_ON_ZERO"*/;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `calculate_update_intervals`()
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
END */;;

/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;;
# Dump of PROCEDURE expire_old_messages
# ------------------------------------------------------------

/*!50003 DROP PROCEDURE IF EXISTS `expire_old_messages` */;;
/*!50003 SET SESSION SQL_MODE="NO_AUTO_VALUE_ON_ZERO"*/;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `expire_old_messages`()
BEGIN
    IF @trigger_flag IS NULL THEN
    SET @trigger_flag = 1;
    DELETE FROM messages WHERE received_at < DATE_SUB(NOW(), INTERVAL 1 MINUTE);
    END IF;
END */;;

/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;;
# Dump of PROCEDURE update_node_configurations
# ------------------------------------------------------------

/*!50003 DROP PROCEDURE IF EXISTS `update_node_configurations` */;;
/*!50003 SET SESSION SQL_MODE="NO_AUTO_VALUE_ON_ZERO"*/;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `update_node_configurations`(IN `p_node_id` VARCHAR(255), IN `p_time` TIMESTAMP, IN `p_table_name` VARCHAR(50))
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
END */;;

/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE */;;
DELIMITER ;

/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
