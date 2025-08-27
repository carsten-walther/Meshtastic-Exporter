# !/usr/bin/env python3
# -*- encoding: utf-8 -*-

from dataclasses import dataclass
from typing import Optional

@dataclass()
class NodeInfoUser:
    id: str
    longName: str
    shortName: str
    macaddr: Optional[str] = None
    hwModel: Optional[str] = None
    role: Optional[str] = None
    publicKey: Optional[str] = None
    isUnmessagable: Optional[bool] = None


@dataclass()
class NodeInfoPosition:
    latitudeI: Optional[int] = None
    longitudeI: Optional[int] = None
    altitude: Optional[int] = None
    time: Optional[int] = None
    locationSource: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


@dataclass()
class NodeInfoDeviceMetrics:
    batteryLevel: Optional[int] = None
    voltage: Optional[float] = None
    channelUtilization: Optional[float] = None
    airUtilTx: Optional[float] = None
    uptimeSeconds: Optional[int] = None


@dataclass
class NodeInfo:
    num: int
    user: NodeInfoUser
    position: NodeInfoPosition
    deviceMetrics: NodeInfoDeviceMetrics
    snr: Optional[float] = None
    lastHeard: Optional[int] = None
    hopsAway: Optional[int] = None