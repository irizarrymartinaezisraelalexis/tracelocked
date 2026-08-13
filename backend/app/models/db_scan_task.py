from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.connection import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class DBScanTask(Base):
    __tablename__ = "scan_tasks"

    id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    profile_id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey(
            "privacy_profiles.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    position: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        index=True,
    )

    source_key: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True,
    )

    source_name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    query_kind: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    query_value: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    source_url: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    removal_url: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    mode: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="direct_browser",
    )

    status: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="pending",
        index=True,
    )

    requires_human_verification: Mapped[bool] = mapped_column(
        nullable=False,
        default=True,
    )

    result_url: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    confidence_score: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=utc_now,
    )

    started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )