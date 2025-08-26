-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: mysql:3306
-- Erstellungszeit: 25. Aug 2025 um 13:56
-- Server-Version: 9.4.0
-- PHP-Version: 8.2.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Datenbank: `meshtastic`
--
CREATE DATABASE IF NOT EXISTS `meshtastic` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `meshtastic`;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `device_metrics`
--

CREATE TABLE `device_metrics` (
  `time` timestamp NOT NULL,
  `node_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `battery_level` float DEFAULT NULL,
  `voltage` float DEFAULT NULL,
  `channel_utilization` float DEFAULT NULL,
  `air_util_tx` float DEFAULT NULL,
  `uptime_seconds` bigint DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `messages`
--

CREATE TABLE `messages` (
  `id` int NOT NULL,
  `received_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Trigger `messages`
--
DELIMITER $$
CREATE TRIGGER `trigger_expire_old_messages` AFTER INSERT ON `messages` FOR EACH ROW BEGIN
    DELETE FROM messages WHERE received_at < NOW() - INTERVAL 1 MINUTE;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `node_configurations`
--

CREATE TABLE `node_configurations` (
  `node_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `last_updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `environment_update_interval` int NOT NULL DEFAULT '0',
  `environment_update_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `device_update_interval` int NOT NULL DEFAULT '0',
  `device_update_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `air_quality_update_interval` int NOT NULL DEFAULT '0',
  `air_quality_update_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `power_update_interval` int NOT NULL DEFAULT '0',
  `power_update_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `range_test_interval` int NOT NULL DEFAULT '0',
  `range_test_packets_total` int DEFAULT '0',
  `range_test_first_packet_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `range_test_last_packet_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `pax_counter_interval` int NOT NULL DEFAULT '0',
  `pax_counter_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `neighbor_info_interval` int NOT NULL DEFAULT '0',
  `neighbor_info_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `map_broadcast_interval` int NOT NULL DEFAULT '0',
  `map_broadcast_last_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `node_details`
--

CREATE TABLE `node_details` (
  `node_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `short_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `long_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `hardware_model` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `role` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `mqtt_status` varchar(255) COLLATE utf8mb4_general_ci DEFAULT 'none',
  `longitude` int DEFAULT NULL,
  `latitude` int DEFAULT NULL,
  `altitude` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `node_neighbors`
--

CREATE TABLE `node_neighbors` (
  `id` int NOT NULL,
  `node_id` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `neighbor_id` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `snr` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `device_metrics`
--
ALTER TABLE `device_metrics`
  ADD KEY `node_id` (`node_id`);

--
-- Indizes für die Tabelle `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`);

--
-- Indizes für die Tabelle `node_configurations`
--
ALTER TABLE `node_configurations`
  ADD PRIMARY KEY (`node_id`),
  ADD UNIQUE KEY `node_id` (`node_id`);

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
  ADD UNIQUE KEY `node_id` (`node_id`,`neighbor_id`),
  ADD UNIQUE KEY `idx_unique_node_neighbor` (`node_id`,`neighbor_id`),
  ADD KEY `neighbor_id` (`neighbor_id`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `node_neighbors`
--
ALTER TABLE `node_neighbors`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `device_metrics`
--
ALTER TABLE `device_metrics`
  ADD CONSTRAINT `device_metrics_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`);

--
-- Constraints der Tabelle `node_neighbors`
--
ALTER TABLE `node_neighbors`
  ADD CONSTRAINT `node_neighbors_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `node_details` (`node_id`),
  ADD CONSTRAINT `node_neighbors_ibfk_2` FOREIGN KEY (`neighbor_id`) REFERENCES `node_details` (`node_id`);
COMMIT;
