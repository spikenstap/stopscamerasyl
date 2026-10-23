import pytest

from app.redact import redact


@pytest.mark.parametrize(
    "raw, expected",
    [
        ("4111 1111 1111 1111", "[CARD]"),
        ("4111-1111-1111-1112", "4111-1111-1111-1112"),
        ("123456789012", "[IIN]"),
        ("test@example.org", "[EMAIL]"),
        ("код 1234", "код [CODE]"),
        ("код через 2 минуты 1234", "код через 2 минуты [CODE]"),
        ("в 1234 году", "в 1234 году"),
        ("otp: 12345678", "otp: [CODE]"),
        (
            "https://example.org/123456789012?code=1234",
            "https://example.org/123456789012?code=1234",
        ),
        ("code " + "x" * 21 + "1234", "code " + "x" * 21 + "1234"),
    ],
)
def test_redaction(raw, expected):
    assert redact(raw) == expected
