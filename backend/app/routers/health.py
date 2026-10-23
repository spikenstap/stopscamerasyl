from fastapi import APIRouter, Request
from sqlalchemy import text

from app.errors import AppError

router = APIRouter()


@router.get("/healthz")
async def health():
    return {"status": "ok"}


@router.get("/readyz")
async def ready(request: Request):
    try:
        async with request.app.state.engine.connect() as connection:
            await connection.execute(text("SELECT 1"))
        await request.app.state.redis.ping()
    except Exception:
        raise AppError("internal", 503, "Service unavailable") from None
    return {"status": "ok"}
