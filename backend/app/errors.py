from fastapi import Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    def __init__(self, code: str, status: int, message: str, headers=None):
        self.code, self.status, self.message = code, status, message
        self.headers = headers or {}


async def app_error(request: Request, exc: AppError):
    return JSONResponse(
        {"error": {"code": exc.code, "message": exc.message}},
        status_code=exc.status,
        headers=exc.headers,
    )
