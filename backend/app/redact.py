import re

URL = re.compile(r"https?://[^\s<>]+", re.IGNORECASE)
CARD = re.compile(r"(?<!\d)(?:\d[ -]?){12,18}\d(?![ -]?\d)")
IIN = re.compile(r"(?<!\d)\d{12}(?!\d)")
EMAIL = re.compile(r"[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}")
CODE = re.compile(
    r"(?i)\b(?:код|code|пароль|password|cvv|cvc|otp|пин|pin|смс|sms)\b([\s\S]{0,20}?)(?<!\d)(\d{4,8})(?!\d)"
)


def luhn(value):
    digits = [int(c) for c in value if c.isdigit()]
    total = 0
    for index, digit in enumerate(reversed(digits)):
        if index % 2:
            digit *= 2
            if digit > 9:
                digit -= 9
        total += digit
    return total % 10 == 0


def redact_piece(text):
    text = CARD.sub(lambda m: "[CARD]" if luhn(m.group()) else m.group(), text)
    text = IIN.sub("[IIN]", text)
    text = EMAIL.sub("[EMAIL]", text)
    return CODE.sub(lambda m: m.group()[: m.start(2) - m.start()] + "[CODE]", text)


def redact(text):
    # URLs are intentionally preserved by the contract.
    output, offset = [], 0
    for match in URL.finditer(text):
        output.extend([redact_piece(text[offset : match.start()]), match.group()])
        offset = match.end()
    output.append(redact_piece(text[offset:]))
    return "".join(output)
