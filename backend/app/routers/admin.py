from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Request, Response
from sqlalchemy import delete, func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.models import (
    AdminAudit,
    BlockedDomain,
    Device,
    PhoneReport,
    PhoneVerdict,
    utcnow,
)
from app.phone import normalize
from app.ratelimit import client_ip, consume
from app.schemas import DomainRequest, DomainWrite, PhoneRequest, VerdictWrite
from app.security import check_admin, hash_secret, phone_hash
from app.urls import normalize_domain


async def admin_auth(request: Request):
    settings = request.app.state.settings
    # Disabled admin endpoints stay indistinguishable from absent endpoints.
    if not settings.admin_api_key:
        check_admin("", "")
    await consume(request.app.state.redis, "admin:" + client_ip(request), 30, 60)
    check_admin(request.headers.get("x-admin-key", ""), settings.admin_api_key)


router = APIRouter(prefix="/v1/admin", dependencies=[Depends(admin_auth)])


async def upsert(session, model, values, key):
    insert = sqlite_insert if session.bind.dialect.name == "sqlite" else pg_insert
    statement = insert(model).values(**values)
    await session.execute(
        statement.on_conflict_do_update(
            index_elements=[key], set_={k: v for k, v in values.items() if k != key}
        )
    )


def audit(session, action, target):
    session.add(AdminAudit(action=action, target_hash=target))


@router.post("/phone-verdicts", status_code=201)
async def verdict(
    body: VerdictWrite, request: Request, session: AsyncSession = Depends(get_session)
):
    hashed = phone_hash(
        normalize(body.phoneNumber), request.app.state.settings.phone_hash_pepper
    )
    expiry = (
        datetime.fromtimestamp(body.expiresAt / 1000, timezone.utc)
        if body.expiresAt is not None
        else None
    )
    await upsert(
        session,
        PhoneVerdict,
        {
            "phone_hash": hashed,
            "status": body.status,
            "source": body.source,
            "source_url": body.sourceUrl,
            "expires_at": expiry,
            "created_at": utcnow(),
        },
        "phone_hash",
    )
    audit(session, "upsert_phone_verdict", hashed)
    await session.commit()
    return {"accepted": True}


@router.delete("/phone-verdicts", status_code=204)
async def remove_verdict(
    body: PhoneRequest, request: Request, session: AsyncSession = Depends(get_session)
):
    hashed = phone_hash(
        normalize(body.phoneNumber), request.app.state.settings.phone_hash_pepper
    )
    await session.execute(delete(PhoneVerdict).where(PhoneVerdict.phone_hash == hashed))
    audit(session, "delete_phone_verdict", hashed)
    await session.commit()
    return Response(status_code=204)


@router.post("/blocked-domains", status_code=201)
async def domain(body: DomainWrite, session: AsyncSession = Depends(get_session)):
    normalized = normalize_domain(body.domain)
    await upsert(
        session,
        BlockedDomain,
        {
            "domain": normalized,
            "category": body.category,
            "source": body.source,
            "created_at": utcnow(),
        },
        "domain",
    )
    audit(session, "upsert_domain", hash_secret(normalized))
    await session.commit()
    return {"accepted": True}


@router.delete("/blocked-domains", status_code=204)
async def remove_domain(
    body: DomainRequest, session: AsyncSession = Depends(get_session)
):
    normalized = normalize_domain(body.domain)
    await session.execute(
        delete(BlockedDomain).where(BlockedDomain.domain == normalized)
    )
    audit(session, "delete_domain", hash_secret(normalized))
    await session.commit()
    return Response(status_code=204)


@router.get("/stats")
async def stats(session: AsyncSession = Depends(get_session)):
    return {
        name: await session.scalar(select(func.count()).select_from(model))
        for name, model in [
            ("devices", Device),
            ("reports", PhoneReport),
            ("verdicts", PhoneVerdict),
            ("domains", BlockedDomain),
        ]
    }
