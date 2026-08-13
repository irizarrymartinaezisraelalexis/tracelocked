from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.models.db_privacy_profile import DBPrivacyProfile
from app.models.db_scan_result import DBScanResult


router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"],
)


@router.get("/")
def get_dashboard(
    db: Session = Depends(get_db),
):
    profiles_count = db.scalar(
        select(func.count()).select_from(
            DBPrivacyProfile
        )
    ) or 0

    scan_results_count = db.scalar(
        select(func.count()).select_from(
            DBScanResult
        )
    ) or 0

    possible_matches_count = db.scalar(
        select(func.count())
        .select_from(DBScanResult)
        .where(
            DBScanResult.status
            == "possible_match"
        )
    ) or 0

    removal_requested_count = db.scalar(
        select(func.count())
        .select_from(DBScanResult)
        .where(
            DBScanResult.status
            == "removal_requested"
        )
    ) or 0

    removed_count = db.scalar(
        select(func.count())
        .select_from(DBScanResult)
        .where(
            DBScanResult.status
            == "removed"
        )
    ) or 0

    latest_scan = db.scalar(
        select(
            func.max(
                DBScanResult.created_at
            )
        )
    )

    active_confidence = db.scalar(
        select(
            func.avg(
                DBScanResult.confidence_score
            )
        ).where(
            DBScanResult.status
            == "possible_match"
        )
    )

    requested_confidence = db.scalar(
        select(
            func.avg(
                DBScanResult.confidence_score
            )
        ).where(
            DBScanResult.status
            == "removal_requested"
        )
    )

    risk_score = 0

    if scan_results_count > 0:
        total_risk = 0.0

        if (
            possible_matches_count > 0
            and active_confidence is not None
        ):
            total_risk += (
                float(active_confidence)
                * possible_matches_count
            )

        if (
            removal_requested_count > 0
            and requested_confidence is not None
        ):
            total_risk += (
                float(requested_confidence)
                * removal_requested_count
                * 0.5
            )

        risk_score = round(
            total_risk / scan_results_count
        )

        risk_score = max(
            0,
            min(100, risk_score),
        )

    recent_results = db.scalars(
        select(DBScanResult)
        .order_by(
            DBScanResult.created_at.desc()
        )
        .limit(5)
    ).all()

    recent_activity = []

    for result in recent_results:
        activity_type = "found"
        activity_date = result.created_at

        if (
            result.status == "removed"
            and result.removed_at is not None
        ):
            activity_type = "removed"
            activity_date = result.removed_at

        elif (
            result.status == "removal_requested"
            and result.removal_requested_at
            is not None
        ):
            activity_type = "removal_requested"
            activity_date = (
                result.removal_requested_at
            )

        recent_activity.append(
            {
                "id": str(result.id),
                "profile_id": str(
                    result.profile_id
                ),
                "source_name":
                    result.source_name,
                "source_url":
                    result.source_url,
                "matched_name":
                    result.matched_name,
                "matched_phone":
                    result.matched_phone,
                "matched_email":
                    result.matched_email,
                "matched_address":
                    result.matched_address,
                "confidence_score":
                    result.confidence_score,
                "status": result.status,
                "activity_type":
                    activity_type,
                "activity_date": (
                    activity_date.isoformat()
                    if activity_date is not None
                    else None
                ),
                "created_at": (
                    result.created_at.isoformat()
                    if result.created_at
                    is not None
                    else None
                ),
                "removal_requested_at": (
                    result
                    .removal_requested_at
                    .isoformat()
                    if result
                    .removal_requested_at
                    is not None
                    else None
                ),
                "removed_at": (
                    result.removed_at.isoformat()
                    if result.removed_at
                    is not None
                    else None
                ),
            }
        )

    recent_activity.sort(
        key=lambda item:
            item["activity_date"] or "",
        reverse=True,
    )

    return {
        "profiles": profiles_count,
        "scan_results": scan_results_count,
        "possible_matches":
            possible_matches_count,
        "removal_requested":
            removal_requested_count,
        "removed": removed_count,
        "risk_score": risk_score,
        "latest_scan": (
            latest_scan.isoformat()
            if latest_scan is not None
            else None
        ),
        "recent_activity":
            recent_activity,
    }