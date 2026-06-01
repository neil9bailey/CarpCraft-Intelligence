from app.routes._crud import build_crud_router
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
