from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from sqlalchemy import Boolean, DateTime, Float, Integer, JSON, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class JsonResourceRecord(Base):
    """Persistent MVP record store for API resources.

    The payload remains shaped by Pydantic schemas. Normalised tables can be
    introduced resource by resource without changing API paths.
    """

    __tablename__ = "json_resource_records"

    resource_type: Mapped[str] = mapped_column(String(80), primary_key=True)
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    payload: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )


class VenueRecord(TimestampMixin, Base):
    __tablename__ = "venues"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    owner_user_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    type: Mapped[str] = mapped_column(String(40), nullable=False, default="unknown")
    location_label: Mapped[str | None] = mapped_column(String(255), nullable=True)
    approximate_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    approximate_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    acreage: Mapped[float | None] = mapped_column(Float, nullable=True)
    max_depth_m: Mapped[float | None] = mapped_column(Float, nullable=True)
    average_depth_m: Mapped[float | None] = mapped_column(Float, nullable=True)
    stock_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    rules_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    privacy_level: Mapped[str] = mapped_column(String(40), nullable=False, default="private")


class SwimRecord(TimestampMixin, Base):
    __tablename__ = "swims"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    venue_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    bank_aspect: Mapped[str | None] = mapped_column(String(80), nullable=True)
    wind_exposure_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    access_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    pressure_rating: Mapped[int | None] = mapped_column(Integer, nullable=True)
    privacy_level: Mapped[str] = mapped_column(String(40), nullable=False, default="private")


class SpotRecord(Base):
    __tablename__ = "spots"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    venue_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    swim_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    distance_wraps: Mapped[float | None] = mapped_column(Float, nullable=True)
    distance_m: Mapped[float | None] = mapped_column(Float, nullable=True)
    depth_m: Mapped[float | None] = mapped_column(Float, nullable=True)
    substrate: Mapped[str] = mapped_column(String(40), nullable=False, default="unknown")
    feature_type: Mapped[str] = mapped_column(String(40), nullable=False, default="unknown")
    weed_density: Mapped[int | None] = mapped_column(Integer, nullable=True)
    confidence_level: Mapped[int | None] = mapped_column(Integer, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class AnglingSessionRecord(Base):
    __tablename__ = "sessions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    venue_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    swim_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    session_type: Mapped[str | None] = mapped_column(String(80), nullable=True)
    status: Mapped[str] = mapped_column(String(40), nullable=False, default="planned")
    target_species: Mapped[str] = mapped_column(String(80), nullable=False, default="carp")
    target_fish_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    angling_pressure_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class RodSetRecord(Base):
    __tablename__ = "rod_sets"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    rod_number: Mapped[int] = mapped_column(Integer, nullable=False)
    spot_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    cast_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    retrieved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    distance_wraps: Mapped[float | None] = mapped_column(Float, nullable=True)
    depth_m: Mapped[float | None] = mapped_column(Float, nullable=True)
    presentation_layer: Mapped[str] = mapped_column(String(40), nullable=False, default="unknown")
    rig_type: Mapped[str | None] = mapped_column(String(120), nullable=True)
    hook_size: Mapped[str | None] = mapped_column(String(40), nullable=True)
    hooklink: Mapped[str | None] = mapped_column(String(120), nullable=True)
    lead_setup: Mapped[str | None] = mapped_column(String(120), nullable=True)
    hookbait_type: Mapped[str | None] = mapped_column(String(120), nullable=True)
    hookbait_colour: Mapped[str | None] = mapped_column(String(80), nullable=True)
    hookbait_size_mm: Mapped[float | None] = mapped_column(Float, nullable=True)
    hookbait_buoyancy: Mapped[str | None] = mapped_column(String(80), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    computed_rod_hours: Mapped[float | None] = mapped_column(Float, nullable=True)


class BaitApplicationRecord(Base):
    __tablename__ = "bait_applications"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    rod_set_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    spot_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    applied_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    bait_type: Mapped[str | None] = mapped_column(String(120), nullable=True)
    bait_category: Mapped[str] = mapped_column(String(40), nullable=False, default="unknown")
    quantity_value: Mapped[float | None] = mapped_column(Float, nullable=True)
    quantity_unit: Mapped[str | None] = mapped_column(String(40), nullable=True)
    spread_pattern: Mapped[str] = mapped_column(String(40), nullable=False, default="unknown")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class ObservationRecord(Base):
    __tablename__ = "observations"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    observed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    observation_type: Mapped[str] = mapped_column(String(60), nullable=False, default="other")
    swim_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    spot_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    confidence_level: Mapped[int | None] = mapped_column(Integer, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class WaterReadingRecord(Base):
    __tablename__ = "water_readings"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    read_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    water_temp_c: Mapped[float | None] = mapped_column(Float, nullable=True)
    dissolved_oxygen_mg_l: Mapped[float | None] = mapped_column(Float, nullable=True)
    ph: Mapped[float | None] = mapped_column(Float, nullable=True)
    turbidity_ntu: Mapped[float | None] = mapped_column(Float, nullable=True)
    conductivity: Mapped[float | None] = mapped_column(Float, nullable=True)
    depth_m: Mapped[float | None] = mapped_column(Float, nullable=True)
    reading_location_notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class WeatherSnapshotRecord(Base):
    __tablename__ = "weather_snapshots"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    captured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    source: Mapped[str] = mapped_column(String(80), nullable=False, default="manual")
    air_temp_c: Mapped[float | None] = mapped_column(Float, nullable=True)
    pressure_hpa: Mapped[float | None] = mapped_column(Float, nullable=True)
    pressure_trend_hpa_3h: Mapped[float | None] = mapped_column(Float, nullable=True)
    wind_speed_mps: Mapped[float | None] = mapped_column(Float, nullable=True)
    wind_direction_degrees: Mapped[float | None] = mapped_column(Float, nullable=True)
    wind_direction_label: Mapped[str | None] = mapped_column(String(40), nullable=True)
    rainfall_mm: Mapped[float | None] = mapped_column(Float, nullable=True)
    cloud_cover_percent: Mapped[int | None] = mapped_column(Integer, nullable=True)
    humidity_percent: Mapped[int | None] = mapped_column(Integer, nullable=True)
    uv_index: Mapped[float | None] = mapped_column(Float, nullable=True)
    moon_phase: Mapped[str | None] = mapped_column(String(80), nullable=True)
    sunrise_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sunset_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class BiteEventRecord(Base):
    __tablename__ = "bite_events"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    rod_set_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    event_type: Mapped[str] = mapped_column(String(60), nullable=False, default="unknown")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class CatchRecord(Base):
    __tablename__ = "catches"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    rod_set_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    bite_event_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    species: Mapped[str] = mapped_column(String(80), nullable=False, default="carp")
    weight_lb: Mapped[int | None] = mapped_column(Integer, nullable=True)
    weight_oz: Mapped[int | None] = mapped_column(Integer, nullable=True)
    length_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    caught_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    photo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    fish_condition_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    returned_safely: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class BlankIntervalRecord(Base):
    __tablename__ = "blank_intervals"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    rods_active_count: Mapped[int] = mapped_column(Integer, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class RecommendationRecord(Base):
    __tablename__ = "recommendations"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    location_score: Mapped[int] = mapped_column(Integer, nullable=False)
    feeding_window_score: Mapped[int] = mapped_column(Integer, nullable=False)
    presentation_fit_score: Mapped[int] = mapped_column(Integer, nullable=False)
    oxygen_comfort_score: Mapped[int] = mapped_column(Integer, nullable=False)
    pressure_risk_score: Mapped[int] = mapped_column(Integer, nullable=False)
    confidence_score: Mapped[int] = mapped_column(Integer, nullable=False)
    recommended_zone: Mapped[str] = mapped_column(String(255), nullable=False)
    recommended_depth_or_layer: Mapped[str] = mapped_column(String(255), nullable=False)
    recommended_tactic: Mapped[str] = mapped_column(Text, nullable=False)
    recommended_baiting_level: Mapped[str] = mapped_column(String(120), nullable=False)
    explanation: Mapped[str] = mapped_column(Text, nullable=False)
    data_gaps: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    evidence_summary: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    alternative_plan: Mapped[str] = mapped_column(Text, nullable=False)


class RecommendationOutcomeRecord(Base):
    __tablename__ = "recommendation_outcomes"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    recommendation_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    session_id: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    outcome_type: Mapped[str] = mapped_column(String(60), nullable=False, default="unknown")
    reviewed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
