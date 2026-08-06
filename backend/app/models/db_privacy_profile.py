from datetime import date
from uuid import UUID, uuid4

from sqlalchemy import Date, String
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.connection import Base


class DBPrivacyProfile(Base):
    __tablename__ = "privacy_profiles"

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        default=uuid4,
    )

    first_name: Mapped[str] = mapped_column(String(100))
    last_name: Mapped[str] = mapped_column(String(100))

    email: Mapped[str] = mapped_column(String(255))
    phone_number: Mapped[str] = mapped_column(String(25))

    street: Mapped[str] = mapped_column(String(255))
    city: Mapped[str] = mapped_column(String(100))
    state: Mapped[str] = mapped_column(String(2))
    postal_code: Mapped[str] = mapped_column(String(10))

    date_of_birth: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )