from fastapi import Request
from redis.asyncio import Redis


def make_redis(url):
    return Redis.from_url(
        url, decode_responses=True, socket_timeout=3, socket_connect_timeout=3
    )


def get_redis(request: Request):
    return request.app.state.redis
