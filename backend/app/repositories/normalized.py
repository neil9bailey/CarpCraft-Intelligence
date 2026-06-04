from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Any, TypeVar

from pydantic import BaseModel
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models.persistence import (
    AnglingSessionRecord,
    BaitApplicationRecord,
    BiteEventRecord,
    BlankIntervalRecord,
    CatchRecord,
    ObservationRecord,
    RecommendationOutcomeRecord,
    RecommendationRecord,
    RodSetRecord,
    SpotRecord,
    SwimRecord,
    VenueRecord,
    WaterReadingRecord,
    WeatherSnapshotRecord,
)
from app.schemas.domain import (
    BaitApplication,
    BiteEvent,
    BlankInterval,
    Catch,
    Observation,
    Recommendation,
    RecommendationOutcome,
    RodSet,
    Session as AnglingSession,
    Spot,
    Swim,
    Venue,
    WaterReading,
    WeatherSnapshot,
)

ModelT = TypeVar("ModelT", bound=BaseModel)


def _plain_value(value: Any) -> Any:
    if isinstance(value, Enum):
        return value.value
    return value


@dataclass(frozen=True)
class ResourceAdapter:
    model_type: type[BaseModel]
    record_type: type[Any]
    fields: tuple[str, ...]
    order_field: str = "id"

    def to_record_values(self, item: BaseModel) -> dict[str, Any]:
        return {field: _plain_value(getattr(item, field)) for field in self.fields}

    def to_schema(self, record: Any) -> BaseModel:
        return self.model_type.model_validate({field: getattr(record, field) for field in self.fields})


NORMALIZED_ADAPTERS: dict[str, ResourceAdapter] = {
    "venues": ResourceAdapter(
        model_type=Venue,
        record_type=VenueRecord,
        fields=(
            "id",
            "owner_user_id",
            "name",
            "type",
            "location_label",
            "approximate_latitude",
            "approximate_longitude",
            "acreage",
            "max_depth_m",
            "average_depth_m",
            "stock_notes",
            "rules_notes",
            "privacy_level",
            "created_at",
            "updated_at",
        ),
        order_field="created_at",
    ),
    "swims": ResourceAdapter(
        model_type=Swim,
        record_type=SwimRecord,
        fields=(
            "id",
            "venue_id",
            "name",
            "bank_aspect",
            "wind_exposure_notes",
            "access_notes",
            "pressure_rating",
            "privacy_level",
            "created_at",
            "updated_at",
        ),
        order_field="created_at",
    ),
    "spots": ResourceAdapter(
        model_type=Spot,
        record_type=SpotRecord,
        fields=(
            "id",
            "venue_id",
            "swim_id",
            "name",
            "latitude",
            "longitude",
            "distance_wraps",
            "distance_m",
            "depth_m",
            "substrate",
            "feature_type",
            "weed_density",
            "confidence_level",
            "notes",
        ),
    ),
    "sessions": ResourceAdapter(
        model_type=AnglingSession,
        record_type=AnglingSessionRecord,
        fields=(
            "id",
            "user_id",
            "venue_id",
            "swim_id",
            "started_at",
            "ended_at",
            "session_type",
            "status",
            "target_species",
            "target_fish_notes",
            "angling_pressure_count",
            "notes",
        ),
    ),
    "rod-sets": ResourceAdapter(
        model_type=RodSet,
        record_type=RodSetRecord,
        fields=(
            "id",
            "session_id",
            "rod_number",
            "spot_id",
            "cast_at",
            "retrieved_at",
            "distance_wraps",
            "depth_m",
            "presentation_layer",
            "rig_type",
            "hook_size",
            "hooklink",
            "lead_setup",
            "hookbait_type",
            "hookbait_colour",
            "hookbait_size_mm",
            "hookbait_buoyancy",
            "notes",
            "computed_rod_hours",
        ),
    ),
    "bait-applications": ResourceAdapter(
        model_type=BaitApplication,
        record_type=BaitApplicationRecord,
        fields=(
            "id",
            "session_id",
            "rod_set_id",
            "spot_id",
            "applied_at",
            "bait_type",
            "bait_category",
            "quantity_value",
            "quantity_unit",
            "spread_pattern",
            "notes",
        ),
        order_field="applied_at",
    ),
    "observations": ResourceAdapter(
        model_type=Observation,
        record_type=ObservationRecord,
        fields=(
            "id",
            "session_id",
            "observed_at",
            "observation_type",
            "swim_id",
            "spot_id",
            "confidence_level",
            "notes",
        ),
        order_field="observed_at",
    ),
    "water-readings": ResourceAdapter(
        model_type=WaterReading,
        record_type=WaterReadingRecord,
        fields=(
            "id",
            "session_id",
            "read_at",
            "water_temp_c",
            "dissolved_oxygen_mg_l",
            "ph",
            "turbidity_ntu",
            "conductivity",
            "depth_m",
            "reading_location_notes",
        ),
        order_field="read_at",
    ),
    "weather-snapshots": ResourceAdapter(
        model_type=WeatherSnapshot,
        record_type=WeatherSnapshotRecord,
        fields=(
            "id",
            "session_id",
            "captured_at",
            "source",
            "air_temp_c",
            "pressure_hpa",
            "pressure_trend_hpa_3h",
            "wind_speed_mps",
            "wind_direction_degrees",
            "wind_direction_label",
            "rainfall_mm",
            "cloud_cover_percent",
            "humidity_percent",
            "uv_index",
            "moon_phase",
            "sunrise_at",
            "sunset_at",
        ),
        order_field="captured_at",
    ),
    "bite-events": ResourceAdapter(
        model_type=BiteEvent,
        record_type=BiteEventRecord,
        fields=("id", "session_id", "rod_set_id", "occurred_at", "event_type", "notes"),
        order_field="occurred_at",
    ),
    "catches": ResourceAdapter(
        model_type=Catch,
        record_type=CatchRecord,
        fields=(
            "id",
            "session_id",
            "rod_set_id",
            "bite_event_id",
            "species",
            "weight_lb",
            "weight_oz",
            "length_cm",
            "caught_at",
            "photo_url",
            "fish_condition_notes",
            "returned_safely",
            "notes",
        ),
    ),
    "blanks": ResourceAdapter(
        model_type=BlankInterval,
        record_type=BlankIntervalRecord,
        fields=("id", "session_id", "started_at", "ended_at", "rods_active_count", "notes"),
    ),
    "recommendations": ResourceAdapter(
        model_type=Recommendation,
        record_type=RecommendationRecord,
        fields=(
            "id",
            "session_id",
            "generated_at",
            "location_score",
            "feeding_window_score",
            "presentation_fit_score",
            "oxygen_comfort_score",
            "pressure_risk_score",
            "confidence_score",
            "recommended_zone",
            "recommended_depth_or_layer",
            "recommended_tactic",
            "recommended_baiting_level",
            "explanation",
            "data_gaps",
            "evidence_summary",
            "alternative_plan",
            "seasonal_context",
            "barometric_note",
            "prime_feeding_windows",
            "priority_actions",
        ),
        order_field="generated_at",
    ),
    "recommendation-outcomes": ResourceAdapter(
        model_type=RecommendationOutcome,
        record_type=RecommendationOutcomeRecord,
        fields=("id", "recommendation_id", "session_id", "outcome_type", "reviewed_at", "notes"),
        order_field="reviewed_at",
    ),
}


def get_normalized_adapter(resource_type: str) -> ResourceAdapter | None:
    return NORMALIZED_ADAPTERS.get(resource_type)


class NormalizedRepository:
    def __init__(self, db: Session, adapter: ResourceAdapter) -> None:
        self.db = db
        self.adapter = adapter

    def list(self) -> list[BaseModel]:
        order_column = getattr(self.adapter.record_type, self.adapter.order_field)
        records = self.db.scalars(select(self.adapter.record_type).order_by(order_column.asc())).all()
        return [self.adapter.to_schema(record) for record in records]

    def get(self, item_id: str) -> BaseModel | None:
        record = self.db.get(self.adapter.record_type, item_id)
        if record is None:
            return None
        return self.adapter.to_schema(record)

    def create(self, item: BaseModel) -> BaseModel:
        record = self.adapter.record_type(**self.adapter.to_record_values(item))
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return self.adapter.to_schema(record)

    def upsert(self, item: BaseModel) -> BaseModel:
        item_id = str(getattr(item, "id"))
        record = self.db.get(self.adapter.record_type, item_id)
        if record is None:
            return self.create(item)
        self._apply(record, item)
        self.db.commit()
        self.db.refresh(record)
        return self.adapter.to_schema(record)

    def update(self, item_id: str, item: BaseModel) -> BaseModel | None:
        record = self.db.get(self.adapter.record_type, item_id)
        if record is None:
            return None
        updated = item.model_copy(update={"id": item_id})
        self._apply(record, updated)
        self.db.commit()
        self.db.refresh(record)
        return self.adapter.to_schema(record)

    def delete(self, item_id: str) -> bool:
        result = self.db.execute(delete(self.adapter.record_type).where(self.adapter.record_type.id == item_id))
        self.db.commit()
        return result.rowcount > 0

    def _apply(self, record: Any, item: BaseModel) -> None:
        for field, value in self.adapter.to_record_values(item).items():
            setattr(record, field, value)
