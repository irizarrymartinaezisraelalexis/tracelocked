from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class SearchQuery:
    kind: str
    value: str
    label: str


def _clean(value: Any) -> str:
    if value is None:
        return ""

    return str(value).strip()


def build_search_queries(
    profile: dict[str, Any],
) -> list[SearchQuery]:
    queries: list[SearchQuery] = []

    first_name = _clean(
        profile.get("first_name")
    )

    last_name = _clean(
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

    email_addresses = [
        _clean(value)
        for value in profile.get(
            "email_addresses",
            [],
        )
        if _clean(value)
    ]

    phone_numbers = [
        _clean(value)
        for value in profile.get(
            "phone_numbers",
            [],
        )
        if _clean(value)
    ]

    current_address = (
        profile.get("current_address")
        or {}
    )

    street = _clean(
        current_address.get("street")
    )

    city = _clean(
        current_address.get("city")
    )

    state = _clean(
        current_address.get("state")
    )

    postal_code = _clean(
        current_address.get("postal_code")
    )

    if full_name:
        queries.append(
            SearchQuery(
                kind="name",
                value=full_name,
                label="Full name",
            )
        )

    if full_name and city:
        queries.append(
            SearchQuery(
                kind="name_city",
                value=f"{full_name} {city}",
                label="Name and city",
            )
        )

    if (
        full_name
        and city
        and state
    ):
        queries.append(
            SearchQuery(
                kind="name_location",
                value=(
                    f"{full_name} "
                    f"{city} {state}"
                ),
                label="Name and location",
            )
        )

    for email in email_addresses:
        queries.append(
            SearchQuery(
                kind="email",
                value=email,
                label="Email address",
            )
        )

    for phone in phone_numbers:
        queries.append(
            SearchQuery(
                kind="phone",
                value=phone,
                label="Phone number",
            )
        )

    address_parts = [
        part
        for part in [
            street,
            city,
            state,
            postal_code,
        ]
        if part
    ]

    if address_parts:
        full_address = " ".join(
            address_parts
        )

        queries.append(
            SearchQuery(
                kind="address",
                value=full_address,
                label="Current address",
            )
        )

    if full_name and street:
        queries.append(
            SearchQuery(
                kind="name_address",
                value=(
                    f"{full_name} "
                    f"{street}"
                ),
                label="Name and street",
            )
        )

    previous_addresses = (
        profile.get(
            "previous_addresses",
            [],
        )
        or []
    )

    for index, address in enumerate(
        previous_addresses,
        start=1,
    ):
        if not isinstance(
            address,
            dict,
        ):
            continue

        previous_parts = [
            _clean(
                address.get("street")
            ),
            _clean(
                address.get("city")
            ),
            _clean(
                address.get("state")
            ),
            _clean(
                address.get(
                    "postal_code"
                )
            ),
        ]

        previous_parts = [
            part
            for part in previous_parts
            if part
        ]

        if not previous_parts:
            continue

        queries.append(
            SearchQuery(
                kind="previous_address",
                value=" ".join(
                    previous_parts
                ),
                label=(
                    f"Previous address "
                    f"{index}"
                ),
            )
        )

    unique_queries: list[
        SearchQuery
    ] = []

    seen: set[
        tuple[str, str]
    ] = set()

    for query in queries:
        key = (
            query.kind,
            query.value.lower(),
        )

        if key in seen:
            continue

        seen.add(key)
        unique_queries.append(
            query
        )

    return unique_queries