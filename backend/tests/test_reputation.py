from datetime import timedelta
from uuid import UUID

import phonenumbers
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.models import Device, PhoneReport, PhoneVerdict, utcnow
from app.security import phone_hash


def sample_number():
    return phonenumbers.format_number(
        phonenumbers.example_number("KZ"), phonenumbers.PhoneNumberFormat.E164
    )


async def authenticate(client):
    credentials = (
        await client.post(
            "/v1/auth/register", json={"platform": "android", "appVersion": "2"}
        )
    ).json()
    response = await client.post("/v1/auth/token", json=credentials)
    return {"Authorization": "Bearer " + response.json()["accessToken"]}, credentials[
        "deviceId"
    ]


async def test_reports_and_invariant(client, app):
    payload = {"phoneNumber": sample_number()}
    app.state.settings.rate_register_per_ip_per_hour = 100
    app.state.settings.rate_token_per_ip_per_min = 100
    headers, _ = await authenticate(client)
    assert (await client.post("/v1/phone/check", json=payload, headers=headers)).json()[
        "status"
    ] == "unknown"
    for index in range(12):
        auth, _ = await authenticate(client)
        response = await client.post(
            "/v1/phone/report",
            json={**payload, "category": "suspectedFraud"},
            headers=auth,
        )
        assert response.status_code == 202
        assert (
            await client.post(
                "/v1/phone/report",
                json={**payload, "category": "suspectedFraud"},
                headers=auth,
            )
        ).status_code == 202
        rep = (
            await client.post("/v1/phone/check", json=payload, headers=headers)
        ).json()
        assert rep["confirmed"] is False and rep["confidence"] <= 0.9
        assert rep["status"] == ("flagged" if index == 11 else "unknown")
    async with async_sessionmaker(app.state.engine)() as session:
        reports = (await session.scalars(select(PhoneReport))).all()
        assert len(reports) == 12 and all(float(r.weight) == 0.25 for r in reports)
    assert (
        await client.request("DELETE", "/v1/phone/report", json=payload, headers=auth)
    ).status_code == 204
    assert (await client.post("/v1/phone/check", json=payload, headers=headers)).json()[
        "status"
    ] == "unknown"


async def test_verdict_precedence_and_expiry(client, app):
    headers, device_id = await authenticate(client)
    payload = {"phoneNumber": sample_number()}
    hashed = phone_hash(payload["phoneNumber"], app.state.settings.phone_hash_pepper)
    async with async_sessionmaker(
        app.state.engine, expire_on_commit=False
    )() as session:
        device = await session.get(Device, UUID(device_id))
        device.created_at = utcnow() - timedelta(days=2)
        await session.commit()
        await client.post(
            "/v1/phone/report", json={**payload, "category": "other"}, headers=headers
        )
        assert float((await session.scalar(select(PhoneReport))).weight) == 1
        verdict = PhoneVerdict(
            phone_hash=hashed, status="flagged", source="test-verdict"
        )
        session.add(verdict)
        await session.commit()
        rep = (
            await client.post("/v1/phone/check", json=payload, headers=headers)
        ).json()
        assert rep["confirmed"] and rep["confidence"] == 0.99
        verdict.status = "clear"
        await session.commit()
        assert (
            await client.post("/v1/phone/check", json=payload, headers=headers)
        ).json()["status"] == "clear"
        verdict.expires_at = utcnow() - timedelta(seconds=1)
        await session.commit()
        assert (
            await client.post("/v1/phone/check", json=payload, headers=headers)
        ).json()["status"] == "unknown"
