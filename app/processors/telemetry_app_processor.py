#!/usr/bin/env python3
# -*- encoding: utf-8 -*-

import logging

from meshtastic.protobuf.portnums_pb2 import PortNum
from meshtastic.protobuf.telemetry_pb2 import Telemetry, DeviceMetrics, EnvironmentMetrics, AirQualityMetrics, \
    PowerMetrics

from app.client.client_details import ClientDetails
from app.processors.processor import Processor
from app.processors.processor_registry import ProcessorRegistry


@ProcessorRegistry.register_processor(PortNum.TELEMETRY_APP)
class TelemetryAppProcessor(Processor):
    def process(self, payload: bytes, client_details: ClientDetails):
        logging.debug("Received TELEMETRY_APP packet")
        telemetry = Telemetry()
        try:
            telemetry.ParseFromString(payload)
        except Exception as e:
            logging.error(f"Failed to parse TELEMETRY_APP packet: {e}")
            return

        if telemetry.HasField('device_metrics'):
            # Node configuration update is now handled by the database timestamps
            device_metrics: DeviceMetrics = telemetry.device_metrics

            # Store device metrics in TimescaleDB
            self.db_handler.store_device_metrics(client_details.node_id, {
                'battery_level': getattr(device_metrics, 'battery_level', 0),
                'voltage': getattr(device_metrics, 'voltage', 0),
                'channel_utilization': getattr(device_metrics, 'channel_utilization', 0),
                'air_util_tx': getattr(device_metrics, 'air_util_tx', 0),
                'uptime_seconds': getattr(device_metrics, 'uptime_seconds', 0)
            })

        if telemetry.HasField('environment_metrics'):
            # Node configuration update is now handled by the database timestamps
            environment_metrics: EnvironmentMetrics = telemetry.environment_metrics

            # Store environment metrics in TimescaleDB
            self.db_handler.store_environment_metrics(client_details.node_id, {
                'temperature': getattr(environment_metrics, 'temperature', 0),
                'relative_humidity': getattr(environment_metrics, 'relative_humidity', 0),
                'barometric_pressure': getattr(environment_metrics, 'barometric_pressure', 0),
                'gas_resistance': getattr(environment_metrics, 'gas_resistance', 0),
                'iaq': getattr(environment_metrics, 'iaq', 0),
                'distance': getattr(environment_metrics, 'distance', 0),
                'lux': getattr(environment_metrics, 'lux', 0),
                'white_lux': getattr(environment_metrics, 'white_lux', 0),
                'ir_lux': getattr(environment_metrics, 'ir_lux', 0),
                'uv_lux': getattr(environment_metrics, 'uv_lux', 0),
                'wind_direction': getattr(environment_metrics, 'wind_direction', 0),
                'wind_speed': getattr(environment_metrics, 'wind_speed', 0),
                'weight': getattr(environment_metrics, 'weight', 0)
            })

        if telemetry.HasField('air_quality_metrics'):
            # Node configuration update is now handled by the database timestamps
            air_quality_metrics: AirQualityMetrics = telemetry.air_quality_metrics

            # Store air quality metrics in TimescaleDB
            self.db_handler.store_air_quality_metrics(client_details.node_id, {
                'pm10_standard': getattr(air_quality_metrics, 'pm10_standard', 0),
                'pm25_standard': getattr(air_quality_metrics, 'pm25_standard', 0),
                'pm100_standard': getattr(air_quality_metrics, 'pm100_standard', 0),
                'pm10_environmental': getattr(air_quality_metrics, 'pm10_environmental', 0),
                'pm25_environmental': getattr(air_quality_metrics, 'pm25_environmental', 0),
                'pm100_environmental': getattr(air_quality_metrics, 'pm100_environmental', 0),
                'particles_03um': getattr(air_quality_metrics, 'particles_03um', 0),
                'particles_05um': getattr(air_quality_metrics, 'particles_05um', 0),
                'particles_10um': getattr(air_quality_metrics, 'particles_10um', 0),
                'particles_25um': getattr(air_quality_metrics, 'particles_25um', 0),
                'particles_50um': getattr(air_quality_metrics, 'particles_50um', 0),
                'particles_100um': getattr(air_quality_metrics, 'particles_100um', 0)
            })

        if telemetry.HasField('power_metrics'):
            # Node configuration update is now handled by the database timestamps
            power_metrics: PowerMetrics = telemetry.power_metrics

            # Store power metrics in TimescaleDB
            self.db_handler.store_power_metrics(client_details.node_id, {
                'ch1_voltage': getattr(power_metrics, 'ch1_voltage', 0),
                'ch1_current': getattr(power_metrics, 'ch1_current', 0),
                'ch2_voltage': getattr(power_metrics, 'ch2_voltage', 0),
                'ch2_current': getattr(power_metrics, 'ch2_current', 0),
                'ch3_voltage': getattr(power_metrics, 'ch3_voltage', 0),
                'ch3_current': getattr(power_metrics, 'ch3_current', 0)
            })
