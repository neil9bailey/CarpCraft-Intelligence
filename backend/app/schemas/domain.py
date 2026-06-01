from __future__ import annotations

from datetime import UTC, datetime
from enum import Enum
from uuid import uuid4

from pydantic import BaseModel, ConfigDict, Field


def new_id() -> str:
    return str(uuid4())


def now_utc() -> datetime:
    return datetime.now(UTC)


class PrivacyLevel(str, Enum):
    private = "private"
    shared_with_me = "shared_with_me"
    team_private = "team_private"
    public = "public"


class VenueType(str, Enum):
    lake = "lake"
    pit = "pit"
    river = "river"
    canal = "canal"
    reservoir = "reservoir"
    syndicate = "syndicate"
    day_ticket = "day_ticket"
    unknown = "unknown"


class Substrate(str, Enum):
    gravel = "gravel"
    silt = "silt"
    clay = "clay"
    chod = "chod"
    weed = "weed"
    sand = "sand"
    leaves = "leaves"
    mussel = "mussel"
    unknown = "unknown"


class FeatureType(str, Enum):
    bar = "bar"
    gully = "gully"
    margin = "margin"
    pads = "pads"
    reedline = "reedline"
    snag = "snag"
    open_water = "open_water"
    plateau = "plateau"
    dropoff = "dropoff"
    channel = "channel"
    inflow = "inflow"
    outflow = "outflow"
    unknown = "unknown"


class PresentationLayer(str, Enum):
    bottom = "bottom"
    low = "low"
    mid = "mid"
    upper = "upper"
    surface = "surface"
    margin = "margin"
    unknown = "unknown"


class BaitCategory(str, Enum):
    boilie = "boilie"
    pellet = "pellet"
    particle = "particle"
    groundbait = "groundbait"
    liquid = "liquid"
    maggot = "maggot"
    worm = "worm"
    corn = "corn"
    mixed = "mixed"
    none = "none"
    unknown = "unknown"


class SpreadPattern(str, Enum):
    tight = "tight"
    spread = "spread"
    line = "line"
    pouch = "pouch"
    single = "single"
    pva = "pva"
    spod = "spod"
    spomb = "spomb"
    unknown = "unknown"


class ObservationType(str, Enum):
    show = "show"
    fizzing = "fizzing"
    liner = "liner"
    bubbling = "bubbling"
    rolling = "rolling"
    crashing = "crashing"
    bird_activity = "bird_activity"
    slick = "slick"
    clouding = "clouding"
    weed_movement = "weed_movement"
    angler_pressure = "angler_pressure"
    noise = "noise"
    spawning_indicator = "spawning_indicator"
    other = "other"


class BiteEventType(str, Enum):
    liner = "liner"
    single_bleep = "single_bleep"
    dropback = "dropback"
    take = "take"
    lost_fish = "lost_fish"
    landed = "landed"
    aborted = "aborted"
    unknown = "unknown"


class RecommendationOutcomeType(str, Enum):
    catch = "catch"
    bite = "bite"
    liner = "liner"
    blank = "blank"
    user_ignored = "user_ignored"
    partial_success = "partial_success"
    unknown = "unknown"


class ApiModel(BaseModel):
    model_config = ConfigDict(from_attributes=True, use_enum_values=True)


class PrivacySettings(ApiModel):
    default_privacy_level: PrivacyLevel = PrivacyLevel.private
    precise_location_enabled: bool = False
    photo_uploads_enabled: bool = False
    ai_processing_enabled: bool = False


class User(ApiModel):
    id: str = Field(default_factory=new_id)
    display_name: str
    email: str
    created_at: datetime = Field(default_factory=now_utc)
    privacy_settings: PrivacySettings = Field(default_factory=PrivacySettings)


class Venue(ApiModel):
    id: str = Field(default_factory=new_id)
    owner_user_id: str | None = None
    name: str
    type: VenueType = VenueType.unknown
    location_label: str | None = None
    approximate_latitude: float | None = None
    approximate_longitude: float | None = None
    acreage: float | None = None
    max_depth_m: float | None = None
    average_depth_m: float | None = None
    stock_notes: str | None = None
    rules_notes: str | None = None
    privacy_level: PrivacyLevel = PrivacyLevel.private
    created_at: datetime = Field(default_factory=now_utc)
    updated_at: datetime = Field(default_factory=now_utc)


class Swim(ApiModel):
    id: str = Field(default_factory=new_id)
    venue_id: str
    name: str
    bank_aspect: str | None = None
    wind_exposure_notes: str | None = None
    access_notes: str | None = None
    pressure_rating: int | None = Field(default=None, ge=0, le=10)
    privacy_level: PrivacyLevel = PrivacyLevel.private
    created_at: datetime = Field(default_factory=now_utc)
    updated_at: datetime = Field(default_factory=now_utc)


class Spot(ApiModel):
    id: str = Field(default_factory=new_id)
    venue_id: str
    swim_id: str | None = None
    name: str
    latitude: float | None = None
    longitude: float | None = None
    distance_wraps: float | None = None
    distance_m: float | None = None
    depth_m: float | None = None
    substrate: Substrate = Substrate.unknown
    feature_type: FeatureType = FeatureType.unknown
    weed_density: int | None = Field(default=None, ge=0, le=10)
    confidence_level: int | None = Field(default=None, ge=0, le=100)
    notes: str | None = None


class Session(ApiModel):
    id: str = Field(default_factory=new_id)
    user_id: str | None = None
    venue_id: str
    swim_id: str | None = None
    started_at: datetime | None = None
    ended_at: datetime | None = None
    session_type: str | None = None
    status: str = "planned"
    target_species: str = "carp"
    target_fish_notes: str | None = None
    angling_pressure_count: int | None = Field(default=None, ge=0)
    notes: str | None = None


class RodSet(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    rod_number: int = Field(ge=1)
    spot_id: str | None = None
    cast_at: datetime | None = None
    retrieved_at: datetime | None = None
    distance_wraps: float | None = None
    depth_m: float | None = None
    presentation_layer: PresentationLayer = PresentationLayer.unknown
    rig_type: str | None = None
    hook_size: str | None = None
    hooklink: str | None = None
    lead_setup: str | None = None
    hookbait_type: str | None = None
    hookbait_colour: str | None = None
    hookbait_size_mm: float | None = None
    hookbait_buoyancy: str | None = None
    notes: str | None = None
    computed_rod_hours: float | None = Field(default=None, ge=0)


class BaitApplication(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    rod_set_id: str | None = None
    spot_id: str | None = None
    applied_at: datetime = Field(default_factory=now_utc)
    bait_type: str | None = None
    bait_category: BaitCategory = BaitCategory.unknown
    quantity_value: float | None = Field(default=None, ge=0)
    quantity_unit: str | None = None
    spread_pattern: SpreadPattern = SpreadPattern.unknown
    notes: str | None = None


class Observation(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    observed_at: datetime = Field(default_factory=now_utc)
    observation_type: ObservationType = ObservationType.other
    swim_id: str | None = None
    spot_id: str | None = None
    confidence_level: int | None = Field(default=None, ge=0, le=100)
    notes: str | None = None


class WaterReading(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    read_at: datetime = Field(default_factory=now_utc)
    water_temp_c: float | None = None
    dissolved_oxygen_mg_l: float | None = None
    ph: float | None = None
    turbidity_ntu: float | None = None
    conductivity: float | None = None
    depth_m: float | None = None
    reading_location_notes: str | None = None


class WeatherSnapshot(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    captured_at: datetime = Field(default_factory=now_utc)
    source: str = "manual"
    air_temp_c: float | None = None
    pressure_hpa: float | None = None
    pressure_trend_hpa_3h: float | None = None
    wind_speed_mps: float | None = None
    wind_direction_degrees: float | None = None
    wind_direction_label: str | None = None
    rainfall_mm: float | None = None
    cloud_cover_percent: int | None = Field(default=None, ge=0, le=100)
    humidity_percent: int | None = Field(default=None, ge=0, le=100)
    uv_index: float | None = None
    moon_phase: str | None = None
    sunrise_at: datetime | None = None
    sunset_at: datetime | None = None


class BiteEvent(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    rod_set_id: str | None = None
    occurred_at: datetime = Field(default_factory=now_utc)
    event_type: BiteEventType = BiteEventType.unknown
    notes: str | None = None


class Catch(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    rod_set_id: str | None = None
    bite_event_id: str | None = None
    species: str = "carp"
    weight_lb: int | None = Field(default=None, ge=0)
    weight_oz: int | None = Field(default=None, ge=0, le=15)
    length_cm: float | None = Field(default=None, ge=0)
    caught_at: datetime = Field(default_factory=now_utc)
    photo_url: str | None = None
    fish_condition_notes: str | None = None
    returned_safely: bool = True
    notes: str | None = None


class BlankInterval(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    started_at: datetime
    ended_at: datetime
    rods_active_count: int = Field(ge=0)
    notes: str | None = None


class Recommendation(ApiModel):
    id: str = Field(default_factory=new_id)
    session_id: str
    generated_at: datetime = Field(default_factory=now_utc)
    location_score: int = Field(ge=0, le=100)
    feeding_window_score: int = Field(ge=0, le=100)
    presentation_fit_score: int = Field(ge=0, le=100)
    oxygen_comfort_score: int = Field(ge=0, le=100)
    pressure_risk_score: int = Field(ge=0, le=100)
    confidence_score: int = Field(ge=0, le=100)
    recommended_zone: str
    recommended_depth_or_layer: str
    recommended_tactic: str
    recommended_baiting_level: str
    explanation: str
    data_gaps: list[str] = Field(default_factory=list)
    evidence_summary: list[str] = Field(default_factory=list)
    alternative_plan: str


class RecommendationOutcome(ApiModel):
    id: str = Field(default_factory=new_id)
    recommendation_id: str
    session_id: str
    outcome_type: RecommendationOutcomeType = RecommendationOutcomeType.unknown
    reviewed_at: datetime = Field(default_factory=now_utc)
    notes: str | None = None


class ObservationSignal(ApiModel):
    observation_type: ObservationType
    count: int = Field(default=1, ge=0)
    away_from_current_rods: bool = False
    notes: str | None = None


class RecommendationContext(ApiModel):
    session_id: str | None = None
    water_temp_c: float | None = None
    dissolved_oxygen_mg_l: float | None = None
    air_temp_c: float | None = None
    venue_history_sessions: int = Field(default=0, ge=0)
    wind_speed_mps: float | None = None
    wind_has_pushed_hours: float | None = Field(default=None, ge=0)
    weed_density: int | None = Field(default=None, ge=0, le=10)
    angling_pressure_count: int | None = Field(default=None, ge=0)
    observations: list[ObservationSignal] = Field(default_factory=list)
    liners_without_takes: bool = False
    spawning_indicators: bool = False
    current_rods_zone: str | None = None


class RecommendationResult(ApiModel):
    recommendation_summary: str
    location_score: int = Field(ge=0, le=100)
    feeding_window_score: int = Field(ge=0, le=100)
    presentation_fit_score: int = Field(ge=0, le=100)
    oxygen_comfort_score: int = Field(ge=0, le=100)
    pressure_risk_score: int = Field(ge=0, le=100)
    confidence_score: int = Field(ge=0, le=100)
    recommended_zone: str
    recommended_tactic: str
    recommended_baiting_level: str
    recommended_depth_or_layer: str
    evidence_summary: list[str]
    data_gaps: list[str]
    alternative_plan: str
    fish_welfare_warning: str | None = None
