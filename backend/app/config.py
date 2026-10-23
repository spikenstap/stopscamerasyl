from typing import Literal
from urllib.parse import urlsplit

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    app_env: Literal["dev", "test", "prod"] = "dev"
    database_url: str = "postgresql+asyncpg://stopscam:stopscam@db:5432/stopscam"
    redis_url: str = "redis://redis:6379/0"
    jwt_secret: str = ""
    jwt_ttl_minutes: int = Field(15, gt=0)
    phone_hash_pepper: str = ""
    admin_api_key: str = ""
    llm_api_key: str = ""
    llm_api_url: str = "https://api.openai.com/v1/chat/completions"
    llm_model: str = "gpt-4o-mini"
    llm_timeout_seconds: float = Field(45, gt=0)
    safe_browsing_api_key: str = ""
    trusted_proxy_count: int = Field(0, ge=0)
    rate_analyze_per_min: int = Field(10, gt=0)
    quota_analyze_per_day: int = Field(50, gt=0)
    rate_phone_check_per_min: int = Field(30, gt=0)
    quota_phone_report_per_day: int = Field(10, gt=0)
    rate_register_per_ip_per_hour: int = Field(10, gt=0)
    rate_token_per_ip_per_min: int = Field(10, gt=0)
    reputation_flag_threshold: float = Field(3.0, gt=0)
    reputation_window_days: int = Field(90, gt=0)
    analysis_cache_ttl_seconds: int = Field(3600, gt=0)
    max_content_chars: int = Field(5000, gt=0)

    @model_validator(mode="after")
    def validate_configuration(self):
        url = urlsplit(self.llm_api_url)
        if url.scheme != "https" or not url.hostname or url.username or url.password:
            raise ValueError("LLM_API_URL must be an HTTPS URL without credentials")
        if self.app_env == "prod" and (
            len(self.jwt_secret) < 32 or len(self.phone_hash_pepper) < 32
        ):
            raise ValueError("Production secrets must contain at least 32 characters")
        return self
