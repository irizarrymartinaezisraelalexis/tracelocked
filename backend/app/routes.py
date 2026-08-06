from fastapi import APIRouter, HTTPException, status

from app.profiles.router import profiles
from app.scan_engine.coordinator import ScanCoordinator

router = APIRouter(prefix="/scan", tags=["Scan"])

scan_coordinator = ScanCoordinator()


@router.get("/")
async def get_scan_status():
    return {
        "status": "ready",
        "message": "TraceLocked scan service is ready.",
    }


@router.post("/start/{profile_id}")
async def start_scan(profile_id: str):
    profile = profiles.get(profile_id)

    if profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Privacy profile not found.",
        )

    matches = await scan_coordinator.run_scan(profile.model_dump())

    return {
        "status": "completed",
        "profile_id": profile_id,
        "sites_scanned": len(scan_coordinator.connectors),
        "matches_found": len(matches),
        "matches": [match.model_dump() for match in matches],
    }