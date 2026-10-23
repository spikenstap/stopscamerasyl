from uuid import UUID, uuid4

import jwt
import pytest
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.errors import AppError
from app.models import Device
from app.security import read_token


async def test_registration_token_and_secret(client, app):
    response = await client.post(
        "/v1/auth/register", json={"platform": "android", "appVersion": "2"}
    )
    assert response.status_code == 201
    credentials = response.json()
    token = await client.post("/v1/auth/token", json=credentials)
    assert token.status_code == 200
    assert read_token(token.json()["accessToken"], app.state.settings) == UUID(
        credentials["deviceId"]
    )
    credentials["deviceSecret"] = "wrong"
    wrong = await client.post("/v1/auth/token", json=credentials)
    credentials["deviceId"] = str(uuid4())
    absent = await client.post("/v1/auth/token", json=credentials)
    assert wrong.status_code == absent.status_code == 401
    assert wrong.json() == absent.json()


async def test_blocked(client, app):
    credentials = (
        await client.post(
            "/v1/auth/register", json={"platform": "android", "appVersion": "2"}
        )
    ).json()
    async with async_sessionmaker(app.state.engine)() as session:
        device = await session.get(Device, UUID(credentials["deviceId"]))
        device.blocked = True
        await session.commit()
    assert (await client.post("/v1/auth/token", json=credentials)).status_code == 403


@pytest.mark.parametrize(
    "algorithm,typ,expiry",
    [
        ("none", "access", 9999999999),
        ("HS384", "access", 9999999999),
        ("HS256", "refresh", 9999999999),
        ("HS256", "access", 1),
    ],
)
def test_bad_tokens(app, algorithm, typ, expiry):
    token = jwt.encode(
        {"sub": str(uuid4()), "exp": expiry, "typ": typ},
        "" if algorithm == "none" else app.state.settings.jwt_secret,
        algorithm=algorithm,
    )
    with pytest.raises(AppError):
        read_token(token, app.state.settings)


async def test_auth_rates(client, app):
    app.state.settings.rate_register_per_ip_per_hour = 1
    payload = {"platform": "android", "appVersion": "2"}
    credentials = (await client.post("/v1/auth/register", json=payload)).json()
    assert (await client.post("/v1/auth/register", json=payload)).status_code == 429
    app.state.settings.rate_token_per_ip_per_min = 1
    assert (await client.post("/v1/auth/token", json=credentials)).status_code == 200
    assert (await client.post("/v1/auth/token", json=credentials)).status_code == 429
