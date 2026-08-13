from dataclasses import dataclass
from typing import Any

from app.connectors.base import ConnectorMatch
from app.connectors.match_scorer import (
    MatchScore,
    score_match,
)
from app.connectors.query_builder import (
    SearchQuery,
    build_search_queries,
)


@dataclass(frozen=True)
class DiscoveryResult:
    match: ConnectorMatch
    score: MatchScore


def build_profile_queries(
    profile: dict[str, Any],
) -> list[SearchQuery]:
    return build_search_queries(
        profile
    )


def score_connector_match(
    profile: dict[str, Any],
    match: ConnectorMatch,
) -> MatchScore:
    candidate = {
        "matched_name": match.matched_name,
        "matched_phone": match.matched_phone,
        "matched_email": match.matched_email,
        "matched_address": match.matched_address,
    }

    return score_match(
        profile,
        candidate,
    )


def evaluate_matches(
    profile: dict[str, Any],
    matches: list[ConnectorMatch],
) -> list[DiscoveryResult]:
    evaluated: list[DiscoveryResult] = []

    for match in matches:
        score = score_connector_match(
            profile,
            match,
        )

        evaluated.append(
            DiscoveryResult(
                match=match,
                score=score,
            )
        )

    return evaluated


def likely_matches(
    profile: dict[str, Any],
    matches: list[ConnectorMatch],
    minimum_score: float = 0.50,
) -> list[DiscoveryResult]:
    evaluated = evaluate_matches(
        profile,
        matches,
    )

    return [
        result
        for result in evaluated
        if result.score.score >= minimum_score
    ]