import math
from copy import deepcopy

import pytest

from app.services.llm import get_llm
from tests.test_analyze import BODY, VALID, FakeLlm
from tests.test_reputation import authenticate, sample_number


def dart_length(value):
    return len(value.encode("utf-16-le")) // 2


def client_analysis(j):
    assert type(j["riskScore"]) is int and 0 <= j["riskScore"] <= 100
    assert (
        type(j["confidence"]) in (int, float)
        and math.isfinite(j["confidence"])
        and 0 <= j["confidence"] <= 1
    )
    assert type(j["isScam"]) is bool
    assert j["riskLevel"] in ["safe", "low", "medium", "high", "critical"]
    assert j["category"] in [
        "phishing",
        "fake_bank",
        "social_engineering",
        "investment_scam",
        "fake_delivery",
        "account_theft",
        "malicious_link",
        "suspicious_message",
        "unknown",
    ]
    for key in ["category", "summary"]:
        assert (
            isinstance(j[key], str) and j[key].strip() and dart_length(j[key]) <= 5000
        )
    for key in ["reasons", "recommendations"]:
        assert isinstance(j[key], list) and len(j[key]) <= 20
        assert all(
            isinstance(v, str) and v.strip() and dart_length(v) <= 3000 for v in j[key]
        )
    assert j["recommendations"]
    assert j["riskScore"] <= 20 or j["reasons"]


def client_reputation(j):
    assert j["status"] in ["unknown", "clear", "flagged"]
    assert (
        type(j["confidence"]) in (float, int)
        and math.isfinite(j["confidence"])
        and 0 <= j["confidence"] <= 1
    )
    assert type(j["confirmed"]) is bool and isinstance(j["source"], str)
    assert j["status"] == "unknown" or j["source"].strip()
    assert isinstance(j["reason"], str)
    assert type(j["expiresAt"]) is int


async def test_endpoint_contracts(client, app):
    app.state.settings.llm_api_key = "test"
    app.dependency_overrides[get_llm] = lambda: FakeLlm()
    headers, _ = await authenticate(client)
    response = await client.post("/v1/analyze", json=BODY, headers=headers)
    client_analysis(response.json())
    response = await client.post(
        "/v1/phone/check", json={"phoneNumber": sample_number()}, headers=headers
    )
    client_reputation(response.json())


@pytest.mark.parametrize("field", ["reasons", "recommendations"])
@pytest.mark.parametrize("items", [[""], ["  "], ["x" * 3001], ["x"] * 21])
async def test_invalid_contract_rejected_by_server_and_client(
    client, app, field, items
):
    result = deepcopy(VALID)
    result[field] = items
    with pytest.raises(AssertionError):
        client_analysis(result)
    provider = FakeLlm(result)
    app.state.settings.llm_api_key = "test"
    app.dependency_overrides[get_llm] = lambda: provider
    headers, _ = await authenticate(client)
    response = await client.post("/v1/analyze", json=BODY, headers=headers)
    assert response.status_code == 502
    assert response.json()["error"]["code"] == "ai_invalid_response"
    assert len(provider.calls) == 2
