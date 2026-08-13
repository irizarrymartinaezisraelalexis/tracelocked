"""add removal timestamps to scan results

Revision ID: c4b890b43e9b
Revises: 78f996c2093d
Create Date: 2026-08-07 16:59:06.464685

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c4b890b43e9b'
down_revision: Union[str, Sequence[str], None] = '78f996c2093d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
