import hashlib
import hmac
import secrets
from datetime import timedelta
from uuid import UUID

import jwt

from app.errors import AppError
from app.models import utcnow


def hash_secret(secret):
    return hashlib.sha256(secret.encode()).hexdigest()


def verify_secret(secret, expected):
    return hmac.compare_digest(hash_secret(secret), expected)


def phone_hash(number, pepper):
    return hmac.new(pepper.encode(), number.encode(), hashlib.sha256).hexdigest()


def issue_token(device_id, settings):
    now = utcnow()
    return jwt.encode(
        {
            "sub": str(device_id),
            "iat": now,
            "exp": now + timedelta(minutes=settings.jwt_ttl_minutes),
            "typ": "access",
        },
        settings.jwt_secret,
        algorithm="HS256",
    )


def read_token(token, settings):
    try:
        claims = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=["HS256"],
            options={"require": ["sub", "exp"]},
        )
        if claims.get("typ") != "access":
            raise ValueError()
        return UUID(claims["sub"])
    except (jwt.PyJWTError, ValueError, TypeError, AttributeError):
        raise AppError("unauthorized", 401, "Unauthorized") from None


def new_secret():
    return secrets.token_urlsafe(32)


def check_admin(provided, expected):
    if not expected:
        raise AppError("not_found", 404, "Not found")
    if not hmac.compare_digest(provided.encode(), expected.encode()):
        raise AppError("unauthorized", 401, "Unauthorized")
