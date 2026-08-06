from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.models.db_privacy_profile import DBPrivacyProfile
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

    return {
        "status": "completed",
        "profile_id": profile_id,
        "sites_scanned": len(scan_coordinator.connectors),
        "matches_found": len(matches),
        "matches": [match.model_dump() for match in matches],
    }