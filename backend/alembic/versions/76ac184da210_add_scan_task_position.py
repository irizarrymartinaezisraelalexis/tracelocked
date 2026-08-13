"""add scan task position

Revision ID: 76ac184da210
Revises: dc1978d3a295
Create Date: 2026-08-09
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "76ac184da210"
down_revision: Union[str, Sequence[str], None] = "dc1978d3a295"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "scan_tasks",
        sa.Column(
            "position",
            sa.Integer(),
            nullable=True,
        ),
    )

    op.execute(
        """
        WITH ranked AS (
            SELECT
                id,
                ROW_NUMBER() OVER (
                    PARTITION BY profile_id
                    ORDER BY created_at ASC, id ASC
                ) AS row_number
            FROM scan_tasks
        )
        UPDATE scan_tasks
        SET position = ranked.row_number
        FROM ranked
        WHERE scan_tasks.id = ranked.id
        """
    )

    op.alter_column(
        "scan_tasks",
        "position",
        existing_type=sa.Integer(),
        nullable=False,
    )

    op.create_index(
        op.f("ix_scan_tasks_position"),
        "scan_tasks",
        ["position"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_scan_tasks_position"),
        table_name="scan_tasks",
    )

    op.drop_column(
        "scan_tasks",
        "position",
    )