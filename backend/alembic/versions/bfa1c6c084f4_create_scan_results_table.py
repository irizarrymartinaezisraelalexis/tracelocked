"""create scan results table

Revision ID: bfa1c6c084f4
Revises: ce7a7a121e34
Create Date: 2026-08-06
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "bfa1c6c084f4"
down_revision: Union[str, Sequence[str], None] = "ce7a7a121e34"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "scan_results",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
        ),
        sa.Column(
            "profile_id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
        ),
        sa.Column(
            "source_name",
            sa.String(length=255),
            nullable=False,
        ),
        sa.Column(
            "source_url",
            sa.String(length=1000),
            nullable=False,
        ),
        sa.Column(
            "matched_name",
            sa.String(length=255),
            nullable=True,
        ),
        sa.Column(
            "matched_phone",
            sa.String(length=50),
            nullable=True,
        ),
        sa.Column(
            "matched_email",
            sa.String(length=255),
            nullable=True,
        ),
        sa.Column(
            "matched_address",
            sa.String(length=500),
            nullable=True,
        ),
        sa.Column(
            "confidence_score",
            sa.Integer(),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.String(length=50),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["profile_id"],
            ["privacy_profiles.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        op.f("ix_scan_results_profile_id"),
        "scan_results",
        ["profile_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_scan_results_profile_id"),
        table_name="scan_results",
    )

    op.drop_table(
        "scan_results"
    )