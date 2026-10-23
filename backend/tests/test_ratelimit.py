import pytest
from redis.exceptions import ConnectionError
from starlette.requests import Request

from app.errors import AppError
from app.ratelimit import client_ip, consume


async def test_limits(app):
    redis = app.state.redis
    await consume(redis, "test", 1, 60)
    with pytest.raises(AppError) as failure:
        await consume(redis, "test", 1, 60)
    assert failure.value.code == "rate_limited"
    assert int(failure.value.headers["Retry-After"]) > 0
    await consume(redis, "daily", 1, 86400, quota=True)
    with pytest.raises(AppError) as failure:
        await consume(redis, "daily", 1, 86400, quota=True)
    assert failure.value.code == "quota_exceeded"


async def test_redis_fail_closed(app, monkeypatch):
    async def broken(*args):
        raise ConnectionError()

    monkeypatch.setattr(app.state.redis, "eval", broken)
    with pytest.raises(AppError) as failure:
        await consume(app.state.redis, "test", 1, 60)
    assert failure.value.status == 503


def test_proxy(app):
    request = Request(
        {
            "type": "http",
            "app": app,
            "client": ("127.0.0.1", 1),
            "headers": [(b"x-forwarded-for", b"192.0.2.1, 192.0.2.2")],
        }
    )
    direct = client_ip(request)
    app.state.settings.trusted_proxy_count = 1
    assert client_ip(request) != direct
