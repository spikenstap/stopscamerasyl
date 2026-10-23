import base64
import hashlib
import json
from typing import Annotated, Literal

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from pydantic import Field, StringConstraints, model_validator

from app.schemas import StrictModel

CATEGORIES = {
    "bank_security",
    "otp",
    "remote_access",
    "authority",
    "urgency_secrecy",
    "money_transfer",
    "investment",
    "relative_emergency",
}
Identifier = Annotated[str, StringConstraints(pattern=r"^[a-z][a-z0-9_]{0,63}$")]
Variant = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=2, max_length=160)
]


class KeywordPhrase(StrictModel):
    id: Identifier
    variants: list[Variant] = Field(min_length=1, max_length=12)
    weight: int = Field(strict=True, ge=1, le=5)


class KeywordCategory(StrictModel):
    id: Identifier
    phrases: list[KeywordPhrase] = Field(max_length=100)


class KeywordDictionary(StrictModel):
    lang: Literal["ru", "kk"]
    version: int = Field(strict=True, ge=1, le=2147483647)
    cautionThreshold: int = Field(strict=True, ge=2, le=50)
    dangerThreshold: int = Field(strict=True, ge=3, le=100)
    categories: list[KeywordCategory] = Field(min_length=8, max_length=8)

    @model_validator(mode="after")
    def validate_dictionary(self):
        if {c.id for c in self.categories} != CATEGORIES:
            raise ValueError("Invalid categories")
        ids = [p.id for c in self.categories for p in c.phrases]
        if len(ids) != len(set(ids)) or self.cautionThreshold >= self.dangerThreshold:
            raise ValueError("Invalid dictionary")
        # '*' means a trailing word stem only, never an arbitrary regex.
        for c in self.categories:
            for p in c.phrases:
                for variant in p.variants:
                    for word in variant.split():
                        if "*" in word and (
                            not word.endswith("*")
                            or word.count("*") != 1
                            or len(word) < 4
                        ):
                            raise ValueError("Invalid stem")
        return self


def signed_dictionary(dictionary: KeywordDictionary, encoded_key: str):
    key = Ed25519PrivateKey.from_private_bytes(
        base64.b64decode(encoded_key, validate=True)
    )
    payload = json.dumps(
        dictionary.model_dump(),
        sort_keys=True,
        ensure_ascii=False,
        separators=(",", ":"),
    ).encode("utf-8")
    if len(payload) > 24000:
        raise ValueError("Dictionary too large")
    return {
        "payload": base64.b64encode(payload).decode("ascii"),
        "signature": base64.b64encode(key.sign(payload)).decode("ascii"),
    }, hashlib.sha256(payload).hexdigest()
