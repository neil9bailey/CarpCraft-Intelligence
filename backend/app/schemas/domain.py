from __future__ import annotations

from datetime import UTC, datetime
from enum import Enum
from uuid import uuid4

from pydantic import BaseModel, ConfigDict, Field, model_validator


def new_id() -> str:
    return str(uuid4())


def now_utc() -> datetime:
    return datetime.now(UTC)


class PrivacyLevel(str, Enum):
    private = "private"
    shared_with_me = "shared_with_me"
    team_private = "team_private"
    public = "public"


class SharingScope(str, Enum):
    private = "private"
    trusted_team = "trusted_team"
    fishery_partner = "fishery_partner"
    public = "public"


class SourceAccessMode(str, Enum):
    official_partner_api = "official_partner_api"
    fishery_provided_link = "fishery_provided_link"
    public_official_page = "public_official_page"
    public_directory = "public_directory"
    user_supplied_link = "user_supplied_link"
    manual_review = "manual_review"
    blocked = "blocked"


class FisheryProfileStatus(str, Enum):
    draft = "draft"
    needs_review = "needs_review"
    source_verified = "source_verified"
    partner_live = "partner_live"


class CaptureCategory(str, Enum):
    location = "location"
    swim = "swim"
    lake_feature = "lake_feature"
    catch = "catch"
    rig = "rig"
    bait = "bait"
    depth = "depth"
    map = "map"
    weed = "weed"
    water_condition = "water_condition"
    rule_notice = "rule_notice"
    other = "other"


class ImageAnnotationType(str, Enum):
    marker = "marker"
    distance = "distance"
    depth = "depth"
    feature = "feature"
    weed = "weed"
    bottom = "bottom"
    rig = "rig"
    catch_point = "catch_point"
    swim_boundary = "swim_boundary"
    cast_line = "cast_line"


class BottomCondition(str, Enum):
    silt = "silt"
    gravel = "gravel"
    smooth_clay = "smooth_clay"
    sand = "sand"
    chod = "chod"
    clear_hard = "clear_hard"
    leaves = "leaves"
    mussel = "mussel"
    debris = "debris"
    unknown = "unknown"


class WeedCondition(str, Enum):
    none = "none"
    silk_weed = "silk_weed"
    canadian_pond_weed = "canadian_pond_weed"
    blanket_weed = "blanket_weed"
    milfoil = "milfoil"
    hornwort = "hornwort"
    lilies = "lilies"
    reeds = "reeds"
    mixed = "mixed"
    unknown = "unknown"


class AlgaeCondition(str, Enum):
    none = "none"
    light_bloom = "light_bloom"
    moderate_bloom = "moderate_bloom"
    heavy_bloom = "heavy_bloom"
    blue_green_suspected = "blue_green_suspected"
    unknown = "unknown"


class WeatherConditionKind(str, Enum):
    clear = "clear"
    sunny = "sunny"
    partly_cloudy = "partly_cloudy"
    cloudy = "cloudy"
    overcast = "overcast"
    mist = "mist"
    fog = "fog"
    drizzle = "drizzle"
    light_rain = "light_rain"
    moderate_rain = "moderate_rain"
    heavy_rain = "heavy_rain"
    storm = "storm"
    hail = "hail"
    sleet = "sleet"
    snow = "snow"
    unknown = "unknown"


class MCPAgentRunStatus(str, Enum):
    queued = "queued"
    running = "running"
    completed = "completed"
    failed = "failed"
    blocked = "blocked"


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


class VenueSourceEvidence(ApiModel):
    source_name: str
    source_type: str
    url: str
    title: str
    summary: str
    confidence: int = Field(ge=0, le=100)
    attribution_required: bool = False
    usage_notes: str | None = None


class VenueMapAsset(ApiModel):
    title: str
    url: str
    asset_type: str
    notes: str | None = None
    license_status: str = "link_only"
    cache_allowed: bool = False
    attribution: str | None = None


class VenueExternalPlace(ApiModel):
    source_name: str
    place_id: str | None = None
    display_name: str | None = None
    formatted_address: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    google_maps_uri: str | None = None
    website_uri: str | None = None
    confidence: int = Field(default=0, ge=0, le=100)


class VenueConnectorStatus(ApiModel):
    connector_name: str
    display_name: str
    status: str
    summary: str
    evidence_count: int = Field(default=0, ge=0)
    data_gaps: list[str] = Field(default_factory=list)


class VenueNewsItem(ApiModel):
    title: str
    published_on: str | None = None
    summary: str
    url: str
    source_name: str


class VenueSwimIntelligence(ApiModel):
    name: str
    acreage: float | None = None
    swim_count: int | None = None
    stock_notes: str | None = None
    feature_notes: str | None = None
    depth_map_url: str | None = None
    source_url: str


class VenueWeatherIntelligence(ApiModel):
    source: str
    air_temp_c: float | None = None
    pressure_hpa: float | None = None
    wind_speed_mps: float | None = None
    wind_direction_degrees: float | None = None
    rainfall_mm: float | None = None
    humidity_percent: float | None = None
    data_gaps: list[str] = Field(default_factory=list)


class VenueIntelligenceReport(ApiModel):
    query: str
    matched_key: str
    confidence_score: int = Field(ge=0, le=100)
    suggested_venue: Venue
    summary: str
    external_place: VenueExternalPlace | None = None
    swims: list[VenueSwimIntelligence] = Field(default_factory=list)
    map_assets: list[VenueMapAsset] = Field(default_factory=list)
    news_items: list[VenueNewsItem] = Field(default_factory=list)
    catch_reports: list[VenueNewsItem] = Field(default_factory=list)
    source_evidence: list[VenueSourceEvidence] = Field(default_factory=list)
    connector_statuses: list[VenueConnectorStatus] = Field(default_factory=list)
    weather: VenueWeatherIntelligence | None = None
    licensing_notes: list[str] = Field(default_factory=list)
    data_gaps: list[str] = Field(default_factory=list)
    ethical_warnings: list[str] = Field(default_factory=list)


class FisheryProfileSource(ApiModel):
    source_name: str
    source_kind: str
    access_mode: SourceAccessMode = SourceAccessMode.manual_review
    url: str
    title: str
    summary: str
    confidence: int = Field(default=0, ge=0, le=100)
    retrieved_at: datetime = Field(default_factory=now_utc)
    attribution_required: bool = True
    cache_allowed: bool = False
    data_rights_notes: str | None = None


class BookingOption(ApiModel):
    platform_name: str
    booking_url: str | None = None
    cost_summary: str | None = None
    price_from_gbp: float | None = Field(default=None, ge=0)
    price_to_gbp: float | None = Field(default=None, ge=0)
    availability_notes: str | None = None
    source_url: str | None = None
    requires_partner_confirmation: bool = True


class FisheryLakeProfile(ApiModel):
    name: str
    acreage: float | None = Field(default=None, ge=0)
    swim_count: int | None = Field(default=None, ge=0)
    average_depth_m: float | None = Field(default=None, ge=0)
    max_depth_m: float | None = Field(default=None, ge=0)
    map_asset_url: str | None = None
    depth_map_url: str | None = None
    source_url: str | None = None
    known_swims: list[str] = Field(default_factory=list)
    feature_notes: str | None = None
    stock_notes: str | None = None


class FisheryProfileSection(ApiModel):
    category: str
    title: str
    summary: str | None = None
    items: list[str] = Field(default_factory=list)
    source_urls: list[str] = Field(default_factory=list)
    confidence: int = Field(default=0, ge=0, le=100)


class FisheryProfile(ApiModel):
    id: str = Field(default_factory=new_id)
    owner_user_id: str | None = None
    venue_id: str | None = None
    display_name: str
    slug: str
    location_label: str | None = None
    approximate_latitude: float | None = None
    approximate_longitude: float | None = None
    description: str | None = None
    costs_notes: str | None = None
    how_to_book_notes: str | None = None
    access_notes: list[str] = Field(default_factory=list)
    opening_times_notes: list[str] = Field(default_factory=list)
    gate_closure_notes: list[str] = Field(default_factory=list)
    parking_notes: list[str] = Field(default_factory=list)
    facilities: list[str] = Field(default_factory=list)
    rules: list[str] = Field(default_factory=list)
    booking_options: list[BookingOption] = Field(default_factory=list)
    lakes: list[FisheryLakeProfile] = Field(default_factory=list)
    sections: list[FisheryProfileSection] = Field(default_factory=list)
    latest_news: list[VenueNewsItem] = Field(default_factory=list)
    catch_reports: list[VenueNewsItem] = Field(default_factory=list)
    map_assets: list[VenueMapAsset] = Field(default_factory=list)
    sources: list[FisheryProfileSource] = Field(default_factory=list)
    profile_status: FisheryProfileStatus = FisheryProfileStatus.needs_review
    privacy_level: PrivacyLevel = PrivacyLevel.private
    sharing_scope: SharingScope = SharingScope.private
    public_sharing_consent: bool = False
    confidence_score: int = Field(default=0, ge=0, le=100)
    licensing_notes: list[str] = Field(default_factory=list)
    data_gaps: list[str] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=now_utc)
    updated_at: datetime = Field(default_factory=now_utc)

    @model_validator(mode="after")
    def require_public_consent(self) -> "FisheryProfile":
        privacy_level = getattr(self.privacy_level, "value", self.privacy_level)
        sharing_scope = getattr(self.sharing_scope, "value", self.sharing_scope)
        if (privacy_level == PrivacyLevel.public.value or sharing_scope == SharingScope.public.value) and not self.public_sharing_consent:
            raise ValueError("Public fishery profiles require explicit public_sharing_consent.")
        return self


class ImageAnnotation(ApiModel):
    id: str = Field(default_factory=new_id)
    annotation_type: ImageAnnotationType = ImageAnnotationType.marker
    label: str
    x1: float = Field(ge=0, le=1)
    y1: float = Field(ge=0, le=1)
    x2: float | None = Field(default=None, ge=0, le=1)
    y2: float | None = Field(default=None, ge=0, le=1)
    distance_yards: float | None = Field(default=None, ge=0)
    distance_wraps: float | None = Field(default=None, ge=0)
    depth_m: float | None = Field(default=None, ge=0)
    bottom_condition: BottomCondition | None = None
    weed_condition: WeedCondition | None = None
    notes: str | None = None
    confidence_level: int | None = Field(default=None, ge=0, le=100)


class CaptureAsset(ApiModel):
    id: str = Field(default_factory=new_id)
    owner_user_id: str | None = None
    venue_id: str | None = None
    swim_id: str | None = None
    spot_id: str | None = None
    session_id: str | None = None
    category: CaptureCategory = CaptureCategory.other
    file_uri: str
    thumbnail_uri: str | None = None
    file_name: str | None = None
    content_type: str | None = None
    caption: str | None = None
    captured_at: datetime = Field(default_factory=now_utc)
    latitude: float | None = None
    longitude: float | None = None
    precise_location_user_enabled: bool = False
    privacy_level: PrivacyLevel = PrivacyLevel.private
    sharing_scope: SharingScope = SharingScope.private
    public_sharing_consent: bool = False
    annotations: list[ImageAnnotation] = Field(default_factory=list)
    bottom_condition: BottomCondition = BottomCondition.unknown
    weed_conditions: list[WeedCondition] = Field(default_factory=list)
    algae_condition: AlgaeCondition = AlgaeCondition.unknown
    water_clarity_notes: str | None = None
    depth_m: float | None = Field(default=None, ge=0)
    distance_yards: float | None = Field(default=None, ge=0)
    distance_wraps: float | None = Field(default=None, ge=0)
    rig_notes: str | None = None
    bait_notes: str | None = None
    source_device: str | None = None
    created_at: datetime = Field(default_factory=now_utc)
    updated_at: datetime = Field(default_factory=now_utc)

    @model_validator(mode="after")
    def enforce_capture_privacy_choices(self) -> "CaptureAsset":
        if (self.latitude is not None or self.longitude is not None) and not self.precise_location_user_enabled:
            raise ValueError("Precise capture location requires precise_location_user_enabled=true.")
        privacy_level = getattr(self.privacy_level, "value", self.privacy_level)
        sharing_scope = getattr(self.sharing_scope, "value", self.sharing_scope)
        if (privacy_level == PrivacyLevel.public.value or sharing_scope == SharingScope.public.value) and not self.public_sharing_consent:
            raise ValueError("Public capture sharing requires explicit public_sharing_consent.")
        return self


class RichWeatherCondition(ApiModel):
    source: str = "multi_provider"
    requested_location: dict[str, object] = Field(default_factory=dict)
    captured_at: str | None = None
    air_temp_c: float | None = None
    approx_surface_temp_c: float | None = None
    approx_surface_temp_confidence: int = Field(default=0, ge=0, le=100)
    pressure_hpa: float | None = None
    pressure_trend_hpa_3h: float | None = None
    wind_speed_mps: float | None = None
    wind_direction_degrees: float | None = None
    wind_direction_label: str | None = None
    rainfall_mm: float | None = None
    rainfall_rate_mm_h: float | None = None
    precipitation_intensity: str | None = None
    cloud_cover_percent: int | None = Field(default=None, ge=0, le=100)
    humidity_percent: int | None = Field(default=None, ge=0, le=100)
    condition: WeatherConditionKind = WeatherConditionKind.unknown
    storm_risk: bool = False
    hail_risk: bool = False
    sleet_or_snow_risk: bool = False
    provider_count: int = Field(default=0, ge=0)
    provider_evidence: list[dict[str, object]] = Field(default_factory=list)
    approximation_notes: list[str] = Field(default_factory=list)
    data_gaps: list[str] = Field(default_factory=list)


class AIEvidenceItem(ApiModel):
    source_type: str
    source_id: str | None = None
    summary: str
    confidence: int = Field(default=0, ge=0, le=100)
    url: str | None = None


class AIIntelligenceBriefInput(ApiModel):
    session_id: str | None = None
    venue_id: str | None = None
    target_species: str = "carp"
    live_session_notes: str | None = None
    weather: RichWeatherCondition | None = None
    observations: list[str] = Field(default_factory=list)
    bottom_conditions: list[BottomCondition] = Field(default_factory=list)
    weed_conditions: list[WeedCondition] = Field(default_factory=list)
    recent_captures: list[CaptureAsset] = Field(default_factory=list)
    spawning_indicators: bool = False


class AIIntelligenceBrief(ApiModel):
    id: str = Field(default_factory=new_id)
    owner_user_id: str | None = None
    session_id: str | None = None
    generated_at: datetime = Field(default_factory=now_utc)
    confidence_score: int = Field(ge=0, le=100)
    headline: str
    recommendations: list[str]
    evidence: list[AIEvidenceItem] = Field(default_factory=list)
    data_gaps: list[str] = Field(default_factory=list)
    safety_warnings: list[str] = Field(default_factory=list)
    no_guarantee_notice: str = "This is a source-grounded watercraft brief, not a catch prediction or guarantee."


class MCPAgentRun(ApiModel):
    id: str = Field(default_factory=new_id)
    owner_user_id: str | None = None
    agent_name: str
    objective: str
    status: MCPAgentRunStatus = MCPAgentRunStatus.queued
    started_at: datetime | None = None
    ended_at: datetime | None = None
    input_summary: str | None = None
    output_summary: str | None = None
    evidence: list[AIEvidenceItem] = Field(default_factory=list)
    data_gaps: list[str] = Field(default_factory=list)
    requires_human_review: bool = True
    privacy_level: PrivacyLevel = PrivacyLevel.private
    sharing_scope: SharingScope = SharingScope.private
    created_at: datetime = Field(default_factory=now_utc)
    updated_at: datetime = Field(default_factory=now_utc)


class ExternalAIProviderStatus(ApiModel):
    provider_name: str
    configured: bool
    base_url: str
    summary: str
    data_gaps: list[str] = Field(default_factory=list)


class AnglingAIVenueResearchRequest(ApiModel):
    venue_name: str
    location: str | None = None
    target_species: str = "Carp"


class AnglingAISwimSelectorRequest(ApiModel):
    water_type: str = "commercial-stillwater"
    target_species: str = "Carp"
    wind_direction: str | None = None
    season: str | None = None
    venue_features: list[str] = Field(default_factory=list)


class AnglingAIWaterTempRequest(ApiModel):
    location: str
    water_type: str = "stillwater"


class AnglingAIWeatherRequest(ApiModel):
    location: str
    target_species: str = "Carp"


class AnglingAISolunarRequest(ApiModel):
    location: str
    days: int = Field(default=3, ge=1, le=14)


class AnglingAISpawnAlertRequest(ApiModel):
    water_temperature: float = Field(ge=0, le=40)
    species: str | None = None


class AnglingAIByelawCheckRequest(ApiModel):
    water_type: str = "stillwater"
    date: str | None = None
    species: str | None = None
    region: str | None = None


class AnglingAIBaitCalculatorRequest(ApiModel):
    duration_hours: float = Field(default=24, gt=0, le=168)
    target_species: list[str] = Field(default_factory=lambda: ["Carp"])
    methods: list[str] = Field(default_factory=lambda: ["boilie"])
    water_type: str = "commercial-stillwater"
    season: str | None = None


class AnglingAIRigBuilderRequest(ApiModel):
    target_species: str = "Carp"
    water_type: str = "commercial-stillwater"
    method: str = "method feeder"
    generate_image: bool = False


class AnglingAIFishDiseaseRequest(ApiModel):
    image_url: str
    context: str | None = None


class AnglingAILakeMapFromLocationRequest(ApiModel):
    lat: float
    lng: float
    name: str
    peg_count: int | None = Field(default=None, ge=0)
    amenities: list[str] = Field(default_factory=list)
    features: list[str] = Field(default_factory=list)


class AnglingAIVisionRequest(ApiModel):
    image_url: str
    prompt: str | None = None


class AnglingAIProviderResponse(ApiModel):
    provider_name: str = "AnglingAI"
    endpoint: str
    configured: bool
    status: str
    result: dict[str, object] | None = None
    text: str | None = None
    source_url: str = "https://anglingai.co.uk/docs"
    evidence: list[AIEvidenceItem] = Field(default_factory=list)
    data_gaps: list[str] = Field(default_factory=list)


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
