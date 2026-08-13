"""add removal timestamps to scan results

Revision ID: 78f996c2093d
Revises: bfa1c6c084f4
Create Date: 2026-08-07 16:57:49.261898
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "78f996c2093d"
down_revision: Union[str, Sequence[str], None] = "bfa1c6c084f4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "scan_results",
        sa.Column(
            "removal_requested_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.add_column(
        "scan_results",
        sa.Column(
            "removed_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column(
        "scan_results",
        "removed_at",
    )

    op.drop_column(
        "scan_results",
        "removal_requested_at",
    )