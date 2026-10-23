from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, StringConstraints

Text32 = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=32)
]


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class RegisterRequest(StrictModel):
    platform: Literal["android", "ios"]
    appVersion: Text32


class TokenRequest(StrictModel):
    deviceId: UUID
    deviceSecret: Annotated[str, StringConstraints(min_length=1, max_length=256)]


class RegisterResponse(StrictModel):
    deviceId: UUID
    deviceSecret: str


class TokenResponse(StrictModel):
    accessToken: str
    tokenType: str = "Bearer"
    expiresIn: int
