from typing import Literal

from fastapi import APIRouter, Depends, Query, Request, Response
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.deps import get_current_device
from app.errors import AppError
from app.models import KeywordDictionaryRecord, utcnow
from app.ratelimit import consume
from app.routers.admin import admin_auth, audit
from app.services.keywords import KeywordDictionary, signed_dictionary

router = APIRouter()


@router.get("/v1/keywords")
async def get_keywords(
    request: Request,
    lang: Literal["ru", "kk"],
    version: int = Query(0, ge=0, le=2147483647),
    device=Depends(get_current_device),
    session: AsyncSession = Depends(get_session),
):
    await consume(request.app.state.redis, f"keywords:{device.id}", 30, 60)
    record = await session.get(KeywordDictionaryRecord, lang)
    if record is None:
        raise AppError("not_found", 404, "Dictionary not available")
    etag = f'"{record.etag}"'
    # A version alone is not proof that the client has these exact signed bytes.
    if request.headers.get("if-none-match") == etag and version == record.version:
        return Response(status_code=304, headers={"ETag": etag})
    return Response(
        content=record.envelope, media_type="application/json", headers={"ETag": etag}
    )


@router.post("/v1/admin/keywords", status_code=201, dependencies=[Depends(admin_auth)])
async def put_keywords(
    body: KeywordDictionary,
    request: Request,
    session: AsyncSession = Depends(get_session),
):
    import json

    private_key = request.app.state.settings.keyword_signing_private_key
    if not private_key:
        raise AppError(
            "keywords_not_configured", 503, "Dictionary signing not configured"
        )
    try:
        envelope, etag = signed_dictionary(body, private_key)
    except ValueError:
        raise AppError("validation_error", 422, "Invalid dictionary") from None
    values = {
        "version": body.version,
        "envelope": json.dumps(envelope, separators=(",", ":")),
        "etag": etag,
        "updated_at": utcnow(),
    }
    exists = await session.scalar(
        select(KeywordDictionaryRecord.version).where(
            KeywordDictionaryRecord.lang == body.lang
        )
    )
    if exists is not None:
        changed = await session.execute(
            update(KeywordDictionaryRecord)
            .where(
                KeywordDictionaryRecord.lang == body.lang,
                KeywordDictionaryRecord.version < body.version,
            )
            .values(**values)
        )
        if changed.rowcount != 1:
            raise AppError("version_conflict", 409, "Version must increase")
    else:
        session.add(KeywordDictionaryRecord(lang=body.lang, **values))
    audit(session, "publish_keywords", etag)
    try:
        await session.commit()
    except IntegrityError:
        await session.rollback()
        raise AppError("version_conflict", 409, "Version must increase") from None
    return {"accepted": True, "version": body.version}
