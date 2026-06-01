# 05 Database Schema

Phase A defined Pydantic schemas and a PostgreSQL-ready domain model. Phase B now includes both a SQLAlchemy JSON resource bridge and normalized tables for the MVP evidence path.

## Current Migration

`json_resource_records`

- resource_type
- id
- payload
- created_at
- updated_at

This table is an MVP persistence bridge. It is not the final analytical schema.

## Current Normalized Tables

Implemented by migrations `20260601_0002` and `20260601_0003`:

- venues
- swims
- spots
- sessions
- rod_sets
- bait_applications
- observations
- water_readings
- weather_snapshots
- bite_events
- catches
- blank_intervals
- recommendations
- recommendation_outcomes

These tables support Lake Brain summaries, sample-size caution, catch/blank counting, observation-led recommendations, water/weather evidence and future effort-normalized reporting.

## Core Tables

### users

- id
- display_name
- email
- created_at
- privacy_settings

### venues

- id
- owner_user_id
- name
- type
- location_label
- approximate_latitude
- approximate_longitude
- acreage
- max_depth_m
- average_depth_m
- stock_notes
- rules_notes
- privacy_level
- created_at
- updated_at

### swims

- id
- venue_id
- name
- bank_aspect
- wind_exposure_notes
- access_notes
- pressure_rating
- privacy_level
- created_at
- updated_at

### spots

- id
- venue_id
- swim_id
- name
- latitude
- longitude
- distance_wraps
- distance_m
- depth_m
- substrate
- feature_type
- weed_density
- confidence_level
- notes

### sessions

- id
- user_id
- venue_id
- swim_id
- started_at
- ended_at
- session_type
- status
- target_species
- target_fish_notes
- angling_pressure_count
- notes

### rod_sets

- id
- session_id
- rod_number
- spot_id
- cast_at
- retrieved_at
- distance_wraps
- depth_m
- presentation_layer
- rig_type
- hook_size
- hooklink
- lead_setup
- hookbait_type
- hookbait_colour
- hookbait_size_mm
- hookbait_buoyancy
- notes
- computed_rod_hours

### bait_applications

- id
- session_id
- rod_set_id nullable
- spot_id nullable
- applied_at
- bait_type
- bait_category
- quantity_value
- quantity_unit
- spread_pattern
- notes

### observations

- id
- session_id
- observed_at
- observation_type
- swim_id nullable
- spot_id nullable
- confidence_level
- notes

### water_readings

- id
- session_id
- read_at
- water_temp_c
- dissolved_oxygen_mg_l nullable
- ph nullable
- turbidity_ntu nullable
- conductivity nullable
- depth_m nullable
- reading_location_notes

### weather_snapshots

- id
- session_id
- captured_at
- source
- air_temp_c
- pressure_hpa
- pressure_trend_hpa_3h
- wind_speed_mps
- wind_direction_degrees
- wind_direction_label
- rainfall_mm
- cloud_cover_percent
- humidity_percent
- uv_index nullable
- moon_phase nullable
- sunrise_at nullable
- sunset_at nullable

### bite_events

- id
- session_id
- rod_set_id
- occurred_at
- event_type
- notes

### catches

- id
- session_id
- rod_set_id
- bite_event_id nullable
- species
- weight_lb
- weight_oz
- length_cm nullable
- caught_at
- photo_url nullable
- fish_condition_notes
- returned_safely
- notes

### blank_intervals

- id
- session_id
- started_at
- ended_at
- rods_active_count
- notes

### recommendations

- id
- session_id
- generated_at
- location_score
- feeding_window_score
- presentation_fit_score
- oxygen_comfort_score
- pressure_risk_score
- confidence_score
- recommended_zone
- recommended_depth_or_layer
- recommended_tactic
- recommended_baiting_level
- explanation
- data_gaps
- evidence_summary
- alternative_plan

### recommendation_outcomes

- id
- recommendation_id
- session_id
- outcome_type
- reviewed_at
- notes

## PostGIS And pgvector Notes

- `spots.latitude` and `spots.longitude` can later become a PostGIS geometry column.
- Approximate venue coordinates should remain optional and private by default.
- RAG documents and embeddings can use pgvector with owner and venue access controls.
