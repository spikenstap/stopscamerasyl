from dataclasses import dataclass, field
from typing import Protocol
from urllib.parse import urlsplit

import httpx
from fastapi import Request
from sqlalchemy import select

from app.models import BlockedDomain


@dataclass
class ThreatResult:
    checked: bool
    matches: list[dict] = field(default_factory=list)


class ThreatProvider(Protocol):
    async def check(self, urls: list[str]) -> ThreatResult: ...


class LocalBlocklist:
    def __init__(self, session):
        self.session = session

    async def check(self, urls):
        domains = (await self.session.scalars(select(BlockedDomain))).all()
        matches = []
        for url in urls:
            host = urlsplit(url).hostname
            for entry in domains:
                if host == entry.domain or host.endswith("." + entry.domain):
                    matches.append(
                        {
                            "url": url,
                            "source": "stopscam-blocklist",
                            "threatType": entry.category,
                        }
                    )
        return ThreatResult(True, matches)


class SafeBrowsingProvider:
    def __init__(self, api_key, transport=None):
        self.api_key, self.transport = api_key, transport

    async def check(self, urls):
        if not self.api_key or not urls:
            return ThreatResult(False)
        try:
            async with httpx.AsyncClient(
                timeout=3, transport=self.transport, follow_redirects=False
            ) as client:
                response = await client.post(
                    "https://safebrowsing.googleapis.com/v4/threatMatches:find",
                    params={"key": self.api_key},
                    json={
                        "client": {"clientId": "stopscam", "clientVersion": "1"},
                        "threatInfo": {
                            "threatTypes": [
                                "MALWARE",
                                "SOCIAL_ENGINEERING",
                                "UNWANTED_SOFTWARE",
                                "POTENTIALLY_HARMFUL_APPLICATION",
                            ],
                            "platformTypes": ["ANY_PLATFORM"],
                            "threatEntryTypes": ["URL"],
                            "threatEntries": [{"url": url} for url in urls],
                        },
                    },
                )
            response.raise_for_status()
            matches = []
            for item in response.json().get("matches", []):
                url = item["threat"]["url"]
                if url in urls:
                    matches.append(
                        {
                            "url": url,
                            "source": "google-safe-browsing",
                            "threatType": item["threatType"],
                        }
                    )
            return ThreatResult(True, matches)
        except (httpx.HTTPError, ValueError, KeyError, TypeError, AttributeError):
            return ThreatResult(False)


def get_external_threat(request: Request):
    return SafeBrowsingProvider(request.app.state.settings.safe_browsing_api_key)
