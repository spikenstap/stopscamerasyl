import json
from copy import deepcopy

import httpx
import pytest
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.errors import AppError
from app.models import BlockedDomain
from app.services.llm import OpenAiCompatibleProvider, get_llm
from tests.test_reputation import authenticate

VALID = {
    "riskScore": 30,
    "confidence": 0.8,
    "riskLevel": "critical",
    "isScam": False,
    "category": "unknown",
    "summary": " Проверка ",
    "reasons": [" Причина "],
    "recommendations": [" Совет "],
}
BODY = {"type": "text", "content": "Проверка", "language": "ru"}


class FakeLlm:
    def __init__(self, result=None):
        self.result = result if result is not None else deepcopy(VALID)
        self.calls = []

    async def complete(self, payload):
        self.calls.append(payload)
        if isinstance(self.result, Exception):
            raise self.result
        return self.result if isinstance(self.result, str) else json.dumps(self.result)


@pytest.fixture
async def ai(client, app):
    provider = FakeLlm()
    app.state.settings.llm_api_key = "test"
    app.dependency_overrides[get_llm] = lambda: provider
    headers, _ = await authenticate(client)
    return provider, headers


async def test_valid_and_cache(client, app, ai):
    provider, headers = ai
    app.state.settings.quota_analyze_per_day = 1
    first = await client.post("/v1/analyze", json=BODY, headers=headers)
    second = await client.post("/v1/analyze", json=BODY, headers=headers)
    assert first.status_code == second.status_code == 200
    assert first.json()["riskLevel"] == "low"
    assert first.json()["summary"] == "Проверка"
    assert first.json()["reasons"] == ["Причина"]
    assert first.json()["requestId"] != second.json()["requestId"]
    assert len(provider.calls) == 1
    assert (
        await client.post(
            "/v1/analyze", json={**BODY, "content": "другой"}, headers=headers
        )
    ).json()["error"]["code"] == "quota_exceeded"


@pytest.mark.parametrize("field", ["reasons", "recommendations"])
@pytest.mark.parametrize("items", [[""], ["   "], ["x" * 3001], ["x"] * 21, [1], []])
async def test_invalid_items(client, ai, field, items):
    provider, headers = ai
    provider.result[field] = items
    response = await client.post("/v1/analyze", json=BODY, headers=headers)
    assert response.status_code == 502
    assert response.json()["error"]["code"] == "ai_invalid_response"
    assert len(provider.calls) == 2


@pytest.mark.parametrize(
    "field,value",
    [
        ("summary", " "),
        ("summary", "x" * 5001),
        ("category", " "),
        ("riskScore", 101),
        ("riskScore", True),
        ("confidence", float("inf")),
        ("isScam", "yes"),
    ],
)
async def test_invalid_fields(client, ai, field, value):
    provider, headers = ai
    provider.result[field] = value
    response = await client.post("/v1/analyze", json=BODY, headers=headers)
    assert response.status_code == 502 and len(provider.calls) == 2


async def test_bad_json(client, ai):
    provider, headers = ai
    provider.result = "not json"
    response = await client.post("/v1/analyze", json=BODY, headers=headers)
    assert response.status_code == 502 and len(provider.calls) == 2


async def test_unconfigured_timeout_and_rate(client, app, ai):
    provider, headers = ai
    app.state.settings.llm_api_key = ""
    assert (await client.post("/v1/analyze", json=BODY, headers=headers)).json()[
        "error"
    ]["code"] == "ai_not_configured"
    assert not provider.calls
    app.state.settings.llm_api_key = "test"
    provider.result = AppError("ai_unavailable", 504, "AI request timed out")
    assert (
        await client.post("/v1/analyze", json=BODY, headers=headers)
    ).status_code == 504
    app.state.settings.rate_analyze_per_min = 1
    assert (
        await client.post("/v1/analyze", json=BODY, headers=headers)
    ).status_code == 429


async def test_redact_and_threat(client, app, ai):
    provider, headers = ai
    async with async_sessionmaker(app.state.engine)() as session:
        session.add(
            BlockedDomain(domain="example.org", category="phishing", source="test")
        )
        await session.commit()
    provider.result["summary"] = "карта 4111 1111 1111 1111 код 1234"
    body = {
        **BODY,
        "content": "карта 4111 1111 1111 1111 код 1234 https://example.org/a",
        "localSignals": {"text": "код 9876"},
    }
    response = await client.post("/v1/analyze", json=body, headers=headers)
    assert response.status_code == 200
    result = response.json()
    assert result["riskScore"] == 85 and result["confidence"] == 0.9
    assert result["riskLevel"] == "critical" and result["category"] == "phishing"
    assert result["isScam"] and "[CARD]" in result["summary"]
    assert "1234" not in provider.calls[0]["content"]
    assert "9876" not in str(provider.calls[0]["localSignals"])


@pytest.mark.parametrize(
    "case,status",
    [
        ("ok", 200),
        ("timeout", 504),
        ("error", 502),
        ("refusal", 502),
        ("truncated", 502),
        ("malformed", 502),
    ],
)
async def test_real_provider_transport(app, case, status):
    def handler(request):
        data = json.loads(request.content)
        assert data["response_format"]["json_schema"]["strict"] is True
        assert data["temperature"] == 0.2
        assert "Russian" in data["messages"][0]["content"]
        if case == "timeout":
            raise httpx.ReadTimeout("private")
        if case == "error":
            return httpx.Response(500)
        if case == "malformed":
            return httpx.Response(200, json={})
        return httpx.Response(
            200,
            json={
                "choices": [
                    {
                        "finish_reason": "length" if case == "truncated" else "stop",
                        "message": {
                            "content": json.dumps(VALID),
                            "refusal": "no" if case == "refusal" else None,
                        },
                    }
                ]
            },
        )

    provider = OpenAiCompatibleProvider(
        app.state.settings, httpx.MockTransport(handler)
    )
    if status == 200:
        assert json.loads(await provider.complete({"language": "ru"})) == VALID
    else:
        with pytest.raises(AppError) as failure:
            await provider.complete({"language": "ru"})
        assert failure.value.status == status
