from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.connectors import connector_manager
from app.connectors.direct_actions import (
    build_direct_action_plans,
    serialize_action_plan,
)
from app.connectors.discovery import (
    build_profile_queries,
    evaluate_matches,
)
from app.connectors.executor import (
    build_execution_tasks,
    serialize_execution_task,
)
from app.connectors.match_scorer import score_match
from app.connectors.registry import (
    get_source,
    list_sources,
    serialize_source,
)
from app.connectors.task_persistence import (
    get_scan_tasks,
    initialize_scan_tasks,
    reset_scan_tasks,
    serialize_scan_task,
    summarize_scan_tasks,
)
from app.connectors.task_queue import (
    build_task_queue,
    summarize_task_queue,
)
from app.database.connection import get_db
from app.models.db_privacy_profile import DBPrivacyProfile
from app.models.db_scan_result import DBScanResult
from app.models.db_scan_task import DBScanTask
from app.models.discovered_listing import DiscoveredListingCreate
from app.models.scan_result import ScanResultStatusUpdate
from app.models.scan_task_update import ScanTaskStatusUpdate


router = APIRouter(
    prefix="/scan",
    tags=["Scan"],
)


def serialize_scan_result(
    result: DBScanResult,
) -> dict:
    return {
        "id": str(result.id),
        "source_name": result.source_name,
        "source_url": result.source_url,
        "matched_name": result.matched_name,
        "matched_phone": result.matched_phone,
        "matched_email": result.matched_email,
        "matched_address": result.matched_address,
        "confidence_score": result.confidence_score,
        "status": result.status,
        "created_at": (
            result.created_at.isoformat()
            if result.created_at is not None
            else None
        ),
        "removal_requested_at": (
            result.removal_requested_at.isoformat()
            if result.removal_requested_at is not None
            else None
        ),
        "removed_at": (
            result.removed_at.isoformat()
            if result.removed_at is not None
            else None
        ),
    }


def build_profile_data(
    profile: DBPrivacyProfile,
) -> dict:
    return {
        "first_name": profile.first_name,
        "last_name": profile.last_name,
        "email_addresses": (
            [profile.email]
            if profile.email
            else []
        ),
        "phone_numbers": (
            [profile.phone_number]
            if profile.phone_number
            else []
        ),
        "current_address": {
            "street": profile.street,
            "city": profile.city,
            "state": profile.state,
            "postal_code": profile.postal_code,
        },
        "previous_addresses": [],
        "date_of_birth": (
            profile.date_of_birth.isoformat()
            if profile.date_of_birth is not None
            else None
        ),
    }


def get_profile_or_404(
    profile_id: str,
    db: Session,
) -> tuple[UUID, DBPrivacyProfile]:
    try:
        parsed_profile_id = UUID(profile_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid privacy profile ID.",
        )

    database_profile = db.get(
        DBPrivacyProfile,
        parsed_profile_id,
    )

    if database_profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Privacy profile not found.",
        )

    return parsed_profile_id, database_profile


def get_result_or_404(
    result_id: str,
    db: Session,
) -> DBScanResult:
    try:
        parsed_result_id = UUID(result_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid scan result ID.",
        )

    result = db.get(
        DBScanResult,
        parsed_result_id,
    )

    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan result not found.",
        )

    return result


def get_task_or_404(
    task_id: str,
    db: Session,
) -> DBScanTask:
    try:
        parsed_task_id = UUID(task_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid scan task ID.",
        )

    task = db.get(
        DBScanTask,
        parsed_task_id,
    )

    if task is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan task not found.",
        )

    return task


def find_source_for_result(
    result: DBScanResult,
):
    normalized_name = result.source_name.strip().lower()

    for source in list_sources():
        if source.name.strip().lower() == normalized_name:
            return source

    return None


@router.get("/")
def get_scan_status():
    return {
        "status": "ready",
        "message": "TraceLocked scan service is ready.",
        "enabled_connectors": (
            connector_manager.enabled_connector_count()
        ),
        "registered_sources": len(
            list_sources()
        ),
    }


@router.get("/sources")
def get_scan_sources():
    sources = list_sources()

    return {
        "sources_count": len(sources),
        "sources": [
            serialize_source(source)
            for source in sources
        ],
    }


@router.get("/plan/{profile_id}")
def get_scan_plan(
    profile_id: str,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        database_profile,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    profile_data = build_profile_data(
        database_profile
    )

    queries = build_profile_queries(
        profile_data
    )

    plans = build_direct_action_plans(
        profile_data
    )

    total_actions = sum(
        len(plan.actions)
        for plan in plans
    )

    return {
        "profile_id": str(parsed_profile_id),
        "registered_sources": len(list_sources()),
        "queries_generated": len(queries),
        "total_actions": total_actions,
        "plans": [
            serialize_action_plan(plan)
            for plan in plans
        ],
    }


@router.get("/tasks/{profile_id}")
def get_execution_tasks(
    profile_id: str,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        database_profile,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    profile_data = build_profile_data(
        database_profile
    )

    tasks = build_execution_tasks(
        profile_data
    )

    return {
        "profile_id": str(parsed_profile_id),
        "tasks_count": len(tasks),
        "tasks": [
            serialize_execution_task(task)
            for task in tasks
        ],
    }


@router.get("/tasks/{profile_id}/first")
def get_first_execution_task(
    profile_id: str,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        database_profile,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    profile_data = build_profile_data(
        database_profile
    )

    tasks = build_execution_tasks(
        profile_data
    )

    if not tasks:
        return {
            "profile_id": str(parsed_profile_id),
            "task": None,
        }

    preferred_order = (
        "fastpeoplesearch",
        "truepeoplesearch",
    )

    selected_task = None

    for source_key in preferred_order:
        selected_task = next(
            (
                task
                for task in tasks
                if task.source_key == source_key
            ),
            None,
        )

        if selected_task is not None:
            break

    if selected_task is None:
        selected_task = tasks[0]

    return {
        "profile_id": str(parsed_profile_id),
        "task": serialize_execution_task(
            selected_task
        ),
    }


@router.get("/queue/{profile_id}")
def get_execution_queue(
    profile_id: str,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        database_profile,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    profile_data = build_profile_data(
        database_profile
    )

    tasks = build_task_queue(
        profile_data
    )

    summary = summarize_task_queue(
        tasks
    )

    return {
        "profile_id": str(parsed_profile_id),
        "summary": {
            "total": summary.total,
            "sources": summary.sources,
            "browser_tasks": summary.browser_tasks,
            "automated_tasks": summary.automated_tasks,
        },
        "tasks": [
            {
                "position": index,
                **serialize_execution_task(task),
            }
            for index, task in enumerate(
                tasks,
                start=1,
            )
        ],
    }


@router.post("/queue/{profile_id}/initialize")
def initialize_execution_queue(
    profile_id: str,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        database_profile,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    profile_data = build_profile_data(
        database_profile
    )

    generated_tasks = build_task_queue(
        profile_data
    )

    saved_tasks = initialize_scan_tasks(
        db=db,
        profile_id=parsed_profile_id,
        tasks=generated_tasks,
    )

    summary = summarize_scan_tasks(
        saved_tasks
    )

    return {
        "profile_id": str(parsed_profile_id),
        "message": (
            "Persistent scan queue initialized."
        ),
        "summary": summary,
        "tasks": [
            serialize_scan_task(task)
            for task in saved_tasks
        ],
    }


@router.post("/queue/{profile_id}/reset")
def reset_execution_queue(
    profile_id: str,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        database_profile,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    profile_data = build_profile_data(
        database_profile
    )

    generated_tasks = build_task_queue(
        profile_data
    )

    saved_tasks = reset_scan_tasks(
        db=db,
        profile_id=parsed_profile_id,
        tasks=generated_tasks,
    )

    summary = summarize_scan_tasks(
        saved_tasks
    )

    return {
        "profile_id": str(parsed_profile_id),
        "message": (
            "Persistent scan queue reset and rebuilt."
        ),
        "summary": summary,
        "tasks": [
            serialize_scan_task(task)
            for task in saved_tasks
        ],
    }


@router.get("/queue/{profile_id}/saved")
def get_saved_execution_queue(
    profile_id: str,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        _,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    tasks = get_scan_tasks(
        db=db,
        profile_id=parsed_profile_id,
    )

    summary = summarize_scan_tasks(
        tasks
    )

    return {
        "profile_id": str(parsed_profile_id),
        "summary": summary,
        "tasks": [
            serialize_scan_task(task)
            for task in tasks
        ],
    }


@router.patch("/queue/task/{task_id}")
def update_scan_task(
    task_id: str,
    update: ScanTaskStatusUpdate,
    db: Session = Depends(get_db),
):
    task = get_task_or_404(
        task_id,
        db,
    )

    allowed_statuses = {
        "pending",
        "opened",
        "no_match",
        "possible_match",
        "removal_ready",
        "removal_requested",
        "completed",
        "failed",
    }

    if update.status not in allowed_statuses:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid task status.",
        )

    now = datetime.now(timezone.utc)

    if update.status == "pending":
        task.status = "pending"
        task.started_at = None
        task.completed_at = None

    elif update.status == "opened":
        task.status = "opened"

        if task.started_at is None:
            task.started_at = now

        task.completed_at = None

    elif update.status == "no_match":
        task.status = "no_match"

        if task.started_at is None:
            task.started_at = now

        task.completed_at = now

    elif update.status == "possible_match":
        task.status = "possible_match"

        if task.started_at is None:
            task.started_at = now

        task.completed_at = None

    elif update.status == "removal_ready":
        task.status = "removal_ready"

        if task.started_at is None:
            task.started_at = now

        task.completed_at = None

    elif update.status == "removal_requested":
        task.status = "removal_requested"

        if task.started_at is None:
            task.started_at = now

        task.completed_at = None

    elif update.status == "completed":
        task.status = "completed"

        if task.started_at is None:
            task.started_at = now

        task.completed_at = now

    elif update.status == "failed":
        task.status = "failed"

        if task.started_at is None:
            task.started_at = now

        task.completed_at = now

    if update.result_url is not None:
        task.result_url = update.result_url

    if update.confidence_score is not None:
        task.confidence_score = (
            update.confidence_score
        )

    db.commit()
    db.refresh(task)

    profile_tasks = get_scan_tasks(
        db=db,
        profile_id=task.profile_id,
    )

    return {
        "message": (
            "Scan task updated."
        ),
        "task": serialize_scan_task(
            task
        ),
        "summary": summarize_scan_tasks(
            profile_tasks
        ),
    }


@router.post("/results/{profile_id}/discovered")
def create_discovered_listing(
    profile_id: str,
    listing: DiscoveredListingCreate,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        database_profile,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    source = get_source(
        listing.source_key
    )

    if source is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Unknown source key.",
        )

    profile_data = build_profile_data(
        database_profile
    )

    candidate = {
        "matched_name": listing.matched_name,
        "matched_phone": listing.matched_phone,
        "matched_email": listing.matched_email,
        "matched_address": listing.matched_address,
    }

    score = score_match(
        profile_data,
        candidate,
    )

    result = DBScanResult(
        profile_id=parsed_profile_id,
        source_name=source.name,
        source_url=listing.source_url,
        matched_name=listing.matched_name,
        matched_phone=listing.matched_phone,
        matched_email=listing.matched_email,
        matched_address=listing.matched_address,
        confidence_score=score.score,
        status="possible_match",
        removal_requested_at=None,
        removed_at=None,
    )

    db.add(result)
    db.commit()
    db.refresh(result)

    return {
        "message": (
            "Discovered listing saved."
        ),
        "source_key": source.key,
        "confidence": score.confidence,
        "matched_fields": list(
            score.matched_fields
        ),
        "result": serialize_scan_result(
            result
        ),
    }


@router.get("/results/{result_id}/removal-action")
def get_removal_action(
    result_id: str,
    db: Session = Depends(get_db),
):
    result = get_result_or_404(
        result_id,
        db,
    )

    source = find_source_for_result(
        result
    )

    if source is None:
        return {
            "result_id": str(result.id),
            "source_name": result.source_name,
            "supported": False,
            "removal_action": None,
            "message": (
                "No registered removal workflow "
                "was found for this source."
            ),
        }

    action_required = (
        source.requires_human_verification
        or source.removal_mode.value
        in {
            "partial",
            "manual",
        }
    )

    return {
        "result_id": str(result.id),
        "source_key": source.key,
        "source_name": source.name,
        "listing_url": result.source_url,
        "supported": True,
        "removal_action": {
            "mode": source.removal_mode.value,
            "removal_url": source.removal_url,
            "requires_human_verification": (
                source.requires_human_verification
            ),
            "action_required": action_required,
            "current_status": result.status,
            "instructions": (
                "Open the source removal page, "
                "identify the matching listing, "
                "complete any required verification, "
                "and submit the removal request."
            ),
        },
    }


@router.get("/results/{result_id}/recheck")
def get_recheck_action(
    result_id: str,
    db: Session = Depends(get_db),
):
    result = get_result_or_404(
        result_id,
        db,
    )

    return {
        "result_id": str(result.id),
        "source_name": result.source_name,
        "listing_url": result.source_url,
        "current_status": result.status,
        "removal_requested_at": (
            result.removal_requested_at.isoformat()
            if result.removal_requested_at is not None
            else None
        ),
        "removed_at": (
            result.removed_at.isoformat()
            if result.removed_at is not None
            else None
        ),
        "instructions": (
            "Open the original listing URL and verify "
            "whether the personal listing is still visible."
        ),
        "allowed_outcomes": [
            "still_present",
            "removed",
            "reappeared",
        ],
    }


@router.post("/start/{profile_id}")
async def start_scan(
    profile_id: str,
    db: Session = Depends(get_db),
):
    (
        parsed_profile_id,
        database_profile,
    ) = get_profile_or_404(
        profile_id,
        db,
    )

    profile_data = build_profile_data(
        database_profile
    )

    search_queries = build_profile_queries(
        profile_data
    )

    raw_matches = await connector_manager.run_all(
        profile_data
    )

    evaluated_matches = evaluate_matches(
        profile_data,
        raw_matches,
    )

    saved_results: list[DBScanResult] = []

    for evaluated in evaluated_matches:
        match = evaluated.match
        score = evaluated.score

        result = DBScanResult(
            profile_id=parsed_profile_id,
            source_name=match.source_name,
            source_url=match.source_url,
            matched_name=match.matched_name,
            matched_phone=match.matched_phone,
            matched_email=match.matched_email,
            matched_address=match.matched_address,
            confidence_score=score.score,
            status=match.status,
            removal_requested_at=None,
            removed_at=None,
        )

        db.add(result)
        saved_results.append(result)

    db.commit()

    for result in saved_results:
        db.refresh(result)

    return {
        "status": "completed",
        "profile_id": profile_id,
        "registered_sources": len(
            list_sources()
        ),
        "sites_scanned": (
            connector_manager.enabled_connector_count()
        ),
        "queries_generated": len(
            search_queries
        ),
        "matches_found": len(
            saved_results
        ),
        "matches": [
            serialize_scan_result(result)
            for result in saved_results
        ],
    }


@router.get("/results/{profile_id}")
def get_scan_results(
    profile_id: str,
    db: Session = Depends(get_db),
):
    try:
        parsed_profile_id = UUID(profile_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid privacy profile ID.",
        )

    results = db.scalars(
        select(DBScanResult)
        .where(
            DBScanResult.profile_id
            == parsed_profile_id
        )
        .order_by(
            DBScanResult.created_at.desc()
        )
    ).all()

    return {
        "profile_id": profile_id,
        "results_count": len(results),
        "results": [
            serialize_scan_result(result)
            for result in results
        ],
    }


@router.patch("/results/{result_id}/status")
def update_scan_result_status(
    result_id: str,
    update: ScanResultStatusUpdate,
    db: Session = Depends(get_db),
):
    result = get_result_or_404(
        result_id,
        db,
    )

    new_status = update.status

    allowed_statuses = {
        "possible_match",
        "removal_requested",
        "removed",
        "reappeared",
    }

    if new_status not in allowed_statuses:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                "Status must be possible_match, "
                "removal_requested, removed, "
                "or reappeared."
            ),
        )

    now = datetime.now(timezone.utc)

    if new_status == "possible_match":
        result.status = "possible_match"
        result.removal_requested_at = None
        result.removed_at = None

    elif new_status == "removal_requested":
        result.status = "removal_requested"

        if result.removal_requested_at is None:
            result.removal_requested_at = now

        result.removed_at = None

    elif new_status == "removed":
        result.status = "removed"

        if result.removal_requested_at is None:
            result.removal_requested_at = now

        if result.removed_at is None:
            result.removed_at = now

    elif new_status == "reappeared":
        result.status = "reappeared"

        if result.removal_requested_at is None:
            result.removal_requested_at = now

        result.removed_at = None

    db.commit()
    db.refresh(result)

    return {
        **serialize_scan_result(result),
        "message": (
            "Scan result status updated successfully."
        ),
    }