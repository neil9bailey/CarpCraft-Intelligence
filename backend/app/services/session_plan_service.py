from __future__ import annotations

from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.persistence import (
    AnglingSessionRecord,
    CatchRecord,
    ObservationRecord,
    WaterReadingRecord,
    WeatherSnapshotRecord,
)
from app.rules.recommendation_engine import RecommendationEngine
from app.schemas.domain import (
    ObservationSignal,
    ObservationType,
    Recommendation,
    RecommendationContext,
    RecommendationResult,
)

# Observation types that count as positive "signs of fish" for the engine.
_POSITIVE_SIGNS = {
    ObservationType.show,
    ObservationType.fizzing,
    ObservationType.bubbling,
    ObservationType.rolling,
    ObservationType.crashing,
    ObservationType.slick,
    ObservationType.clouding,
}


class SessionPlanService:
    """Assembles a live recommendation context from a session's logged evidence.

    This is the bridge between raw logs (water readings, weather snapshots,
    observations, venue history and recent catches) and the deterministic
    :class:`RecommendationEngine`. It only ever passes through what has actually
    been logged; anything missing is left as ``None`` so the engine reports it as
    a data gap rather than inventing a value.
    """

    def __init__(self, db: Session, engine: RecommendationEngine | None = None) -> None:
        self.db = db
        self.engine = engine or RecommendationEngine()

    def build_context(self, session: AnglingSessionRecord) -> RecommendationContext:
        reference_time = session.started_at or datetime.now(UTC)

        water_temp, water_temp_trend, dissolved_oxygen = self._water_signals(session.id)
        weather = self._latest_weather(session.id)
        observations, liners, spawning = self._observation_signals(session.id)

        air_temp = weather.air_temp_c if weather else None
        pressure = weather.pressure_hpa if weather else None
        pressure_trend = weather.pressure_trend_hpa_3h if weather else None
        cloud_cover = weather.cloud_cover_percent if weather else None
        wind_speed = weather.wind_speed_mps if weather else None
        wind_label = weather.wind_direction_label if weather else None
        moon_phase = weather.moon_phase if weather else None

        return RecommendationContext(
            session_id=session.id,
            water_temp_c=water_temp,
            water_temp_trend_c_24h=water_temp_trend,
            dissolved_oxygen_mg_l=dissolved_oxygen,
            air_temp_c=air_temp,
            venue_history_sessions=self._venue_session_count(session.venue_id),
            recent_catch_count_7d=self._recent_catch_count(session.venue_id, reference_time),
            wind_speed_mps=wind_speed,
            wind_direction_label=wind_label,
            pressure_hpa=pressure,
            pressure_trend_hpa_3h=pressure_trend,
            cloud_cover_percent=cloud_cover,
            month=reference_time.month,
            local_hour=reference_time.hour,
            moon_phase=moon_phase,
            angling_pressure_count=session.angling_pressure_count,
            observations=observations,
            liners_without_takes=liners,
            spawning_indicators=spawning,
        )

    def generate_plan(self, session: AnglingSessionRecord) -> tuple[RecommendationResult, Recommendation]:
        context = self.build_context(session)
        result = self.engine.generate(context)
        recommendation = Recommendation(
            session_id=session.id,
            location_score=result.location_score,
            feeding_window_score=result.feeding_window_score,
            presentation_fit_score=result.presentation_fit_score,
            oxygen_comfort_score=result.oxygen_comfort_score,
            pressure_risk_score=result.pressure_risk_score,
            confidence_score=result.confidence_score,
            recommended_zone=result.recommended_zone,
            recommended_depth_or_layer=result.recommended_depth_or_layer,
            recommended_tactic=result.recommended_tactic,
            recommended_baiting_level=result.recommended_baiting_level,
            explanation=result.recommendation_summary,
            data_gaps=result.data_gaps,
            evidence_summary=result.evidence_summary,
            alternative_plan=result.alternative_plan,
            seasonal_context=result.seasonal_context,
            barometric_note=result.barometric_note,
            prime_feeding_windows=result.prime_feeding_windows,
            priority_actions=result.priority_actions,
        )
        return result, recommendation

    # ------------------------------------------------------------------
    # Evidence gathering
    # ------------------------------------------------------------------
    def _water_signals(self, session_id: str) -> tuple[float | None, float | None, float | None]:
        readings = self.db.scalars(
            select(WaterReadingRecord)
            .where(WaterReadingRecord.session_id == session_id)
            .order_by(WaterReadingRecord.read_at.desc())
        ).all()

        latest_temp: float | None = None
        dissolved_oxygen: float | None = None
        for reading in readings:
            if latest_temp is None and reading.water_temp_c is not None:
                latest_temp = reading.water_temp_c
            if dissolved_oxygen is None and reading.dissolved_oxygen_mg_l is not None:
                dissolved_oxygen = reading.dissolved_oxygen_mg_l
            if latest_temp is not None and dissolved_oxygen is not None:
                break

        trend = self._water_temp_trend(
            [(reading.read_at, reading.water_temp_c) for reading in readings if reading.water_temp_c is not None]
        )
        return latest_temp, trend, dissolved_oxygen

    @staticmethod
    def _water_temp_trend(samples: list[tuple[datetime, float]]) -> float | None:
        """Estimate the 24h water-temperature change from the two latest readings."""
        if len(samples) < 2:
            return None
        (latest_at, latest_temp), (previous_at, previous_temp) = samples[0], samples[1]
        delta = latest_temp - previous_temp
        gap_hours = abs((latest_at - previous_at).total_seconds()) / 3600
        if gap_hours <= 0:
            return round(delta, 2)
        # Normalise to a 24h rate but cap scaling so a tiny gap cannot explode the trend.
        scale = min(24.0 / gap_hours, 4.0)
        return round(delta * scale, 2)

    def _latest_weather(self, session_id: str) -> WeatherSnapshotRecord | None:
        return self.db.scalars(
            select(WeatherSnapshotRecord)
            .where(WeatherSnapshotRecord.session_id == session_id)
            .order_by(WeatherSnapshotRecord.captured_at.desc())
            .limit(1)
        ).first()

    def _observation_signals(self, session_id: str) -> tuple[list[ObservationSignal], bool, bool]:
        records = self.db.scalars(
            select(ObservationRecord).where(ObservationRecord.session_id == session_id)
        ).all()

        counts: dict[ObservationType, int] = {}
        liners = False
        spawning = False
        for record in records:
            try:
                observation_type = ObservationType(record.observation_type)
            except ValueError:
                observation_type = ObservationType.other
            counts[observation_type] = counts.get(observation_type, 0) + 1
            if observation_type == ObservationType.liner:
                liners = True
            if observation_type == ObservationType.spawning_indicator:
                spawning = True

        signals = [
            ObservationSignal(observation_type=observation_type, count=count)
            for observation_type, count in counts.items()
        ]
        return signals, liners, spawning

    def _venue_session_count(self, venue_id: str) -> int:
        count = self.db.scalar(
            select(func.count()).select_from(AnglingSessionRecord).where(AnglingSessionRecord.venue_id == venue_id)
        )
        return int(count or 0)

    def _recent_catch_count(self, venue_id: str, reference_time: datetime) -> int:
        window_start = reference_time - timedelta(days=7)
        session_ids = select(AnglingSessionRecord.id).where(AnglingSessionRecord.venue_id == venue_id)
        count = self.db.scalar(
            select(func.count())
            .select_from(CatchRecord)
            .where(CatchRecord.session_id.in_(session_ids))
            .where(CatchRecord.caught_at >= window_start)
        )
        return int(count or 0)
