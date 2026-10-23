from datetime import timedelta

from sqlalchemy import func, select

from app.models import Device, PhoneReport, PhoneVerdict, aware, utcnow


def unknown(reason="no_data"):
    return {
        "status": "unknown",
        "confidence": 0,
        "confirmed": False,
        "source": "",
        "reason": reason,
        "expiresAt": int((utcnow() + timedelta(hours=1)).timestamp() * 1000),
    }


async def reputation(session, hashed, settings):
    now = utcnow()
    verdict = await session.get(PhoneVerdict, hashed)
    if verdict and (verdict.expires_at is None or aware(verdict.expires_at) > now):
        expiry = now + timedelta(hours=24)
        if verdict.expires_at:
            expiry = min(expiry, aware(verdict.expires_at))
        return {
            "status": verdict.status,
            "confidence": 0.99 if verdict.status == "flagged" else 0.9,
            "confirmed": True,
            "source": verdict.source,
            "reason": "verified",
            "expiresAt": int(expiry.timestamp() * 1000),
        }
    score = float(
        await session.scalar(
            select(func.coalesce(func.sum(PhoneReport.weight), 0))
            .join(Device)
            .where(
                PhoneReport.phone_hash == hashed,
                Device.blocked.is_(False),
                PhoneReport.created_at
                >= now - timedelta(days=settings.reputation_window_days),
            )
        )
    )
    if score >= settings.reputation_flag_threshold:
        return {
            "status": "flagged",
            "confidence": min(0.9, 0.5 + 0.1 * score),
            "confirmed": False,
            "source": "stopscam-community",
            "reason": "community_reports",
            "expiresAt": int((now + timedelta(hours=6)).timestamp() * 1000),
        }
    return unknown()
