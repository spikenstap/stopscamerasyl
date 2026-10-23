from datetime import timedelta

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.errors import AppError
from app.models import Device, aware, utcnow
from app.security import read_token


async def get_current_device(
    request: Request, session: AsyncSession = Depends(get_session)
):
    authorization = request.headers.get("authorization", "").split()
    if len(authorization) != 2 or authorization[0].lower() != "bearer":
        raise AppError("unauthorized", 401, "Unauthorized")
    device_id = read_token(authorization[1], request.app.state.settings)
    device = await session.get(Device, device_id)
    if device is None:
        raise AppError("unauthorized", 401, "Unauthorized")
    if device.blocked:
        raise AppError("device_blocked", 403, "Device blocked")
    if utcnow() - aware(device.last_seen_at) >= timedelta(hours=1):
        device.last_seen_at = utcnow()
        await session.commit()
    request.state.device_id = str(device.id)
    return device
