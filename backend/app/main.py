from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.auth import router as auth_router
from app.dashboard.router import router as dashboard_router
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

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(scan_router)
app.include_router(dashboard_router)


@app.get("/")
def root():
    return {
        "app": "TraceLocked",
        "status": "online",
        "version": "0.1.0",
        "message": "Welcome to the TraceLocked API.",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
    }