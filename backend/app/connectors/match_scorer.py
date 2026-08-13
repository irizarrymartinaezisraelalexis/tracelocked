from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class MatchScore:
    score: float
    matched_fields: tuple[str, ...]
    confidence: str


def _normalize(value: Any) -> str:
    if value is None:
        return ""

    return " ".join(
        str(value)
        .strip()
        .lower()
        .split()
    )


def _digits_only(value: Any) -> str:
    if value is None:
        return ""

    return "".join(
        character
        for character in str(value)
        if character.isdigit()
    )


def score_match(
    profile: dict[str, Any],
    candidate: dict[str, Any],
) -> MatchScore:
    score = 0.0
    matched_fields: list[str] = []

    first_name = _normalize(
        profile.get("first_name")
    )
    last_name = _normalize(
        profile.get("last_name")
    )

    full_name = " ".join(
        part
        for part in [
            first_name,
            last_name,
        ]
        if part
    )

    candidate_name = _normalize(
        candidate.get("name")
        or candidate.get("matched_name")
    )

    if (
        full_name
        and candidate_name
        and full_name == candidate_name
    ):
        score += 0.35
        matched_fields.append(
            "name"
        )

    profile_emails = {
        _normalize(email)
        for email in profile.get(
            "email_addresses",
            [],
        )
        if _normalize(email)
    }

    candidate_email = _normalize(
        candidate.get("email")
        or candidate.get("matched_email")
    )

    if (
        candidate_email
        and candidate_email in profile_emails
    ):
        score += 0.30
        matched_fields.append(
            "email"
        )

    profile_phones = {
        _digits_only(phone)
        for phone in profile.get(
            "phone_numbers",
            [],
        )
        if _digits_only(phone)
    }

    candidate_phone = _digits_only(
        candidate.get("phone")
        or candidate.get("matched_phone")
    )

    if (
        candidate_phone
        and candidate_phone in profile_phones
    ):
        score += 0.30
        matched_fields.append(
            "phone"
        )

    current_address = (
        profile.get("current_address")
        or {}
    )

    profile_address = _normalize(
        " ".join(
            part
            for part in [
                str(
                    current_address.get(
                        "street",
                        "",
                    )
                ),
                str(
                    current_address.get(
                        "city",
                        "",
                    )
                ),
                str(
                    current_address.get(
                        "state",
                        "",
                    )
                ),
                str(
                    current_address.get(
                        "postal_code",
                        "",
                    )
                ),
            ]
            if str(part).strip()
        )
    )

    candidate_address = _normalize(
        candidate.get("address")
        or candidate.get(
            "matched_address"
        )
    )

    if (
        profile_address
        and candidate_address
        and profile_address
        == candidate_address
    ):
        score += 0.25
        matched_fields.append(
            "address"
        )

    profile_city = _normalize(
        current_address.get("city")
    )

    candidate_city = _normalize(
        candidate.get("city")
    )

    if (
        profile_city
        and candidate_city
        and profile_city == candidate_city
        and "address" not in matched_fields
    ):
        score += 0.10
        matched_fields.append(
            "city"
        )

    profile_state = _normalize(
        current_address.get("state")
    )

    candidate_state = _normalize(
        candidate.get("state")
    )

    if (
        profile_state
        and candidate_state
        and profile_state == candidate_state
        and "address" not in matched_fields
    ):
        score += 0.05
        matched_fields.append(
            "state"
        )

    score = min(
        score,
        1.0,
    )

    if score >= 0.80:
        confidence = "high"
    elif score >= 0.50:
        confidence = "medium"
    elif score > 0:
        confidence = "low"
    else:
        confidence = "none"

    return MatchScore(
        score=round(
            score,
            2,
        ),
        matched_fields=tuple(
            matched_fields
        ),
        confidence=confidence,
    )