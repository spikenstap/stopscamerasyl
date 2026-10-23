import re
from urllib.parse import urlsplit, urlunsplit

import idna

from app.errors import AppError


def normalize_domain(value):
    try:
        domain = idna.encode(value.strip().lower().rstrip("."), uts46=True).decode()
        if (
            not domain
            or len(domain) > 253
            or any(not label for label in domain.split("."))
        ):
            raise ValueError()
        return domain
    except (idna.IDNAError, ValueError):
        raise AppError("validation_error", 422, "Invalid domain") from None


def normalize_url(value):
    try:
        parts = urlsplit(value.strip())
        if parts.scheme.lower() not in {"http", "https"} or not parts.hostname:
            raise ValueError()
        host = normalize_domain(parts.hostname)
        port = parts.port
        netloc = host + (f":{port}" if port else "")
        return urlunsplit((parts.scheme.lower(), netloc, parts.path, parts.query, ""))
    except (ValueError, AppError):
        raise AppError("validation_error", 422, "Invalid URL") from None


def extract_urls(content, kind):
    if kind in {"url", "qr"}:
        return [normalize_url(content)]
    found = []
    for match in re.finditer(r"https?://[^\s<>]+", content, re.IGNORECASE):
        try:
            normalized = normalize_url(match.group().rstrip(".,;!?)]}"))
        except AppError:
            continue
        if normalized not in found:
            found.append(normalized)
        if len(found) == 10:
            break
    return found
