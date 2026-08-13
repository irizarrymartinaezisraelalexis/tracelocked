from dataclasses import dataclass
from typing import Any

from app.connectors.executor import (
    ExecutionTask,
    build_execution_tasks,
)


@dataclass(frozen=True)
class TaskQueueSummary:
    total: int
    browser_tasks: int
    automated_tasks: int
    sources: int


SOURCE_PRIORITY = {
    "fastpeoplesearch": 0,
    "truepeoplesearch": 1,
    "whitepages": 2,
    "spokeo": 3,
    "peoplefinders": 4,
    "beenverified": 5,
    "intelius": 6,
    "truthfinder": 7,
    "instant_checkmate": 8,
    "usphonebook": 9,
    "truecaller": 10,
    "radaris": 11,
    "nuwber": 12,
    "thatsthem": 13,
    "clustrmaps": 14,
    "familytreenow": 15,
    "peekyou": 16,
    "mylife": 17,
    "zillow": 18,
    "redfin": 19,
    "linkedin": 20,
    "facebook": 21,
    "instagram": 22,
    "google_maps": 23,
}


QUERY_PRIORITY = {
    "phone": 0,
    "email": 1,
    "name_location": 2,
    "name_city": 3,
    "name": 4,
    "address": 5,
    "name_address": 6,
    "previous_address": 7,
}


def build_task_queue(
    profile: dict[str, Any],
) -> list[ExecutionTask]:
    tasks = build_execution_tasks(
        profile
    )

    return sorted(
        tasks,
        key=lambda task: (
            SOURCE_PRIORITY.get(
                task.source_key,
                999,
            ),
            _query_priority(
                task.query_kind
            ),
            task.query_value.lower(),
        ),
    )


def _query_priority(
    query_kind: str,
) -> int:
    return QUERY_PRIORITY.get(
        query_kind,
        99,
    )


def summarize_task_queue(
    tasks: list[ExecutionTask],
) -> TaskQueueSummary:
    source_keys = {
        task.source_key
        for task in tasks
    }

    browser_modes = {
        "external_browser",
        "embedded_webview",
    }

    browser_tasks = sum(
        1
        for task in tasks
        if task.mode.value
        in browser_modes
    )

    automated_tasks = sum(
        1
        for task in tasks
        if task.mode.value
        == "automated_http"
    )

    return TaskQueueSummary(
        total=len(tasks),
        browser_tasks=browser_tasks,
        automated_tasks=automated_tasks,
        sources=len(source_keys),
    )