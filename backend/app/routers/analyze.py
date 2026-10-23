import json

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.deps import get_current_device
from app.errors import AppError
from app.models import Device
from app.schemas import AnalyzeRequest, AnalyzeResponse
from app.services.analysis import analyze
from app.services.llm import get_llm
from app.services.threat_intel import get_external_threat

router = APIRouter(prefix="/v1")


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_endpoint(
    body: AnalyzeRequest,
    request: Request,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_session),
    llm=Depends(get_llm),
    external=Depends(get_external_threat),
):
    settings = request.app.state.settings
    if (
        len(body.content) > settings.max_content_chars
        or len(json.dumps(body.localSignals, ensure_ascii=False).encode()) > 8192
    ):
        raise AppError("validation_error", 422, "Invalid request")
    result = await analyze(
        body, device, settings, request.app.state.redis, session, llm, external
    )
    return {**result, "requestId": request.state.request_id}
