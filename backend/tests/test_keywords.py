import base64
import copy
import json
from pathlib import Path

import pytest
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.serialization import (
    Encoding,
    NoEncryption,
    PrivateFormat,
)
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.models import AdminAudit, KeywordDictionaryRecord


@pytest.fixture
def dictionary():
    return json.loads(
        (
            Path(__file__).resolve().parents[2] / "assets/call_keywords/ru.json"
        ).read_text(encoding="utf-8")
    )


async def setup(client, app):
    key = Ed25519PrivateKey.generate()
    app.state.settings.keyword_signing_private_key = base64.b64encode(
        key.private_bytes(Encoding.Raw, PrivateFormat.Raw, NoEncryption())
    ).decode()
    app.state.settings.admin_api_key = "admin-test"
    identity = (
        await client.post(
            "/v1/auth/register", json={"platform": "android", "appVersion": "2.2"}
        )
    ).json()
    token = (await client.post("/v1/auth/token", json=identity)).json()["accessToken"]
    return key, {"Authorization": "Bearer " + token}, {"X-Admin-Key": "admin-test"}


async def test_signed_dictionary_etag_version_and_audit(client, app, dictionary):
    key, auth, admin = await setup(client, app)
    assert (await client.get("/v1/keywords?lang=ru")).status_code == 401
    assert (await client.get("/v1/keywords?lang=ru", headers=auth)).status_code == 404
    assert (
        await client.post("/v1/admin/keywords", json=dictionary, headers=admin)
    ).status_code == 201
    response = await client.get("/v1/keywords?lang=ru&version=0", headers=auth)
    assert response.status_code == 200
    envelope = response.json()
    raw = base64.b64decode(envelope["payload"])
    key.public_key().verify(base64.b64decode(envelope["signature"]), raw)
    assert json.loads(raw) == dictionary
    etag = response.headers["etag"]
    cached = await client.get(
        "/v1/keywords?lang=ru&version=1", headers={**auth, "If-None-Match": etag}
    )
    assert cached.status_code == 304 and cached.content == b""
    assert cached.headers["etag"] == etag
    assert (
        await client.get("/v1/keywords?lang=ru&version=1", headers=auth)
    ).status_code == 200
    for version in [1, 0]:
        data = {**dictionary, "version": version}
        assert (
            await client.post("/v1/admin/keywords", json=data, headers=admin)
        ).status_code == (409 if version else 422)
    new = {**dictionary, "version": 2}
    assert (
        await client.post("/v1/admin/keywords", json=new, headers=admin)
    ).status_code == 201
    upgraded = await client.get(
        "/v1/keywords?lang=ru&version=1", headers={**auth, "If-None-Match": etag}
    )
    assert upgraded.status_code == 200 and upgraded.headers["etag"] != etag
    async with async_sessionmaker(app.state.engine)() as session:
        assert (
            await session.scalar(
                select(func.count()).select_from(KeywordDictionaryRecord)
            )
            == 1
        )
        assert await session.scalar(select(func.count()).select_from(AdminAudit)) == 2


async def test_dictionary_admin_validation_and_no_signing_key(client, app, dictionary):
    _, auth, admin = await setup(client, app)
    assert (await client.post("/v1/admin/keywords", json=dictionary)).status_code == 401
    for change in [
        {"lang": "en"},
        {"cautionThreshold": 10, "dangerThreshold": 5},
        {"version": True},
        {"audio": "forbidden"},
        {"categories": []},
    ]:
        assert (
            await client.post(
                "/v1/admin/keywords", json={**dictionary, **change}, headers=admin
            )
        ).status_code == 422
    data = copy.deepcopy(dictionary)
    data["categories"][0]["phrases"][0]["weight"] = 6
    assert (
        await client.post("/v1/admin/keywords", json=data, headers=admin)
    ).status_code == 422
    app.state.settings.keyword_signing_private_key = ""
    assert (
        await client.post("/v1/admin/keywords", json=dictionary, headers=admin)
    ).status_code == 503
    assert (await client.get("/v1/keywords?lang=bad", headers=auth)).status_code == 422
    assert (
        await client.get("/v1/keywords?lang=ru&version=-1", headers=auth)
    ).status_code == 422


async def test_empty_kazakh_dictionary_is_explicit(client, app, dictionary):
    _, auth, admin = await setup(client, app)
    dictionary["lang"] = "kk"
    for category in dictionary["categories"]:
        category["phrases"] = []
    assert (
        await client.post("/v1/admin/keywords", json=dictionary, headers=admin)
    ).status_code == 201
    response = await client.get("/v1/keywords?lang=kk", headers=auth)
    assert json.loads(base64.b64decode(response.json()["payload"]))["lang"] == "kk"
