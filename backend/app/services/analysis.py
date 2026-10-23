import hashlib
import json

from pydantic import ValidationError
from redis.exceptions import RedisError

from app.errors import AppError
from app.ratelimit import consume
from app.redact import redact
from app.schemas import AnalysisResult
from app.services.threat_intel import LocalBlocklist
from app.urls import extract_urls


def redact_value(value):
    if isinstance(value, str):
        return redact(value)
    if isinstance(value, list):
        return [redact_value(item) for item in value]
    if isinstance(value, dict):
        return {redact(key): redact_value(item) for key, item in value.items()}
    return value


def cache_key(body):
    signals = hashlib.sha256(
        json.dumps(
            body.localSignals, sort_keys=True, separators=(",", ":"), ensure_ascii=False
        ).encode()
    ).hexdigest()
    raw = f"{body.type}|{body.language}|{body.content}|{signals}"
    return "analysis:" + hashlib.sha256(raw.encode()).hexdigest()


async def analyze(body, device, settings, redis, session, llm, external):
    await consume(redis, "analyze:" + str(device.id), settings.rate_analyze_per_min, 60)
    if not settings.llm_api_key:
        raise AppError("ai_not_configured", 503, "AI is not configured")
    key = cache_key(body)
    try:
        cached = await redis.get(key)
    except RedisError:
        raise AppError("internal", 503, "Service unavailable") from None
    if cached:
        return json.loads(cached)
    urls = extract_urls(body.content, body.type)
    local = await LocalBlocklist(session).check(urls)
    other = await external.check(urls)
    threat = {
        "checked": local.checked
        and (other.checked if settings.safe_browsing_api_key else True),
        "matches": local.matches + other.matches,
    }
    payload = {
        "analysisType": body.type,
        "content": redact(body.content),
        "language": body.language,
        "localSignals": redact_value(body.localSignals),
        "localUrlSignals": [],
        "threatIntel": threat,
    }
    await consume(
        redis,
        "analyze-daily:" + str(device.id),
        settings.quota_analyze_per_day,
        86400,
        quota=True,
    )
    for attempt in range(2):
        try:
            raw = await llm.complete(payload)
            result = AnalysisResult.model_validate_json(raw)
            result = AnalysisResult.model_validate(redact_value(result.model_dump()))
            break
        except (ValidationError, ValueError, TypeError):
            if attempt == 1:
                raise AppError(
                    "ai_invalid_response", 502, "Invalid AI response"
                ) from None
        except AppError as exc:
            if exc.code != "ai_invalid_response" or attempt == 1:
                raise
    if threat["matches"]:
        result.riskScore = max(result.riskScore, 85)
        result.confidence = max(result.confidence, 0.9)
        result.isScam = True
        result.category = (
            "phishing"
            if any(
                m["threatType"] in {"phishing", "SOCIAL_ENGINEERING"}
                for m in threat["matches"]
            )
            else "malicious_link"
        )
        sources = ", ".join(sorted({m["source"] for m in threat["matches"]}))
        reason = (
            f"Сілтеме қауіпті сілтемелер тізімінен табылды (дереккөз: {sources})."
            if body.language == "kk"
            else f"Ссылка найдена в списке опасных (источник: {sources})."
        )
        result.reasons = result.reasons[:19] + [reason]
    result = AnalysisResult.model_validate(result.model_dump())
    response = {**result.model_dump(), "threatIntel": threat}
    try:
        await redis.set(
            key,
            json.dumps(response, ensure_ascii=False),
            ex=settings.analysis_cache_ttl_seconds,
        )
    except RedisError:
        raise AppError("internal", 503, "Service unavailable") from None
    return response
