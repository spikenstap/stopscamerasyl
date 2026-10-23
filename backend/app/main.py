import json
import logging
import time
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from uuid import UUID, uuid4

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException
from starlette.responses import JSONResponse

from app.config import Settings
from app.db import make_engine
from app.errors import AppError, app_error
from app.redis import make_redis
from app.routers import auth, health, phone

logger = logging.getLogger("stopscam.access")


class EnvelopeMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)
        started = time.monotonic()
        headers = dict(scope["headers"])
        try:
            request_id = str(UUID(headers.get(b"x-request-id", b"").decode()))
        except (ValueError, UnicodeError):
            request_id = str(uuid4())
        scope.setdefault("state", {})["request_id"] = request_id
        status = 500

        async def wrapped_send(message):
            nonlocal status
            if message["type"] == "http.response.start":
                status = message["status"]
                message["headers"] += [
                    (b"x-request-id", request_id.encode()),
                    (b"x-content-type-options", b"nosniff"),
                    (b"cache-control", b"no-store"),
                ]
            await send(message)

        try:
            body = bytearray()
            while True:
                message = await receive()
                if message["type"] == "http.disconnect":
                    return
                body.extend(message.get("body", b""))
                if len(body) > 32768:
                    response = JSONResponse(
                        {
                            "error": {
                                "code": "validation_error",
                                "message": "Request body too large",
                            }
                        },
                        status_code=413,
                    )
                    await response(scope, receive, wrapped_send)
                    return
                if not message.get("more_body", False):
                    break
            delivered = False

            async def replay():
                nonlocal delivered
                if not delivered:
                    delivered = True
                    return {
                        "type": "http.request",
                        "body": bytes(body),
                        "more_body": False,
                    }
                return await receive()

            await self.app(scope, replay, wrapped_send)
        except Exception:
            response = JSONResponse(
                {"error": {"code": "internal", "message": "Internal server error"}},
                status_code=500,
            )
            await response(scope, receive, wrapped_send)
        finally:
            # Log the route template, never an arbitrary path or query containing PII.
            route = scope.get("route")
            logger.info(
                json.dumps(
                    {
                        "time": datetime.now(timezone.utc).isoformat(),
                        "level": "INFO",
                        "requestId": request_id,
                        "path": getattr(route, "path", "<unmatched>"),
                        "status": status,
                        "duration": round(time.monotonic() - started, 6),
                        "deviceId": scope["state"].get("device_id"),
                    }
                )
            )


def create_app(settings=None):
    settings = settings or Settings()

    @asynccontextmanager
    async def lifespan(app):
        yield
        await app.state.engine.dispose()
        await app.state.redis.aclose()

    app = FastAPI(
        lifespan=lifespan,
        docs_url=None if settings.app_env == "prod" else "/docs",
        redoc_url=None if settings.app_env == "prod" else "/redoc",
        openapi_url=None if settings.app_env == "prod" else "/openapi.json",
    )
    app.state.settings = settings
    app.state.engine = make_engine(settings.database_url)
    app.state.redis = make_redis(settings.redis_url)
    app.add_middleware(EnvelopeMiddleware)
    app.add_exception_handler(AppError, app_error)

    @app.exception_handler(RequestValidationError)
    async def validation_error(request, exc):
        return JSONResponse(
            {"error": {"code": "validation_error", "message": "Invalid request"}},
            status_code=422,
        )

    @app.exception_handler(HTTPException)
    async def http_error(request, exc):
        return JSONResponse(
            {
                "error": {
                    "code": "not_found" if exc.status_code == 404 else "internal",
                    "message": "Not found"
                    if exc.status_code == 404
                    else "Request failed",
                }
            },
            status_code=exc.status_code,
        )

    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(phone.router)
    return app
