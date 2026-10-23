import httpx
import pytest
from fakeredis.aioredis import FakeRedis
from pydantic import ValidationError

from app.config import Settings
from app.main import create_app


@pytest.mark.asyncio
async def test_health_and_envelope():
    app = create_app(Settings(app_env="test", database_url="sqlite+aiosqlite://"))
    app.state.redis = FakeRedis(decode_responses=True)
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/readyz")
        assert response.status_code == 200
        assert response.headers["cache-control"] == "no-store"
        assert response.headers["x-request-id"]
        assert (await client.get("/healthz")).json() == {"status": "ok"}
        assert (await client.post("/healthz", content="x" * 32769)).status_code == 413
    await app.state.engine.dispose()
    await app.state.redis.aclose()


def test_production_secrets_and_https():
    with pytest.raises(ValidationError):
        Settings(app_env="prod")
    with pytest.raises(ValidationError):
        Settings(llm_api_url="http://localhost")
    app = create_app(
        Settings(app_env="prod", jwt_secret="a" * 32, phone_hash_pepper="b" * 32)
    )
    assert app.openapi_url is None
