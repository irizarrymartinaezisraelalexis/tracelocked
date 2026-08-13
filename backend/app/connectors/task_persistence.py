from collections import Counter
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.connectors.executor import ExecutionTask
from app.models.db_scan_task import DBScanTask


def initialize_scan_tasks(
    db: Session,
    profile_id: UUID,
    tasks: list[ExecutionTask],
) -> list[DBScanTask]:
    existing_tasks = get_scan_tasks(
        db=db,
        profile_id=profile_id,
    )

    if existing_tasks:
        return existing_tasks

    return _create_scan_tasks(
        db=db,
        profile_id=profile_id,
        tasks=tasks,
    )


def reset_scan_tasks(
    db: Session,
    profile_id: UUID,
    tasks: list[ExecutionTask],
) -> list[DBScanTask]:
    db.execute(
        delete(DBScanTask)
        .where(
            DBScanTask.profile_id
            == profile_id
        )
    )

    db.commit()

    return _create_scan_tasks(
        db=db,
        profile_id=profile_id,
        tasks=tasks,
    )


def _create_scan_tasks(
    db: Session,
    profile_id: UUID,
    tasks: list[ExecutionTask],
) -> list[DBScanTask]:
    saved_tasks: list[DBScanTask] = []

    for position, task in enumerate(
        tasks,
        start=1,
    ):
        record = DBScanTask(
            profile_id=profile_id,
            position=position,
            source_key=task.source_key,
            source_name=task.source_name,
            query_kind=task.query_kind,
            query_value=task.query_value,
            source_url=task.source_url,
            removal_url=task.removal_url,
            mode=task.mode.value,
            status="pending",
            requires_human_verification=(
                task.requires_human_verification
            ),
            result_url=None,
            confidence_score=None,
            started_at=None,
            completed_at=None,
        )

        db.add(record)
        saved_tasks.append(record)

    db.commit()

    for task in saved_tasks:
        db.refresh(task)

    return saved_tasks


def get_scan_tasks(
    db: Session,
    profile_id: UUID,
) -> list[DBScanTask]:
    return list(
        db.scalars(
            select(DBScanTask)
            .where(
                DBScanTask.profile_id
                == profile_id
            )
            .order_by(
                DBScanTask.position.asc()
            )
        ).all()
    )


def summarize_scan_tasks(
    tasks: list[DBScanTask],
) -> dict:
    status_counts = Counter(
        task.status
        for task in tasks
    )

    source_keys = {
        task.source_key
        for task in tasks
    }

    finished_tasks = sum(
        status_counts.get(
            status_name,
            0,
        )
        for status_name in (
            "no_match",
            "completed",
            "failed",
        )
    )

    return {
        "total": len(tasks),
        "sources": len(source_keys),
        "pending": status_counts.get(
            "pending",
            0,
        ),
        "opened": status_counts.get(
            "opened",
            0,
        ),
        "no_match": status_counts.get(
            "no_match",
            0,
        ),
        "possible_match": status_counts.get(
            "possible_match",
            0,
        ),
        "removal_ready": status_counts.get(
            "removal_ready",
            0,
        ),
        "removal_requested": status_counts.get(
            "removal_requested",
            0,
        ),
        "completed": status_counts.get(
            "completed",
            0,
        ),
        "failed": status_counts.get(
            "failed",
            0,
        ),
        "finished_tasks": finished_tasks,
    }


def serialize_scan_task(
    task: DBScanTask,
) -> dict:
    return {
        "id": str(task.id),
        "profile_id": str(
            task.profile_id
        ),
        "position": task.position,
        "source_key": task.source_key,
        "source_name": task.source_name,
        "query_kind": task.query_kind,
        "query_value": task.query_value,
        "source_url": task.source_url,
        "removal_url": task.removal_url,
        "mode": task.mode,
        "status": task.status,
        "requires_human_verification": (
            task.requires_human_verification
        ),
        "result_url": task.result_url,
        "confidence_score": (
            task.confidence_score
        ),
        "created_at": (
            task.created_at.isoformat()
            if task.created_at is not None
            else None
        ),
        "started_at": (
            task.started_at.isoformat()
            if task.started_at is not None
            else None
        ),
        "completed_at": (
            task.completed_at.isoformat()
            if task.completed_at is not None
            else None
        ),
    }