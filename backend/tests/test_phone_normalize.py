import phonenumbers
import pytest

from app.errors import AppError
from app.phone import normalize


@pytest.mark.parametrize("style", ["national", "international", "digits"])
def test_normalize(style):
    number = phonenumbers.example_number("KZ")
    expected = phonenumbers.format_number(number, phonenumbers.PhoneNumberFormat.E164)
    value = {
        "national": phonenumbers.format_number(
            number, phonenumbers.PhoneNumberFormat.NATIONAL
        ),
        "international": phonenumbers.format_number(
            number, phonenumbers.PhoneNumberFormat.INTERNATIONAL
        ),
        "digits": str(number.national_number),
    }[style]
    assert normalize(value) == expected


@pytest.mark.parametrize(
    "value", ["abc", "12", "000000000000000000", "101", "102", "103", "112"]
)
def test_invalid(value):
    with pytest.raises(AppError):
        normalize(value)
    if value in {"101", "102", "103", "112"}:
        assert normalize(value, allow_short=True) is None
