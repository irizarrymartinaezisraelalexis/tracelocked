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
        select(func.count()).select_from(DBPrivacyProfile)
    ) or 0

    scan_results_count = db.scalar(
        select(func.count()).select_from(DBScanResult)
    ) or 0

    possible_matches_count = db.scalar(
        select(func.count())
        .select_from(DBScanResult)
        .where(DBScanResult.status == "possible_match")
    ) or 0

    removed_count = db.scalar(
        select(func.count())
        .select_from(DBScanResult)
        .where(DBScanResult.status == "removed")
    ) or 0

    average_confidence = db.scalar(
        select(func.avg(DBScanResult.confidence_score))
    )

    latest_scan = db.scalar(
        select(func.max(DBScanResult.created_at))
    )

    risk_score = 0

    if scan_results_count > 0 and average_confidence is not None:
        risk_score = min(
            100,
            round(float(average_confidence)),
        )

    return {
        "profiles": profiles_count,
        "scan_results": scan_results_count,
        "possible_matches": possible_matches_count,
        "removed": removed_count,
        "risk_score": risk_score,
        "latest_scan": (
            latest_scan.isoformat()
            if latest_scan is not None
            else None
        ),
    }