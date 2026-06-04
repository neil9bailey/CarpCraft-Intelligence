"""add watercraft plan fields to recommendations

Revision ID: 20260604_0004
Revises: 20260601_0003
Create Date: 2026-06-04 00:04:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "20260604_0004"
down_revision: Union[str, Sequence[str], None] = "20260601_0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("recommendations", sa.Column("seasonal_context", sa.Text(), nullable=True))
    op.add_column("recommendations", sa.Column("barometric_note", sa.Text(), nullable=True))
    op.add_column(
        "recommendations",
        sa.Column("prime_feeding_windows", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
    )
    op.add_column(
        "recommendations",
        sa.Column("priority_actions", sa.JSON(), nullable=False, server_default=sa.text("'[]'")),
    )
    # The empty-array server default backfills existing rows and is portable across
    # PostgreSQL and SQLite; the application always supplies explicit values.


def downgrade() -> None:
    op.drop_column("recommendations", "priority_actions")
    op.drop_column("recommendations", "prime_feeding_windows")
    op.drop_column("recommendations", "barometric_note")
    op.drop_column("recommendations", "seasonal_context")
