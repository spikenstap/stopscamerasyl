# StopScam backend — phase 1

Python 3.12, FastAPI, SQLAlchemy async, PostgreSQL and Redis. Client files are unchanged.

## Local tests (no Docker, no network or keys during tests)

From this directory, using Python 3.12:

```powershell
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements-test.lock
.venv\Scripts\ruff check .
.venv\Scripts\ruff format --check .
.venv\Scripts\python -m pytest --cov --cov-report=term-missing
```

On Linux use `.venv/bin/`. Tests use aiosqlite and fakeredis with Lua.
Test settings ignore the local `.env` and inherited application environment
variables, so developer credentials cannot change test behavior.
Coverage explicitly tracks greenlet and thread concurrency because SQLAlchemy async
switches greenlets; without this setting covered async lines can be missed.
All tests use synthetic library examples or explicitly labelled fake providers.
Production dependencies are pinned in `requirements.lock`; test dependencies are
separate in `requirements-test.lock`.

## Local API and deployment

Copy `.env.example` to `.env`; generate independent random JWT, phone pepper and
admin secrets locally (for example with Python's `secrets.token_urlsafe(48)`).
Set `POSTGRES_PASSWORD` and update the password in `DATABASE_URL` to match.
Set `APP_ENV=prod` for deployment. URL-encode special characters in DB credentials.
Configure the optional LLM and Safe Browsing keys only when actually using them.

Production commands, after configuring `.env`:

```sh
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up -d
curl --fail http://127.0.0.1:8000/healthz
curl --fail http://127.0.0.1:8000/readyz
docker compose -f docker-compose.yml logs --tail=50 api
```

The API command applies Alembic before starting. Run migrations once as a deployment
job when scaling to multiple API replicas. Put an HTTPS reverse proxy in front of
the loopback binding. Set TRUSTED_PROXY_COUNT only for a controlled proxy chain;
the proxy must replace untrusted forwarding headers. Uvicorn's proxy parsing is
disabled so the application alone applies the configured policy. Uvicorn access
logging is disabled; the app emits JSON records with time, level, requestId, route
template, status, duration and deviceId. No request/response bodies or full URLs
are logged. Configure the process log handler to emit the message unchanged.

Without containers, point DATABASE_URL and REDIS_URL at local services and run:

```sh
alembic upgrade head
uvicorn app.main:create_app --factory --host 127.0.0.1 --port 8000 --no-access-log --no-proxy-headers
```

SQLite migration check (PowerShell):

```powershell
$env:DATABASE_URL = "sqlite+aiosqlite:///migration-check.db"
alembic upgrade head
alembic check
alembic downgrade base
Remove-Item Env:DATABASE_URL
```

Downgrade deletes backend tables: only use it on a disposable verification database.
PostgreSQL verification uses the same Alembic commands with a PostgreSQL URL.

## Configuration

All variables and defaults are listed in `.env.example`. Secrets are blank there.

| Variable | Default / behavior |
|---|---|
| APP_ENV | dev; prod disables docs, redoc and OpenAPI routes |
| DATABASE_URL | PostgreSQL asyncpg; set credentials to match the DB |
| REDIS_URL | redis://redis:6379/0 |
| JWT_SECRET, PHONE_HASH_PEPPER | Required in prod, at least 32 characters each |
| JWT_TTL_MINUTES | 15 |
| ADMIN_API_KEY | Blank disables every registered admin route with 404 |
| LLM_API_KEY | Blank makes analyze return 503 ai_not_configured |
| LLM_API_URL | HTTPS Chat Completions endpoint; no URL credentials |
| LLM_MODEL, LLM_TIMEOUT_SECONDS | gpt-4o-mini, 45 |
| SAFE_BROWSING_API_KEY | Optional; blank uses only local blocklist |
| TRUSTED_PROXY_COUNT | 0; otherwise N-th forwarded IP from right |
| RATE_ANALYZE_PER_MIN, QUOTA_ANALYZE_PER_DAY | 10, 50 per device |
| RATE_PHONE_CHECK_PER_MIN | 30 per device |
| QUOTA_PHONE_REPORT_PER_DAY | 10 per device |
| RATE_REGISTER_PER_IP_PER_HOUR | 10 |
| RATE_TOKEN_PER_IP_PER_MIN | 10 |
| REPUTATION_FLAG_THRESHOLD, REPUTATION_WINDOW_DAYS | 3.0, 90 |
| ANALYSIS_CACHE_TTL_SECONDS | 3600 |
| MAX_CONTENT_CHARS | 5000 |
| POSTGRES_PASSWORD | Compose-only DB password; set locally |

Dev/test instances with blank JWT or pepper generate ephemeral random values at
startup. Set persistent values even in dev if tokens or reputation must survive
restarts. Rotate JWT_SECRET to revoke all tokens. Rotating PHONE_HASH_PEPPER
**resets reputation**: existing hashes cannot be linked to numbers under the new
pepper; delete obsolete reports/verdicts as part of a planned reset. Rotate
ADMIN_API_KEY and provider keys independently.

## API

See `openapi.json` for the exported request and response schemas.

| Method | Path | Result |
|---|---|---|
| POST | /v1/auth/register | 201 deviceId, deviceSecret (shown once) |
| POST | /v1/auth/token | 200 accessToken, tokenType, expiresIn |
| POST | /v1/analyze | 200 validated analysis, threatIntel, requestId |
| POST | /v1/phone/check | 200 status, confidence, confirmed, source, reason, expiresAt |
| POST | /v1/phone/report | 202 accepted; duplicates idempotent |
| DELETE | /v1/phone/report | 204 |
| GET | /healthz | 200 |
| GET | /readyz | 200 when DB and Redis respond, otherwise 503 |
| POST / DELETE | /v1/admin/phone-verdicts | 201 upsert / 204 delete |
| POST / DELETE | /v1/admin/blocked-domains | 201 upsert / 204 delete |
| GET | /v1/admin/stats | counts: devices, reports, verdicts, domains |

Public data endpoints require a Bearer device token. Admin endpoints require
X-Admin-Key and are limited to 30 requests/minute/IP. Every admin write creates an
audit row containing a hash, never a full number.

To add a verdict, POST a JSON object with phoneNumber, status (flagged or clear),
source, optional sourceUrl, optional expiresAt (Unix milliseconds) to
/v1/admin/phone-verdicts with X-Admin-Key. Omitted/null expiry means no verdict
expiry; client cache validity is still capped at 24 hours.
To add a domain, POST domain, category (phishing/malware/scam), source to
/v1/admin/blocked-domains. Domains are normalized to lowercase IDNA and match
subdomains. DELETE takes just phoneNumber or domain. No public endpoint can create
a confirmed verdict; public checks can return confirmed verdicts that an admin
has previously entered.

Errors use `{"error":{"code":"...","message":"..."}}` with English messages.
429 responses include Retry-After. Every response has X-Request-Id, no-store and
nosniff. Bodies above 32 KiB return 413 validation_error. Unmatched routes use
404 not_found. Redis failures close auth and analysis with 503 internal.

Model output is validated strictly, with one retry on invalid output.
All reasons/recommendations are trimmed nonempty strings of at most 3000 UTF-16
code units, matching Dart String.length, and each list has at most 20 elements.
Recommendations are nonempty; reasons are required above score 20.
Summary is trimmed and at most 5000 UTF-16 units; category is trimmed and checked
against the client's enum. riskLevel is always recomputed. The prompt and JSON
schema are copied from the client at commit 546b47a.
Cache hits still consume the minute limit but not the daily AI quota. A single
analysis operation consumes one daily unit even if invalid model output needs
one retry. Provider failures after invocation consume that unit.

## Reputation and data privacy

No phone number is stored in the database. Normalized E.164 numbers become
HMAC-SHA256 with PHONE_HASH_PEPPER. The DB stores device secret hashes, device
metadata, hashed reports/verdicts, blocklist domains and hashed audit targets.
Duplicate reports do not consume an additional daily report unit. Reports from
devices younger than 24 hours weigh 0.25; mature-device reports weigh 1.
Blocked-device and out-of-window reports do not count.
Community results always have confirmed=false and confidence at most 0.9.
Only admin verdicts can return confirmed=true. Unknown numbers remain unknown.

Before calling the LLM, card data passing Luhn, IIN, email and contextual codes
are masked; the same post-filter is applied to output. Local signal strings are
also filtered. URLs remain unchanged as required by the contract. The LLM therefore
receives URLs and other unmasked content; enabling Safe Browsing sends extracted
URLs to Google. No audio, transcript uploads or personal number notes are accepted.
The result cache stores output only, never the original request text; its key is a
hash. Output can contain URLs from threat matches. Treat Redis as private data
infrastructure with controlled network access and the configured TTL.

Run `python -m app.cli purge` daily via your deployment scheduler to remove reports
older than twice the reputation window, devices inactive for 365 days (cascading
their reports) and expired verdicts. Audit retention is not specified by phase 1
and is not automatically purged.

## Safe Browsing terms and replacement

Reviewed 2026-10-23: [Google Safe Browsing v4 documentation](https://developers.google.com/safe-browsing/v4)
limits the API to non-commercial use and directs commercial use to
[Web Risk](https://cloud.google.com/web-risk). Google also labels v4 deprecated.
The requested v4 adapter is implemented, but its live availability has not been
verified. Choose an appropriate supported/licensed provider before deployment.
ThreatProvider returns checked plus matches; replace the dependency factory
without changing analysis.py. A provider outage gives checked=false and never
turns an absence of matches into a safety guarantee. Local matches still raise risk.

## Docker verification and manual smoke commands

Verified on 2026-10-23 with Docker Desktop 4.96.3, Engine 29.9.2 and Compose 5.6.1:
all three images build, the production API and dev API become healthy, and
both `/healthz` and `/readyz` return 200. Registration and token issuance work;
the production API with no LLM key returns 503 `ai_not_configured`, with docs
disabled. The dev smoke sequence below passes against the HTTPS mock LLM.
Alembic upgrade, schema check and downgrade also pass on containerized
PostgreSQL 16.15; Redis 7.4.11 is used for the live limits and cache.
The production image runs without root and contains no `.env`, dev mock or
pytest dependency. Its installed dependencies pass `pip check`.
The verification project's containers and disposable volumes are removed
after testing. Real LLM and Safe Browsing calls remain unverified.

To repeat, use a fresh disposable Compose project and configure .env as above.

```sh
docker compose -p stopscam-smoke --profile dev build
docker compose -p stopscam-smoke --profile dev up -d api-dev
curl --fail http://127.0.0.1:8001/readyz
python dev/smoke.py --url http://127.0.0.1:8001
docker compose -p stopscam-smoke --profile dev down
```

dev/smoke.py performs register → token → check → reports from three separate
new devices → check → analyze. Three new reports total 0.75, so the expected
result remains unknown; unit tests separately cover three mature reports.
The mock LLM is explicitly a test fixture, served over HTTPS with a short-lived
local certificate trusted only by api-dev. It is excluded from the production
image. Refresh the mock container to renew its one-day certificate.
The regular api service retains its real configured LLM; the dev profile adds
a separate api-dev on port 8001. Do not deploy the dev profile or use its canned
response for risk decisions.

