"""Publish an explicitly selected dictionary with the locally configured admin key."""

import argparse
import json
from pathlib import Path
from urllib.parse import urlsplit

import httpx

from app.config import Settings
from app.services.keywords import KeywordDictionary


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file", type=Path)
    parser.add_argument("--url", default="http://127.0.0.1:8000")
    args = parser.parse_args()
    settings = Settings()
    if not settings.admin_api_key:
        raise SystemExit("ADMIN_API_KEY is not configured")
    url = urlsplit(args.url)
    if (
        url.scheme not in {"http", "https"}
        or not url.hostname
        or url.username
        or url.query
        or url.fragment
    ):
        raise SystemExit("Invalid backend URL")
    data = KeywordDictionary.model_validate(
        json.loads(args.file.read_text(encoding="utf-8"))
    )
    with httpx.Client(timeout=15, follow_redirects=False) as client:
        response = client.post(
            args.url.rstrip("/") + "/v1/admin/keywords",
            json=data.model_dump(),
            headers={"X-Admin-Key": settings.admin_api_key},
        )
    if response.status_code != 201:
        raise SystemExit(
            f"Publish failed (HTTP {response.status_code}); no server details logged"
        )
    print(f"Published {data.lang} dictionary version {data.version}")


if __name__ == "__main__":
    main()
