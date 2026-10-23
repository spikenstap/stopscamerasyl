import httpx
import pytest
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.models import BlockedDomain
from app.services.threat_intel import LocalBlocklist, SafeBrowsingProvider


@pytest.mark.parametrize("case", ["match", "empty", "error", "timeout", "malformed"])
async def test_safe_browsing(case):
    url = "https://example.org/a"

    def handler(request):
        if case == "timeout":
            raise httpx.ReadTimeout("private detail")
        if case == "error":
            return httpx.Response(500)
        if case == "malformed":
            return httpx.Response(200, json={"matches": [{}]})
        return httpx.Response(
            200,
            json={
                "matches": [
                    {"threat": {"url": url}, "threatType": "SOCIAL_ENGINEERING"}
                ]
            }
            if case == "match"
            else {},
        )

    result = await SafeBrowsingProvider("test", httpx.MockTransport(handler)).check(
        [url]
    )
    assert result.checked == (case in {"match", "empty"})
    assert bool(result.matches) == (case == "match")
    assert not (await SafeBrowsingProvider("").check([url])).checked


async def test_blocklist(app):
    async with async_sessionmaker(app.state.engine)() as session:
        session.add(
            BlockedDomain(domain="example.org", category="phishing", source="test")
        )
        await session.commit()
        result = await LocalBlocklist(session).check(
            ["https://sub.example.org/a", "https://notexample.org"]
        )
        assert result.checked and len(result.matches) == 1
