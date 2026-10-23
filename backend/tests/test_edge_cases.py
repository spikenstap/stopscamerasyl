import json
from datetime import timedelta
from uuid import UUID, uuid4

import pytest
from redis.exceptions import ConnectionError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.models import Device, PhoneReport, PhoneVerdict, utcnow
from app.security import hash_secret, phone_hash
from app.services.llm import get_llm
from tests.test_analyze import BODY, VALID, FakeLlm
from tests.test_reputation import authenticate, sample_number


async def test_auth_and_metadata(client, app):
    payload = {"phoneNumber": sample_number()}
    assert (await client.post("/v1/phone/check", json=payload)).status_code == 401
    headers, device_id = await authenticate(client)
    request_id = str(uuid4())
    response = await client.post(
        "/v1/phone/check", json=payload, headers={**headers, "X-Request-Id": request_id}
    )
    assert response.headers["X-Request-Id"] == request_id
    assert (
        await client.post(
            "/v1/phone/check", json={"phoneNumber": "112"}, headers=headers
        )
    ).json()["reason"] == "short_code"
    assert (
        await client.post(
            "/v1/phone/report",
            json={"phoneNumber": "112", "category": "other"},
            headers=headers,
        )
    ).status_code == 422
    async with async_sessionmaker(
        app.state.engine, expire_on_commit=False
    )() as session:
        device = await session.get(Device, UUID(device_id))
        device.last_seen_at = utcnow() - timedelta(hours=2)
        await session.commit()
        await client.post("/v1/phone/check", json=payload, headers=headers)
        await session.refresh(device)
        assert device.last_seen_at.replace(
            tzinfo=utcnow().tzinfo
        ) > utcnow() - timedelta(minutes=1)
        device.blocked = True
        await session.commit()
    assert (
        await client.post("/v1/phone/check", json=payload, headers=headers)
    ).status_code == 403


async def test_blocked_and_old_reports_ignored(client, app):
    headers, caller = await authenticate(client)
    number = sample_number()
    hashed = phone_hash(number, app.state.settings.phone_hash_pepper)
    async with async_sessionmaker(app.state.engine)() as session:
        for index in range(5):
            device = Device(
                secret_hash=hash_secret(str(index)),
                platform="android",
                app_version="2",
                blocked=index < 4,
            )
            session.add(device)
            await session.flush()
            session.add(
                PhoneReport(
                    phone_hash=hashed,
                    device_id=device.id,
                    category="other",
                    weight=1,
                    created_at=utcnow() - timedelta(days=100 if index == 4 else 0),
                )
            )
        await session.commit()
    response = await client.post(
        "/v1/phone/check", json={"phoneNumber": number}, headers=headers
    )
    assert response.json()["status"] == "unknown"


async def test_expiry_capped_and_report_quota(client, app):
    headers, device_id = await authenticate(client)
    number = sample_number()
    app.state.settings.quota_phone_report_per_day = 1
    payload = {"phoneNumber": number, "category": "other"}
    assert (
        await client.post("/v1/phone/report", json=payload, headers=headers)
    ).status_code == 202
    await client.request(
        "DELETE", "/v1/phone/report", json={"phoneNumber": number}, headers=headers
    )
    assert (
        await client.post("/v1/phone/report", json=payload, headers=headers)
    ).status_code == 429
    async with async_sessionmaker(app.state.engine)() as session:
        session.add(
            PhoneVerdict(
                phone_hash=phone_hash(number, app.state.settings.phone_hash_pepper),
                status="clear",
                source="test",
                expires_at=utcnow() + timedelta(minutes=30),
            )
        )
        await session.commit()
    rep = (
        await client.post(
            "/v1/phone/check", json={"phoneNumber": number}, headers=headers
        )
    ).json()
    assert 0 < rep["expiresAt"] - int(utcnow().timestamp() * 1000) <= 1800000


async def test_redis_failure_and_health(client, app, monkeypatch):
    async def broken(*args, **kwargs):
        raise ConnectionError("private")

    monkeypatch.setattr(app.state.redis, "eval", broken)
    monkeypatch.setattr(app.state.redis, "ping", broken)
    assert (
        await client.post(
            "/v1/auth/register", json={"platform": "android", "appVersion": "2"}
        )
    ).status_code == 503
    assert (await client.get("/readyz")).status_code == 503
    assert (await client.get("/healthz")).status_code == 200


@pytest.mark.parametrize("stage", ["get", "set"])
async def test_analysis_cache_failure(client, app, monkeypatch, stage):
    headers, _ = await authenticate(client)
    app.state.settings.llm_api_key = "test"
    app.dependency_overrides[get_llm] = lambda: FakeLlm()

    async def broken(*args, **kwargs):
        raise ConnectionError("private")

    monkeypatch.setattr(app.state.redis, stage, broken)
    response = await client.post("/v1/analyze", json=BODY, headers=headers)
    assert response.status_code == 503 and "private" not in response.text


async def test_valid_retry_and_safe_empty_reasons(client, app):
    provider = FakeLlm()
    calls = []

    async def complete(payload):
        calls.append(payload)
        return (
            "invalid"
            if len(calls) == 1
            else json.dumps({**VALID, "riskScore": 0, "reasons": []})
        )

    provider.complete = complete
    app.state.settings.llm_api_key = "test"
    app.dependency_overrides[get_llm] = lambda: provider
    headers, _ = await authenticate(client)
    response = await client.post("/v1/analyze", json=BODY, headers=headers)
    assert response.status_code == 200 and len(calls) == 2
    assert response.json()["riskLevel"] == "safe"


async def test_input_bounds(client, app):
    headers, _ = await authenticate(client)
    for extra in [
        {"content": " "},
        {"content": "x" * 5001},
        {"localSignals": {"data": "x" * 8193}},
        {"extra": True},
    ]:
        assert (
            await client.post("/v1/analyze", json={**BODY, **extra}, headers=headers)
        ).status_code == 422


async def test_logs_do_not_include_inputs(client, app, caplog):
    import logging

    caplog.set_level(logging.INFO, logger="stopscam.access")
    private = "secret-input-not-for-logs"
    await client.post("/not-found/" + private, content=private)
    assert private not in caplog.text
    entry = json.loads(caplog.records[-1].message)
    assert entry["path"] == "<unmatched>"


def test_prompts_match_client():
    from pathlib import Path

    from app.services.prompts import SYSTEM_PROMPT

    source = Path("../lib/services/scam_ai_service.dart").read_text(encoding="utf-8")
    assert (
        SYSTEM_PROMPT
        == source.split("static const systemPrompt = " + "'" * 3)[1].split("'" * 3)[0]
    )


async def test_three_mature_reports_and_no_plaintext(client, app):
    headers, caller = await authenticate(client)
    number = sample_number()
    for index in range(3):
        auth, device_id = await authenticate(client)
        async with async_sessionmaker(app.state.engine)() as session:
            device = await session.get(Device, UUID(device_id))
            device.created_at = utcnow() - timedelta(days=2)
            await session.commit()
        assert (
            await client.post(
                "/v1/phone/report",
                json={"phoneNumber": number, "category": "other"},
                headers=auth,
            )
        ).status_code == 202
        rep = (
            await client.post(
                "/v1/phone/check", json={"phoneNumber": number}, headers=headers
            )
        ).json()
        assert rep["status"] == ("flagged" if index == 2 else "unknown")
        assert rep["confirmed"] is False and rep["confidence"] <= 0.9
    from app.models import Base

    async with app.state.engine.connect() as connection:
        for table in Base.metadata.sorted_tables:
            assert number not in str((await connection.execute(select(table))).all())
