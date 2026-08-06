from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.connection import Base


class DBScanResult(Base):
    __tablename__ = "scan_results"

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    profile_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("privacy_profiles.id", ondelete="CASCADE"),
        index=True,
    )

    source_name: Mapped[str] = mapped_column(String(255))
    source_url: Mapped[str] = mapped_column(String(1000))

    matched_name: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    matched_phone: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    matched_email: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    matched_address: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    confidence_score: Mapped[int] = mapped_column(Integer)

    status: Mapped[str] = mapped_column(
        String(50),
        default="possible_match",
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )