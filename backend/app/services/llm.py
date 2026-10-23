from typing import Protocol

import httpx
from fastapi import Request

from app.errors import AppError
from app.services.prompts import SCHEMA, SYSTEM_PROMPT


class LlmProvider(Protocol):
    async def complete(self, payload: dict) -> str: ...


class OpenAiCompatibleProvider:
    def __init__(self, settings, transport=None):
        self.settings, self.transport = settings, transport

    async def complete(self, payload):
        import json

        language = "Kazakh" if payload["language"] == "kk" else "Russian"
        try:
            async with httpx.AsyncClient(
                timeout=self.settings.llm_timeout_seconds,
                transport=self.transport,
                follow_redirects=False,
            ) as client:
                response = await client.post(
                    self.settings.llm_api_url,
                    headers={"Authorization": "Bearer " + self.settings.llm_api_key},
                    json={
                        "model": self.settings.llm_model,
                        "messages": [
                            {
                                "role": "system",
                                "content": SYSTEM_PROMPT
                                + f"\nWrite summary, reasons and recommendations in {language}.",
                            },
                            {
                                "role": "user",
                                "content": json.dumps(payload, ensure_ascii=False),
                            },
                        ],
                        "response_format": {
                            "type": "json_schema",
                            "json_schema": {
                                "name": "scam_analysis",
                                "strict": True,
                                "schema": SCHEMA,
                            },
                        },
                        "temperature": 0.2,
                        "max_tokens": 1200,
                    },
                )
            response.raise_for_status()
        except httpx.TimeoutException:
            raise AppError("ai_unavailable", 504, "AI request timed out") from None
        except httpx.HTTPError:
            raise AppError("ai_unavailable", 502, "AI service unavailable") from None
        try:
            choice = response.json()["choices"][0]
            if (
                choice["finish_reason"] != "stop"
                or choice["message"].get("refusal") is not None
            ):
                raise ValueError()
            content = choice["message"]["content"]
            if not isinstance(content, str) or len(content) > 100000:
                raise ValueError()
            return content
        except (ValueError, KeyError, IndexError, TypeError, AttributeError):
            raise AppError("ai_invalid_response", 502, "Invalid AI response") from None


def get_llm(request: Request):
    return OpenAiCompatibleProvider(request.app.state.settings)
