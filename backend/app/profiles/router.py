from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.models.db_privacy_profile import DBPrivacyProfile
from app.models.privacy_profile import (
    Address,
    PrivacyProfileCreate,
    PrivacyProfileResponse,
)

router = APIRouter(
    prefix="/profiles",
    tags=["Privacy Profiles"],
)


def build_profile_response(
    profile: DBPrivacyProfile,
) -> PrivacyProfileResponse:
    return PrivacyProfileResponse(
        profile_id=str(profile.id),
        status="created",
        first_name=profile.first_name,
        last_name=profile.last_name,
        email_addresses=[profile.email],
        phone_numbers=[profile.phone_number],
        current_address=Address(
            street=profile.street,
            city=profile.city,
            state=profile.state,
            postal_code=profile.postal_code,
        ),
        previous_addresses=[],
        date_of_birth=(
            profile.date_of_birth.isoformat()
            if profile.date_of_birth is not None
            else None
        ),
    )


@router.post(
    "/",
    response_model=PrivacyProfileResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_profile(
    profile: PrivacyProfileCreate,
    db: Session = Depends(get_db),
):
    if not profile.email_addresses:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="At least one email address is required.",
        )

    if not profile.phone_numbers:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="At least one phone number is required.",
        )

    parsed_date_of_birth = None

    if profile.date_of_birth:
        try:
            parsed_date_of_birth = date.fromisoformat(profile.date_of_birth)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Date of birth must use YYYY-MM-DD format.",
            )

    database_profile = DBPrivacyProfile(
        first_name=profile.first_name,
        last_name=profile.last_name,
        email=str(profile.email_addresses[0]),
        phone_number=profile.phone_numbers[0],
        street=profile.current_address.street,
        city=profile.current_address.city,
        state=profile.current_address.state.upper(),
        postal_code=profile.current_address.postal_code,
        date_of_birth=parsed_date_of_birth,
    )

    db.add(database_profile)
    db.commit()
    db.refresh(database_profile)

    return build_profile_response(database_profile)


@router.get(
    "/{profile_id}",
    response_model=PrivacyProfileResponse,
)
def get_profile(
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

    return build_profile_response(database_profile)