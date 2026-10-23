import httpx
import pytest
from fakeredis.aioredis import FakeRedis

from app.config import Settings
from app.main import create_app
from app.models import Base


@pytest.fixture
async def app():
    instance = create_app(
        Settings(
            app_env="test",
            database_url="sqlite+aiosqlite://",
            jwt_secret="test-only-" * 6,
            phone_hash_pepper="test-pepper-" * 4,
        )
    )
    instance.state.redis = FakeRedis(decode_responses=True)
    async with instance.state.engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    yield instance
    await instance.state.redis.aclose()
    await instance.state.engine.dispose()


@pytest.fixture
async def client(app):
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app), base_url="https://test"
    ) as instance:
        yield instance
