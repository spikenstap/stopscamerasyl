from typing import Annotated, Any, Literal
from uuid import UUID

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StringConstraints,
    field_validator,
    model_validator,
)

from app.services.prompts import SCHEMA

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


class PhoneRequest(StrictModel):
    phoneNumber: Annotated[str, StringConstraints(min_length=1, max_length=64)]


class PhoneReportRequest(PhoneRequest):
    category: Literal["advertising", "suspectedFraud", "harassment", "other"]


class ReputationResponse(StrictModel):
    status: Literal["unknown", "clear", "flagged"]
    confidence: float
    confirmed: bool
    source: str
    reason: str
    expiresAt: int


class AcceptedResponse(StrictModel):
    accepted: bool


class AnalyzeRequest(StrictModel):
    type: Literal["text", "url", "qr", "phone"]
    content: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]
    language: Literal["ru", "kk"]
    localSignals: dict[str, Any] = Field(default_factory=dict)


class AnalysisResult(StrictModel):
    riskScore: int = Field(strict=True, ge=0, le=100)
    confidence: float = Field(strict=True, ge=0, le=1, allow_inf_nan=False)
    riskLevel: Any = None
    isScam: bool = Field(strict=True)
    category: str
    summary: str
    reasons: list[str] = Field(max_length=20)
    recommendations: list[str] = Field(min_length=1, max_length=20)

    @field_validator("summary", "category", mode="before")
    @classmethod
    def validate_text(cls, value, info):
        if not isinstance(value, str) or not value.strip() or len(value) > 5000:
            raise ValueError("Invalid text")
        value = value.strip()
        if (
            info.field_name == "category"
            and value not in SCHEMA["properties"]["category"]["enum"]
        ):
            raise ValueError("Invalid category")
        return value

    @field_validator("reasons", "recommendations", mode="before")
    @classmethod
    def validate_items(cls, value):
        if not isinstance(value, list) or any(
            not isinstance(v, str) or not v.strip() or len(v) > 3000 for v in value
        ):
            raise ValueError("Invalid items")
        return [v.strip() for v in value]

    @model_validator(mode="after")
    def validate_evidence(self):
        if self.riskScore > 20 and not self.reasons:
            raise ValueError("Missing evidence")
        self.riskLevel = (
            "safe"
            if self.riskScore <= 20
            else "low"
            if self.riskScore <= 40
            else "medium"
            if self.riskScore <= 60
            else "high"
            if self.riskScore <= 80
            else "critical"
        )
        return self


class ThreatMatch(StrictModel):
    url: str
    source: str
    threatType: str


class ThreatIntel(StrictModel):
    checked: bool
    matches: list[ThreatMatch]


class AnalyzeResponse(AnalysisResult):
    threatIntel: ThreatIntel
    requestId: UUID
