from fastapi import APIRouter
from uuid import uuid4

from app.models.privacy_profile import (
    PrivacyProfileCreate,
    PrivacyProfileResponse,
)

router = APIRouter(prefix="/profiles", tags=["Privacy Profiles"])

profiles: dict[str, PrivacyProfileResponse] = {}


@router.post("/", response_model=PrivacyProfileResponse)
async def create_profile(
    profile: PrivacyProfileCreate,
):
    profile_id = str(uuid4())

    saved_profile = PrivacyProfileResponse(
        profile_id=profile_id,
        status="created",
        **profile.model_dump(),
    )

    profiles[profile_id] = saved_profile

    return saved_profile


@router.get("/{profile_id}", response_model=PrivacyProfileResponse)
async def get_profile(profile_id: str):
    return profiles[profile_id]