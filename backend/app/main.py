from fastapi import FastAPI

from app.auth import router as auth_router
from app.profiles.router import router as profile_router
from app.routes import router as scan_router

app = FastAPI(
    title="TraceLocked API",
    description=(
        "Privacy platform API for discovering, removing, "
        "and monitoring personal information."
    ),
    version="0.1.0",
)

app.include_router(auth_router)
app.include_router(scan_router)
app.include_router(profile_router)


@app.get("/")
async def root():
    return {
        "app": "TraceLocked",
        "status": "online",
        "version": "0.1.0",
        "message": "Welcome to the TraceLocked API.",
    }


@app.get("/health")
async def health():
    return {
        "status": "healthy",
    }