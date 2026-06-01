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
