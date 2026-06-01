from app.services.weather_service import WeatherLookupRequest, WeatherProvider, WeatherService


class _StaticProvider(WeatherProvider):
    def __init__(
        self,
        name: str,
        data: dict[str, object],
        data_gaps: list[str] | None = None,
    ) -> None:
        self.name = name
        self._data = data
        self._data_gaps = data_gaps or []

    def get_snapshot(self, request: WeatherLookupRequest) -> dict[str, object]:
        return {
            "source": self.name,
            "data": self._data,
            "data_gaps": self._data_gaps,
        }


def test_weather_service_keeps_provider_evidence_and_gaps() -> None:
    snapshot = WeatherService(
        providers=[
            _StaticProvider("open_meteo", {"air_temp_c": 12.5, "pressure_hpa": 1008}),
            _StaticProvider("met_office", {}, ["MET_OFFICE_API_KEY is not configured."]),
        ]
    ).get_snapshot(WeatherLookupRequest(latitude=52.3, longitude=-1.2, location_label="test lake"))

    assert snapshot["source"] == "multi_provider"
    assert snapshot["requested_location"]["location_label"] == "test lake"
    assert snapshot["air_temp_c"] == 12.5
    assert snapshot["pressure_hpa"] == 1008
    assert len(snapshot["providers"]) == 2
    assert "MET_OFFICE_API_KEY is not configured." in snapshot["data_gaps"]
