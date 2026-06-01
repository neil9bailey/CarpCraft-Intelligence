"""create normalized evidence tables

Revision ID: 20260601_0003
Revises: 20260601_0002
Create Date: 2026-06-01 00:03:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "20260601_0003"
down_revision: Union[str, Sequence[str], None] = "20260601_0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "rod_sets",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("rod_number", sa.Integer(), nullable=False),
        sa.Column("spot_id", sa.String(length=64), nullable=True),
        sa.Column("cast_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("retrieved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("distance_wraps", sa.Float(), nullable=True),
        sa.Column("depth_m", sa.Float(), nullable=True),
        sa.Column("presentation_layer", sa.String(length=40), nullable=False),
        sa.Column("rig_type", sa.String(length=120), nullable=True),
        sa.Column("hook_size", sa.String(length=40), nullable=True),
        sa.Column("hooklink", sa.String(length=120), nullable=True),
        sa.Column("lead_setup", sa.String(length=120), nullable=True),
        sa.Column("hookbait_type", sa.String(length=120), nullable=True),
        sa.Column("hookbait_colour", sa.String(length=80), nullable=True),
        sa.Column("hookbait_size_mm", sa.Float(), nullable=True),
        sa.Column("hookbait_buoyancy", sa.String(length=80), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("computed_rod_hours", sa.Float(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_rod_sets_session_id", "rod_sets", ["session_id"])
    op.create_index("ix_rod_sets_spot_id", "rod_sets", ["spot_id"])

    op.create_table(
        "bait_applications",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("rod_set_id", sa.String(length=64), nullable=True),
        sa.Column("spot_id", sa.String(length=64), nullable=True),
        sa.Column("applied_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("bait_type", sa.String(length=120), nullable=True),
        sa.Column("bait_category", sa.String(length=40), nullable=False),
        sa.Column("quantity_value", sa.Float(), nullable=True),
        sa.Column("quantity_unit", sa.String(length=40), nullable=True),
        sa.Column("spread_pattern", sa.String(length=40), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_bait_applications_session_id", "bait_applications", ["session_id"])
    op.create_index("ix_bait_applications_rod_set_id", "bait_applications", ["rod_set_id"])
    op.create_index("ix_bait_applications_spot_id", "bait_applications", ["spot_id"])

    op.create_table(
        "observations",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("observed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("observation_type", sa.String(length=60), nullable=False),
        sa.Column("swim_id", sa.String(length=64), nullable=True),
        sa.Column("spot_id", sa.String(length=64), nullable=True),
        sa.Column("confidence_level", sa.Integer(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_observations_session_id", "observations", ["session_id"])
    op.create_index("ix_observations_swim_id", "observations", ["swim_id"])
    op.create_index("ix_observations_spot_id", "observations", ["spot_id"])

    op.create_table(
        "water_readings",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("water_temp_c", sa.Float(), nullable=True),
        sa.Column("dissolved_oxygen_mg_l", sa.Float(), nullable=True),
        sa.Column("ph", sa.Float(), nullable=True),
        sa.Column("turbidity_ntu", sa.Float(), nullable=True),
        sa.Column("conductivity", sa.Float(), nullable=True),
        sa.Column("depth_m", sa.Float(), nullable=True),
        sa.Column("reading_location_notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_water_readings_session_id", "water_readings", ["session_id"])

    op.create_table(
        "weather_snapshots",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("captured_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("source", sa.String(length=80), nullable=False),
        sa.Column("air_temp_c", sa.Float(), nullable=True),
        sa.Column("pressure_hpa", sa.Float(), nullable=True),
        sa.Column("pressure_trend_hpa_3h", sa.Float(), nullable=True),
        sa.Column("wind_speed_mps", sa.Float(), nullable=True),
        sa.Column("wind_direction_degrees", sa.Float(), nullable=True),
        sa.Column("wind_direction_label", sa.String(length=40), nullable=True),
        sa.Column("rainfall_mm", sa.Float(), nullable=True),
        sa.Column("cloud_cover_percent", sa.Integer(), nullable=True),
        sa.Column("humidity_percent", sa.Integer(), nullable=True),
        sa.Column("uv_index", sa.Float(), nullable=True),
        sa.Column("moon_phase", sa.String(length=80), nullable=True),
        sa.Column("sunrise_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sunset_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_weather_snapshots_session_id", "weather_snapshots", ["session_id"])

    op.create_table(
        "bite_events",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("session_id", sa.String(length=64), nullable=False),
        sa.Column("rod_set_id", sa.String(length=64), nullable=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("event_type", sa.String(length=60), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_bite_events_session_id", "bite_events", ["session_id"])
    op.create_index("ix_bite_events_rod_set_id", "bite_events", ["rod_set_id"])


def downgrade() -> None:
    op.drop_index("ix_bite_events_rod_set_id", table_name="bite_events")
    op.drop_index("ix_bite_events_session_id", table_name="bite_events")
    op.drop_table("bite_events")
    op.drop_index("ix_weather_snapshots_session_id", table_name="weather_snapshots")
    op.drop_table("weather_snapshots")
    op.drop_index("ix_water_readings_session_id", table_name="water_readings")
    op.drop_table("water_readings")
    op.drop_index("ix_observations_spot_id", table_name="observations")
    op.drop_index("ix_observations_swim_id", table_name="observations")
    op.drop_index("ix_observations_session_id", table_name="observations")
    op.drop_table("observations")
    op.drop_index("ix_bait_applications_spot_id", table_name="bait_applications")
    op.drop_index("ix_bait_applications_rod_set_id", table_name="bait_applications")
    op.drop_index("ix_bait_applications_session_id", table_name="bait_applications")
    op.drop_table("bait_applications")
    op.drop_index("ix_rod_sets_spot_id", table_name="rod_sets")
    op.drop_index("ix_rod_sets_session_id", table_name="rod_sets")
    op.drop_table("rod_sets")
