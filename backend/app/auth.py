from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.models.db_user import DBUser
from app.models.user import UserCreate, UserLogin
from app.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(
    user: UserCreate,
    db: Session = Depends(get_db),
):
    normalized_email = user.email.lower()

    existing_user = db.scalar(
        select(DBUser).where(DBUser.email == normalized_email)
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    new_user = DBUser(
        first_name=user.first_name,
        last_name=user.last_name,
        email=normalized_email,
        hashed_password=hash_password(user.password),
    )

    db.add(new_user)

    try:
        db.commit()
        db.refresh(new_user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    return {
        "message": "Account created successfully.",
        "user": {
            "id": new_user.id,
            "first_name": new_user.first_name,
            "last_name": new_user.last_name,
            "email": new_user.email,
        },
    }


@router.post("/login")
def login(
    user: UserLogin,
    db: Session = Depends(get_db),
):
    normalized_email = user.email.lower()

    stored_user = db.scalar(
        select(DBUser).where(DBUser.email == normalized_email)
    )

    if stored_user is None or not verify_password(
        user.password,
        stored_user.hashed_password,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    access_token = create_access_token(stored_user.email)

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }