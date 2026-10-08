from pydantic import BaseModel
from typing import List

class Point(BaseModel):
    x: float
    y: float

class ZoneConfig(BaseModel):
    name: str
    polygon: List[Point]
    type: str = "safe"

class MonitorUpdate(BaseModel):
    battery_level: int
    is_charging: bool
    # Which camera phone this battery report belongs to (multi-camera setups).
    monitor_id: str | None = None

class SoundEvent(BaseModel):
    # Loudness in dBFS as measured on the monitor; kept for the event details.
    level: float = 0.0

class PetProfile(BaseModel):
    name: str
    type: str
    profile_pic: str | None = None

class LoginRequest(BaseModel):
    secret: str
    scope: str = "full"

class MedicalDataSync(BaseModel):
    medications: list[dict]
    vaccines: list[dict]