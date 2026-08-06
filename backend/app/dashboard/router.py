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
    )

    scan_results_count = db.scalar(
        select(func.count()).select_from(DBScanResult)
    )

    latest_scan = db.scalar(
        select(func.max(DBScanResult.created_at))
    )

    return {
        "profiles": profiles_count or 0,
        "scan_results": scan_results_count or 0,
        "latest_scan": (
            latest_scan.isoformat()
            if latest_scan is not None
            else None
        ),
    }