from fastapi import APIRouter, HTTPException, status

from app.models.user import UserCreate, UserLogin
from app.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["Authentication"])

users: dict[str, dict[str, str]] = {}


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate):
    normalized_email = user.email.lower()

    if normalized_email in users:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    users[normalized_email] = {
        "first_name": user.first_name,
        "last_name": user.last_name,
        "email": normalized_email,
        "hashed_password": hash_password(user.password),
    }

    return {
        "message": "Account created successfully.",
        "user": {
            "first_name": user.first_name,
            "last_name": user.last_name,
            "email": normalized_email,
        },
    }


@router.post("/login")
async def login(user: UserLogin):
    normalized_email = user.email.lower()
    stored_user = users.get(normalized_email)

    if stored_user is None or not verify_password(
        user.password,
        stored_user["hashed_password"],
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    access_token = create_access_token(normalized_email)

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }