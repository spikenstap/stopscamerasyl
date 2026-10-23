from datetime import timedelta

from fastapi import APIRouter, Depends, Request, Response
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.deps import get_current_device
from app.models import Device, PhoneReport, aware, utcnow
from app.phone import normalize
from app.ratelimit import consume
from app.schemas import (
    AcceptedResponse,
    PhoneReportRequest,
    PhoneRequest,
    ReputationResponse,
)
from app.security import phone_hash
from app.services.reputation import reputation, unknown

router = APIRouter(prefix="/v1/phone")


@router.post("/check", response_model=ReputationResponse)
async def check(
    body: PhoneRequest,
    request: Request,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_session),
):
    settings = request.app.state.settings
    await consume(
        request.app.state.redis,
        "phone:" + str(device.id),
        settings.rate_phone_check_per_min,
        60,
    )
    number = normalize(body.phoneNumber, allow_short=True)
    if number is None:
        return unknown("short_code")
    return await reputation(
        session, phone_hash(number, settings.phone_hash_pepper), settings
    )


@router.post("/report", status_code=202, response_model=AcceptedResponse)
async def report(
    body: PhoneReportRequest,
    request: Request,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_session),
):
    settings = request.app.state.settings
    hashed = phone_hash(normalize(body.phoneNumber), settings.phone_hash_pepper)
    exists = await session.scalar(
        select(PhoneReport.id).where(
            PhoneReport.phone_hash == hashed, PhoneReport.device_id == device.id
        )
    )
    if exists:
        return {"accepted": True}
    await consume(
        request.app.state.redis,
        "report:" + str(device.id),
        settings.quota_phone_report_per_day,
        86400,
        quota=True,
    )
    session.add(
        PhoneReport(
            phone_hash=hashed,
            device_id=device.id,
            category=body.category,
            weight=1.0
            if utcnow() - aware(device.created_at) >= timedelta(hours=24)
            else 0.25,
        )
    )
    try:
        await session.commit()
    except IntegrityError:
        await session.rollback()
        existing = await session.scalar(
            select(PhoneReport.id).where(
                PhoneReport.phone_hash == hashed, PhoneReport.device_id == device.id
            )
        )
        if existing is None:
            raise
    return {"accepted": True}


@router.delete("/report", status_code=204)
async def revoke(
    body: PhoneRequest,
    request: Request,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_session),
):
    hashed = phone_hash(
        normalize(body.phoneNumber), request.app.state.settings.phone_hash_pepper
    )
    await session.execute(
        delete(PhoneReport).where(
            PhoneReport.phone_hash == hashed, PhoneReport.device_id == device.id
        )
    )
    await session.commit()
    return Response(status_code=204)
