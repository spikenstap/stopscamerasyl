import pytest

from app.errors import AppError
from app.urls import extract_urls, normalize_domain, normalize_url


def test_urls():
    assert (
        normalize_url("HTTPS://user:pass@EXAMPLE.COM/a?q=1#x")
        == "https://example.com/a?q=1"
    )
    assert normalize_domain("пример.рф") == "xn--e1afmkfd.xn--p1ai"
    assert (
        len(
            extract_urls(
                " ".join(f"https://example.org/{i}" for i in range(20)), "text"
            )
        )
        == 10
    )
    assert extract_urls("https://example.org/a", "qr") == ["https://example.org/a"]


@pytest.mark.parametrize(
    "url",
    ["file:///etc/passwd", "javascript:alert(1)", "http://", "https://example.org:bad"],
)
def test_invalid_urls(url):
    with pytest.raises(AppError):
        normalize_url(url)
