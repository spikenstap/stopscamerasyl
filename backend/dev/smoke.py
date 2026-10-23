"""Manual integration check against the explicitly selected dev profile."""

import argparse

import httpx
import phonenumbers


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:8001")
    args = parser.parse_args()
    number = phonenumbers.format_number(
        phonenumbers.example_number("KZ"), phonenumbers.PhoneNumberFormat.E164
    )
    with httpx.Client(base_url=args.url, timeout=60) as client:
        assert client.get("/readyz").status_code == 200
        credentials = client.post(
            "/v1/auth/register", json={"platform": "android", "appVersion": "smoke"}
        ).json()
        token = client.post("/v1/auth/token", json=credentials)
        token.raise_for_status()
        headers = {"Authorization": "Bearer " + token.json()["accessToken"]}
        response = client.post(
            "/v1/phone/check", json={"phoneNumber": number}, headers=headers
        )
        response.raise_for_status()
        assert response.json()["status"] == "unknown", (
            "Use an isolated empty dev database"
        )
        for _ in range(3):
            credentials = client.post(
                "/v1/auth/register", json={"platform": "android", "appVersion": "smoke"}
            ).json()
            token = client.post("/v1/auth/token", json=credentials)
            token.raise_for_status()
            reporter = {"Authorization": "Bearer " + token.json()["accessToken"]}
            assert (
                client.post(
                    "/v1/phone/report",
                    json={"phoneNumber": number, "category": "other"},
                    headers=reporter,
                ).status_code
                == 202
            )
        response = client.post(
            "/v1/phone/check", json={"phoneNumber": number}, headers=headers
        )
        response.raise_for_status()
        assert response.json()["confirmed"] is False
        assert response.json()["status"] == "unknown"  # Three new devices total 0.75.
        response = client.post(
            "/v1/analyze",
            json={"type": "text", "content": "Тест инфраструктуры", "language": "ru"},
            headers=headers,
        )
        response.raise_for_status()
        assert response.json()["requestId"]
    print("Smoke checks passed; AI response came from the dev fixture.")


if __name__ == "__main__":
    main()
