from app.routes._crud import build_crud_router
from app.schemas.domain import RichWeatherCondition
from app.services.condition_service import WeatherConditionService
from app.services.weather_service import WeatherLookupRequest, WeatherService
from app.schemas.domain import WeatherSnapshot

router = build_crud_router(WeatherSnapshot, "weather-snapshots")


@router.get("/live/lookup")
def lookup_live_weather(
    latitude: float | None = None,
    longitude: float | None = None,
    location_label: str | None = None,
) -> dict[str, object]:
    return WeatherService().get_snapshot(
        WeatherLookupRequest(
            latitude=latitude,
            longitude=longitude,
            location_label=location_label,
        )
    )


@router.get("/live/conditions", response_model=RichWeatherCondition)
def lookup_live_conditions(
    latitude: float | None = None,
    longitude: float | None = None,
    location_label: str | None = None,
) -> RichWeatherCondition:
    snapshot = WeatherService().get_snapshot(
        WeatherLookupRequest(
            latitude=latitude,
            longitude=longitude,
            location_label=location_label,
        )
    )
    return WeatherConditionService().enrich_snapshot(snapshot)
