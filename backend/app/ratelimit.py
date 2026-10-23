import hashlib
from datetime import datetime, timezone
from ipaddress import ip_address

from redis.exceptions import RedisError

from app.errors import AppError

SCRIPT = """
local count = redis.call('INCR', KEYS[1])
if count == 1 then redis.call('EXPIRE', KEYS[1], ARGV[1]) end
return {count, redis.call('TTL', KEYS[1])}
"""


def client_ip(request):
    host = request.client.host if request.client else "unknown"
    count = request.app.state.settings.trusted_proxy_count
    if count:
        forwarded = request.headers.get("x-forwarded-for", "").split(",")
        if len(forwarded) >= count:
            try:
                host = str(ip_address(forwarded[-count].strip()))
            except ValueError:
                pass
    return hashlib.sha256(host.encode()).hexdigest()


async def consume(redis, key, limit, seconds, quota=False):
    now = datetime.now(timezone.utc)
    if quota:
        suffix = now.strftime("%Y-%m-%d")
        seconds = 86400 - (now.hour * 3600 + now.minute * 60 + now.second)
    else:
        suffix = str(int(now.timestamp()) // seconds)
        seconds -= int(now.timestamp()) % seconds
    try:
        count, ttl = await redis.eval(SCRIPT, 1, f"limit:{key}:{suffix}", seconds)
    except RedisError:
        raise AppError("internal", 503, "Service unavailable") from None
    if count > limit:
        raise AppError(
            "quota_exceeded" if quota else "rate_limited",
            429,
            "Daily quota exceeded" if quota else "Too many requests",
            {"Retry-After": str(max(1, ttl))},
        )
