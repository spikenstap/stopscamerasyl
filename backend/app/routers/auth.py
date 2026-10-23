from datetime import timedelta

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.errors import AppError
from app.models import Device, aware, utcnow
from app.ratelimit import client_ip, consume
from app.schemas import RegisterRequest, RegisterResponse, TokenRequest, TokenResponse
from app.security import hash_secret, issue_token, new_secret, verify_secret

router = APIRouter(prefix="/v1/auth")


@router.post("/register", status_code=201, response_model=RegisterResponse)
async def register(
    body: RegisterRequest,
    request: Request,
    session: AsyncSession = Depends(get_session),
):
    settings = request.app.state.settings
    await consume(
        request.app.state.redis,
        "register:" + client_ip(request),
        settings.rate_register_per_ip_per_hour,
        3600,
    )
    secret = new_secret()
    device = Device(
        secret_hash=hash_secret(secret),
        platform=body.platform,
        app_version=body.appVersion,
    )
    session.add(device)
    await session.commit()
    return {"deviceId": device.id, "deviceSecret": secret}


@router.post("/token", response_model=TokenResponse)
async def token(
    body: TokenRequest, request: Request, session: AsyncSession = Depends(get_session)
):
    settings = request.app.state.settings
    await consume(
        request.app.state.redis,
        "token:" + client_ip(request),
        settings.rate_token_per_ip_per_min,
        60,
    )
    device = await session.get(Device, body.deviceId)
    valid = verify_secret(body.deviceSecret, device.secret_hash if device else "0" * 64)
    if not valid or device is None:
        raise AppError("unauthorized", 401, "Unauthorized")
    if device.blocked:
        raise AppError("device_blocked", 403, "Device blocked")
    if utcnow() - aware(device.last_seen_at) >= timedelta(hours=1):
        device.last_seen_at = utcnow()
        await session.commit()
    return {
        "accessToken": issue_token(device.id, settings),
        "tokenType": "Bearer",
        "expiresIn": settings.jwt_ttl_minutes * 60,
    }
