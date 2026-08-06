from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.models.db_privacy_profile import DBPrivacyProfile
from app.models.db_scan_result import DBScanResult
from app.scan_engine.coordinator import ScanCoordinator

router = APIRouter(prefix="/scan", tags=["Scan"])

scan_coordinator = ScanCoordinator()


@router.get("/")
def get_scan_status():
    return {
        "status": "ready",
        "message": "TraceLocked scan service is ready.",
    }


@router.post("/start/{profile_id}")
async def start_scan(
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

    database_profile = db.get(
        DBPrivacyProfile,
        parsed_profile_id,
    )

    if database_profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Privacy profile not found.",
        )

    profile_data = {
        "first_name": database_profile.first_name,
        "last_name": database_profile.last_name,
        "email_addresses": [database_profile.email],
        "phone_numbers": [database_profile.phone_number],
        "current_address": {
            "street": database_profile.street,
            "city": database_profile.city,
            "state": database_profile.state,
            "postal_code": database_profile.postal_code,
        },
        "previous_addresses": [],
        "date_of_birth": (
            database_profile.date_of_birth.isoformat()
            if database_profile.date_of_birth is not None
            else None
        ),
    }

    matches = await scan_coordinator.run_scan(profile_data)

    saved_results = []

    for match in matches:
        result = DBScanResult(
            profile_id=parsed_profile_id,
            source_name=match.source_name,
            source_url=match.source_url,
            matched_name=match.matched_name,
            matched_phone=match.matched_phone,
            matched_email=match.matched_email,
            matched_address=match.matched_address,
            confidence_score=match.confidence_score,
            status=match.status,
        )

        db.add(result)
        saved_results.append(result)

    db.commit()

    for result in saved_results:
        db.refresh(result)

    return {
        "status": "completed",
        "profile_id": profile_id,
        "sites_scanned": len(scan_coordinator.connectors),
        "matches_found": len(saved_results),
        "matches": [
            {
                "id": str(result.id),
                "source_name": result.source_name,
                "source_url": result.source_url,
                "matched_name": result.matched_name,
                "matched_phone": result.matched_phone,
                "matched_email": result.matched_email,
                "matched_address": result.matched_address,
                "confidence_score": result.confidence_score,
                "status": result.status,
                "created_at": result.created_at.isoformat(),
            }
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
        .where(DBScanResult.profile_id == parsed_profile_id)
        .order_by(DBScanResult.created_at.desc())
    ).all()

    return {
        "profile_id": profile_id,
        "results_count": len(results),
        "results": [
            {
                "id": str(result.id),
                "source_name": result.source_name,
                "source_url": result.source_url,
                "matched_name": result.matched_name,
                "matched_phone": result.matched_phone,
                "matched_email": result.matched_email,
                "matched_address": result.matched_address,
                "confidence_score": result.confidence_score,
                "status": result.status,
                "created_at": result.created_at.isoformat(),
            }
            for result in results
        ],
    }