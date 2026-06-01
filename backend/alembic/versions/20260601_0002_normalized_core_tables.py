"""create normalized core tables

Revision ID: 20260601_0002
Revises: 20260601_0001
Create Date: 2026-06-01 00:02:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "20260601_0002"
down_revision: Union[str, Sequence[str], None] = "20260601_0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "venues",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("owner_user_id", sa.String(length=64), nullable=True),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("type", sa.String(length=40), nullable=False),
        sa.Column("location_label", sa.String(length=255), nullable=True),
        sa.Column("approximate_latitude", sa.Float(), nullable=True),
        sa.Column("approximate_longitude", sa.Float(), nullable=True),
        sa.Column("acreage", sa.Float(), nullable=True),
        sa.Column("max_depth_m", sa.Float(), nullable=True),
        sa.Column("average_depth_m", sa.Float(), nullable=True),
        sa.Column("stock_notes", sa.Text(), nullable=True),
        sa.Column("rules_notes", sa.Text(), nullable=True),
        sa.Column("privacy_level", sa.String(length=40), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_venues_owner_user_id", "venues", ["owner_user_id"])

    op.create_table(
        "swims",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("venue_id", sa.String(length=64), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("bank_aspect", sa.String(length=80), nullable=True),
        sa.Column("wind_exposure_notes", sa.Text(), nullable=True),
        sa.Column("access_notes", sa.Text(), nullable=True),
        sa.Column("pressure_rating", sa.Integer(), nullable=True),
        sa.Column("privacy_level", sa.String(length=40), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_swims_venue_id", "swims", ["venue_id"])

    op.create_table(
        "spots",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("venue_id", sa.String(length=64), nullable=False),
        sa.Column("swim_id", sa.String(length=64), nullable=True),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("distance_wraps", sa.Float(), nullable=True),
        sa.Column("distance_m", sa.Float(), nullable=True),
        sa.Column("depth_m", sa.Float(), nullable=True),
        sa.Column("substrate", sa.String(length=40), nullable=False),
        sa.Column("feature_type", sa.String(length=40), nullable=False),
        sa.Column("weed_density", sa.Integer(), nullable=True),
        sa.Column("confidence_level", sa.Integer(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_spots_venue_id", "spots", ["venue_id"])
    op.create_index("ix_spots_swim_id", "spots", ["swim_id"])

    op.create_table(
        "sessions",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("user_id", sa.String(length=64), nullable=True),
        sa.Column("venue_id", sa.String(length=64), nullable=False),
        sa.Column("swim_id", sa.String(length=64), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("session_type", sa.String(length=80), nullable=True),
        sa.Column("status", sa.String(length=40), nullable=False),
        sa.Column("target_species", sa.String(length=80), nullable=False),
        sa.Column("target_fish_notes", sa.Text(), nullable=True),
        sa.Column("angling_pressure_count", sa.Integer(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_sessions_user_id", "sessions", ["user_id"])
    op.create_index("ix_sessions_venue_id", "sessions", ["venue_id"])
    op.create_index("ix_sessions_swim_id", "sessions", ["swim_id"])

    op.create_table(
        "catches",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("rod_set_id", sa.String(length=64), nullable=True),
        sa.Column("bite_event_id", sa.String(length=64), nullable=True),
        sa.Column("species", sa.String(length=80), nullable=False),
        sa.Column("weight_lb", sa.Integer(), nullable=True),
        sa.Column("weight_oz", sa.Integer(), nullable=True),
        sa.Column("length_cm", sa.Float(), nullable=True),
        sa.Column("caught_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("photo_url", sa.String(length=500), nullable=True),
        sa.Column("fish_condition_notes", sa.Text(), nullable=True),
        sa.Column("returned_safely", sa.Boolean(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_catches_session_id", "catches", ["session_id"])
    op.create_index("ix_catches_rod_set_id", "catches", ["rod_set_id"])
    op.create_index("ix_catches_bite_event_id", "catches", ["bite_event_id"])

    op.create_table(
        "blank_intervals",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("rods_active_count", sa.Integer(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_blank_intervals_session_id", "blank_intervals", ["session_id"])

    op.create_table(
        "recommendations",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("location_score", sa.Integer(), nullable=False),
        sa.Column("feeding_window_score", sa.Integer(), nullable=False),
        sa.Column("presentation_fit_score", sa.Integer(), nullable=False),
        sa.Column("oxygen_comfort_score", sa.Integer(), nullable=False),
        sa.Column("pressure_risk_score", sa.Integer(), nullable=False),
        sa.Column("confidence_score", sa.Integer(), nullable=False),
        sa.Column("recommended_zone", sa.String(length=255), nullable=False),
        sa.Column("recommended_depth_or_layer", sa.String(length=255), nullable=False),
        sa.Column("recommended_tactic", sa.Text(), nullable=False),
        sa.Column("recommended_baiting_level", sa.String(length=120), nullable=False),
        sa.Column("explanation", sa.Text(), nullable=False),
        sa.Column("data_gaps", sa.JSON(), nullable=False),
        sa.Column("evidence_summary", sa.JSON(), nullable=False),
        sa.Column("alternative_plan", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_recommendations_session_id", "recommendations", ["session_id"])

    op.create_table(
        "recommendation_outcomes",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("recommendation_id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("outcome_type", sa.String(length=60), nullable=False),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_recommendation_outcomes_recommendation_id", "recommendation_outcomes", ["recommendation_id"])
    op.create_index("ix_recommendation_outcomes_session_id", "recommendation_outcomes", ["session_id"])


def downgrade() -> None:
    op.drop_index("ix_recommendation_outcomes_session_id", table_name="recommendation_outcomes")
    op.drop_index("ix_recommendation_outcomes_recommendation_id", table_name="recommendation_outcomes")
    op.drop_table("recommendation_outcomes")
    op.drop_index("ix_recommendations_session_id", table_name="recommendations")
    op.drop_table("recommendations")
    op.drop_index("ix_blank_intervals_session_id", table_name="blank_intervals")
    op.drop_table("blank_intervals")
    op.drop_index("ix_catches_bite_event_id", table_name="catches")
    op.drop_index("ix_catches_rod_set_id", table_name="catches")
    op.drop_index("ix_catches_session_id", table_name="catches")
    op.drop_table("catches")
    op.drop_index("ix_sessions_swim_id", table_name="sessions")
    op.drop_index("ix_sessions_venue_id", table_name="sessions")
    op.drop_index("ix_sessions_user_id", table_name="sessions")
    op.drop_table("sessions")
    op.drop_index("ix_spots_swim_id", table_name="spots")
    op.drop_index("ix_spots_venue_id", table_name="spots")
    op.drop_table("spots")
    op.drop_index("ix_swims_venue_id", table_name="swims")
    op.drop_table("swims")
    op.drop_index("ix_venues_owner_user_id", table_name="venues")
    op.drop_table("venues")
