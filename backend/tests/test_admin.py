from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.cli import purge
from app.models import Base, Device, PhoneReport, PhoneVerdict, utcnow
from tests.test_reputation import sample_number


async def test_admin_disabled_and_wrong_key(client, app):
    assert (await client.get("/v1/admin/stats")).status_code == 404
    app.state.settings.admin_api_key = "test-admin"
    assert (await client.get("/v1/admin/stats")).status_code == 401
    assert (
        await client.get("/v1/admin/stats", headers={"X-Admin-Key": "wrong"})
    ).status_code == 401


async def test_admin_writes_and_dump(client, app):
    app.state.settings.admin_api_key = "test-admin"
    headers = {"X-Admin-Key": "test-admin"}
    payload = {"phoneNumber": sample_number(), "status": "flagged", "source": "test"}
    assert (
        await client.post("/v1/admin/phone-verdicts", json=payload, headers=headers)
    ).status_code == 201
    assert (
        await client.post(
            "/v1/admin/phone-verdicts",
            json={**payload, "status": "clear"},
            headers=headers,
        )
    ).status_code == 201
    assert (
        await client.post(
            "/v1/admin/blocked-domains",
            json={"domain": "EXAMPLE.ORG", "category": "phishing", "source": "test"},
            headers=headers,
        )
    ).status_code == 201
    stats = (await client.get("/v1/admin/stats", headers=headers)).json()
    assert stats["verdicts"] == stats["domains"] == 1
    async with app.state.engine.connect() as connection:
        for table in Base.metadata.sorted_tables:
            rows = (await connection.execute(select(table))).all()
            assert sample_number() not in str(rows)
    assert (
        await client.request(
            "DELETE",
            "/v1/admin/phone-verdicts",
            json={"phoneNumber": sample_number()},
            headers=headers,
        )
    ).status_code == 204
    assert (
        await client.request(
            "DELETE",
            "/v1/admin/blocked-domains",
            json={"domain": "example.org"},
            headers=headers,
        )
    ).status_code == 204


async def test_purge(app):
    async with async_sessionmaker(
        app.state.engine, expire_on_commit=False
    )() as session:
        device = Device(
            secret_hash="a" * 64,
            platform="android",
            app_version="2",
            last_seen_at=utcnow() - timedelta(days=366),
        )
        session.add(device)
        await session.flush()
        session.add(
            PhoneReport(
                phone_hash="b" * 64, device_id=device.id, category="other", weight=1
            )
        )
        session.add(
            PhoneVerdict(
                phone_hash="b" * 64,
                status="clear",
                source="test",
                expires_at=utcnow() - timedelta(seconds=1),
            )
        )
        await session.commit()
        await purge(session, app.state.settings)
        assert (await session.scalars(select(Device))).all() == []
        assert (await session.scalars(select(PhoneReport))).all() == []
        assert (await session.scalars(select(PhoneVerdict))).all() == []
