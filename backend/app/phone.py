import re

import phonenumbers

from app.errors import AppError

SHORT_CODES = {"101", "102", "103", "112"}


def normalize(number, allow_short=False):
    digits = re.sub(r"\D", "", number)
    if digits in SHORT_CODES and allow_short:
        return None
    try:
        if len(digits) < 7:
            raise ValueError()
        parsed = phonenumbers.parse(number, "KZ")
        if not phonenumbers.is_valid_number(parsed):
            raise ValueError()
        return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)
    except (ValueError, phonenumbers.NumberParseException):
        raise AppError("validation_error", 422, "Invalid phone number") from None
