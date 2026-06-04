from app.rules.recommendation_engine import RecommendationEngine
from app.schemas.domain import ObservationSignal, ObservationType, RecommendationContext


def test_missing_water_temperature_caps_confidence_at_65_when_history_is_sufficient() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=None,
            dissolved_oxygen_mg_l=8.0,
            air_temp_c=12.0,
        )
    )

    assert result.confidence_score <= 65
    assert any("Water temperature is missing" in gap for gap in result.data_gaps)


def test_low_history_caps_confidence_at_50() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=4,
            water_temp_c=13.0,
            dissolved_oxygen_mg_l=8.0,
        )
    )

    assert result.confidence_score <= 50
    assert any("fewer than 10 sessions" in gap for gap in result.data_gaps)


def test_missing_dissolved_oxygen_in_hot_conditions_caps_confidence() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=15,
            water_temp_c=21.0,
            air_temp_c=27.0,
            dissolved_oxygen_mg_l=None,
        )
    )

    assert result.confidence_score <= 65
    assert any("Dissolved oxygen is missing" in gap for gap in result.data_gaps)


def test_cold_water_recommends_low_baiting() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=6.5,
            dissolved_oxygen_mg_l=8.5,
        )
    )

    assert result.recommended_baiting_level == "low"


def test_shows_away_from_rods_suggest_mobile_move() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=15.0,
            dissolved_oxygen_mg_l=7.0,
            observations=[
                ObservationSignal(
                    observation_type=ObservationType.show,
                    count=2,
                    away_from_current_rods=True,
                )
            ],
        )
    )

    assert "mobile rod" in result.recommended_tactic


def test_falling_pressure_lifts_feeding_window_and_sets_note() -> None:
    falling = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=15.0,
            dissolved_oxygen_mg_l=7.0,
            pressure_hpa=1004.0,
            pressure_trend_hpa_3h=-2.0,
        )
    )
    steady = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=15.0,
            dissolved_oxygen_mg_l=7.0,
            pressure_hpa=1004.0,
            pressure_trend_hpa_3h=0.0,
        )
    )

    assert falling.feeding_window_score > steady.feeding_window_score
    assert falling.barometric_note is not None
    assert "front" in falling.barometric_note.lower()


def test_missing_pressure_is_reported_as_a_data_gap() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=15.0,
            dissolved_oxygen_mg_l=7.0,
        )
    )

    assert any("Barometric pressure" in gap for gap in result.data_gaps)


def test_winter_season_lowers_feeding_window_and_prioritises_location() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=6.0,
            dissolved_oxygen_mg_l=9.0,
            month=1,
        )
    )

    assert result.seasonal_context is not None and "Winter" in result.seasonal_context
    assert result.prime_feeding_windows
    assert any("locat" in action.lower() for action in result.priority_actions)


def test_autumn_season_lifts_feeding_window_versus_no_season() -> None:
    autumn = RecommendationEngine().generate(
        RecommendationContext(venue_history_sessions=12, water_temp_c=14.0, dissolved_oxygen_mg_l=8.0, month=10)
    )
    no_season = RecommendationEngine().generate(
        RecommendationContext(venue_history_sessions=12, water_temp_c=14.0, dissolved_oxygen_mg_l=8.0)
    )

    assert autumn.feeding_window_score > no_season.feeding_window_score


def test_first_or_last_light_lifts_feeding_window() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=15.0,
            dissolved_oxygen_mg_l=7.0,
            is_first_or_last_light=True,
        )
    )

    assert any("low-light" in action.lower() for action in result.priority_actions)


def test_rising_water_temperature_trend_is_a_positive_trigger() -> None:
    rising = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12, water_temp_c=12.0, dissolved_oxygen_mg_l=8.0, water_temp_trend_c_24h=1.5
        )
    )
    falling = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12, water_temp_c=12.0, dissolved_oxygen_mg_l=8.0, water_temp_trend_c_24h=-1.5
        )
    )

    assert rising.feeding_window_score > falling.feeding_window_score


def test_high_pressure_in_warm_weather_suggests_higher_presentation() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=18.0,
            dissolved_oxygen_mg_l=8.0,
            month=7,
            pressure_hpa=1030.0,
            pressure_trend_hpa_3h=0.0,
        )
    )

    assert "zig" in result.recommended_depth_or_layer.lower() or "upper" in result.recommended_depth_or_layer.lower()


def test_cold_wind_in_spring_suggests_back_bank() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=10.0,
            dissolved_oxygen_mg_l=9.0,
            month=3,
            wind_direction_label="NE",
        )
    )

    assert any("back bank" in action.lower() for action in result.priority_actions)


def test_spawning_indicator_action_is_surfaced_first() -> None:
    result = RecommendationEngine().generate(
        RecommendationContext(
            venue_history_sessions=12,
            water_temp_c=18.0,
            dissolved_oxygen_mg_l=8.0,
            month=5,
            spawning_indicators=True,
            wind_has_pushed_hours=5,
        )
    )

    assert result.priority_actions
    assert "welfare" in result.priority_actions[0].lower()
    assert result.confidence_score <= 40
