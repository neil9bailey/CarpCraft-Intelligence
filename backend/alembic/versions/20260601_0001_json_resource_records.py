"""create json resource records

Revision ID: 20260601_0001
Revises:
Create Date: 2026-06-01 00:01:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "20260601_0001"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    op.create_table(
        "json_resource_records",
        sa.Column("resource_type", sa.String(length=80), nullable=False),
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("resource_type", "id", name="pk_json_resource_records"),
    )
    op.create_index(
        "ix_json_resource_records_resource_type",
        "json_resource_records",
        ["resource_type"],
    )


def downgrade() -> None:
    op.drop_index("ix_json_resource_records_resource_type", table_name="json_resource_records")
    op.drop_table("json_resource_records")
