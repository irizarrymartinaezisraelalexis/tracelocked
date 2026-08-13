from dataclasses import dataclass
from typing import Any

from app.connectors.query_builder import (
    SearchQuery,
    build_search_queries,
)
from app.connectors.registry import (
    SourceDefinition,
    list_sources,
)


@dataclass(frozen=True)
class DirectSearchAction:
    source_key: str
    source_name: str
    source_url: str
    query_kind: str
    query_value: str
    query_label: str
    removal_url: str | None
    requires_human_verification: bool


@dataclass(frozen=True)
class SourceActionPlan:
    source_key: str
    source_name: str
    homepage_url: str | None
    search_url: str | None
    removal_url: str | None
    requires_human_verification: bool
    actions: tuple[DirectSearchAction, ...]


def _queries_for_source(
    source: SourceDefinition,
    queries: list[SearchQuery],
) -> list[SearchQuery]:
    if source.category.value == "phone_lookup":
        allowed_kinds = {
            "phone",
        }

    elif source.category.value == "property_records":
        allowed_kinds = {
            "address",
            "name_address",
        }

    elif source.category.value == "social":
        allowed_kinds = {
            "name",
            "name_city",
            "name_location",
            "email",
        }

    elif source.category.value == "business_directory":
        allowed_kinds = {
            "name",
            "name_city",
            "name_location",
            "address",
        }

    else:
        allowed_kinds = {
            "name",
            "name_city",
            "name_location",
            "email",
            "phone",
            "address",
            "name_address",
            "previous_address",
        }

    return [
        query
        for query in queries
        if query.kind in allowed_kinds
    ]


def build_source_action_plan(
    source: SourceDefinition,
    queries: list[SearchQuery],
) -> SourceActionPlan:
    source_queries = _queries_for_source(
        source,
        queries,
    )

    base_search_url = (
        source.search_url
        or source.homepage_url
    )

    actions: list[DirectSearchAction] = []

    if base_search_url:
        for query in source_queries:
            actions.append(
                DirectSearchAction(
                    source_key=source.key,
                    source_name=source.name,
                    source_url=base_search_url,
                    query_kind=query.kind,
                    query_value=query.value,
                    query_label=query.label,
                    removal_url=source.removal_url,
                    requires_human_verification=(
                        source.requires_human_verification
                    ),
                )
            )

    return SourceActionPlan(
        source_key=source.key,
        source_name=source.name,
        homepage_url=source.homepage_url,
        search_url=source.search_url,
        removal_url=source.removal_url,
        requires_human_verification=(
            source.requires_human_verification
        ),
        actions=tuple(actions),
    )


def build_direct_action_plans(
    profile: dict[str, Any],
) -> list[SourceActionPlan]:
    queries = build_search_queries(
        profile
    )

    return [
        build_source_action_plan(
            source,
            queries,
        )
        for source in list_sources()
    ]


def serialize_action_plan(
    plan: SourceActionPlan,
) -> dict:
    return {
        "source_key": plan.source_key,
        "source_name": plan.source_name,
        "homepage_url": plan.homepage_url,
        "search_url": plan.search_url,
        "removal_url": plan.removal_url,
        "requires_human_verification": (
            plan.requires_human_verification
        ),
        "actions_count": len(
            plan.actions
        ),
        "actions": [
            {
                "query_kind": action.query_kind,
                "query_value": action.query_value,
                "query_label": action.query_label,
                "source_url": action.source_url,
                "removal_url": action.removal_url,
                "requires_human_verification": (
                    action.requires_human_verification
                ),
            }
            for action in plan.actions
        ],
    }
