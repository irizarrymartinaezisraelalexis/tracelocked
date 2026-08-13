from dataclasses import dataclass
from enum import Enum
from typing import Any

from app.connectors.direct_actions import (
    DirectSearchAction,
    build_direct_action_plans,
)


class ExecutionMode(str, Enum):
    EMBEDDED_WEBVIEW = "embedded_webview"
    EXTERNAL_BROWSER = "external_browser"
    AUTOMATED_HTTP = "automated_http"
    UNSUPPORTED = "unsupported"


class ExecutionStatus(str, Enum):
    READY = "ready"
    ACTION_REQUIRED = "action_required"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass(frozen=True)
class ExecutionTask:
    source_key: str
    source_name: str
    query_kind: str
    query_value: str
    source_url: str
    removal_url: str | None
    mode: ExecutionMode
    status: ExecutionStatus
    requires_human_verification: bool
    browser_instructions: str


EXTERNAL_BROWSER_SOURCES = {
    "fastpeoplesearch",
}


EMBEDDED_WEBVIEW_SOURCES = {
    "truepeoplesearch",
    "whitepages",
    "spokeo",
    "peoplefinders",
    "beenverified",
    "intelius",
    "truthfinder",
    "instant_checkmate",
    "usphonebook",
    "truecaller",
    "radaris",
    "nuwber",
    "thatsthem",
    "clustrmaps",
    "familytreenow",
    "peekyou",
    "mylife",
    "zillow",
    "redfin",
    "linkedin",
    "facebook",
    "instagram",
    "google_maps",
}


def _execution_mode_for_action(
    action: DirectSearchAction,
) -> ExecutionMode:
    if action.source_key in EXTERNAL_BROWSER_SOURCES:
        return ExecutionMode.EXTERNAL_BROWSER

    if action.source_key in EMBEDDED_WEBVIEW_SOURCES:
        return ExecutionMode.EMBEDDED_WEBVIEW

    if action.requires_human_verification:
        return ExecutionMode.EXTERNAL_BROWSER

    return ExecutionMode.AUTOMATED_HTTP


def _browser_instructions(
    action: DirectSearchAction,
) -> str:
    kind = action.query_kind

    if kind == "phone":
        return (
            "Use the source phone lookup. "
            f"Search for: {action.query_value}"
        )

    if kind == "email":
        return (
            "Use email lookup if the source provides it. "
            f"Search for: {action.query_value}"
        )

    if kind in {
        "address",
        "previous_address",
    }:
        return (
            "Use the source address lookup. "
            f"Search for: {action.query_value}"
        )

    if kind == "name_address":
        return (
            "Search by name and use the address "
            "to identify the correct record. "
            f"Search information: {action.query_value}"
        )

    if kind in {
        "name_city",
        "name_location",
    }:
        return (
            "Use the source people/name search. "
            f"Search for: {action.query_value}"
        )

    return (
        "Use the source people/name search. "
        f"Search for: {action.query_value}"
    )


def build_execution_tasks(
    profile: dict[str, Any],
) -> list[ExecutionTask]:
    plans = build_direct_action_plans(
        profile
    )

    tasks: list[ExecutionTask] = []

    for plan in plans:
        for action in plan.actions:
            mode = _execution_mode_for_action(
                action
            )

            tasks.append(
                ExecutionTask(
                    source_key=action.source_key,
                    source_name=action.source_name,
                    query_kind=action.query_kind,
                    query_value=action.query_value,
                    source_url=action.source_url,
                    removal_url=action.removal_url,
                    mode=mode,
                    status=ExecutionStatus.READY,
                    requires_human_verification=(
                        action.requires_human_verification
                    ),
                    browser_instructions=(
                        _browser_instructions(
                            action
                        )
                    ),
                )
            )

    return tasks


def serialize_execution_task(
    task: ExecutionTask,
) -> dict:
    return {
        "source_key": task.source_key,
        "source_name": task.source_name,
        "query_kind": task.query_kind,
        "query_value": task.query_value,
        "source_url": task.source_url,
        "removal_url": task.removal_url,
        "mode": task.mode.value,
        "status": task.status.value,
        "requires_human_verification": (
            task.requires_human_verification
        ),
        "browser_instructions": (
            task.browser_instructions
        ),
    }