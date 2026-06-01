import httpx

from app.core.config import get_settings
from app.services.weather_service import MetOfficeWeatherProvider, WeatherLookupRequest, WeatherProvider, WeatherService


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


def test_met_office_provider_requests_bd1_and_normalizes_response(monkeypatch) -> None:
    get_settings.cache_clear()
    monkeypatch.setenv("MET_OFFICE_API_KEY", "test-key")
    captured_request = {}

    class Response:
        def raise_for_status(self) -> None:
            return None

        def json(self) -> dict[str, object]:
            return {
                "type": "FeatureCollection",
                "features": [
                    {
                        "type": "Feature",
                        "properties": {
                            "location": {"name": "Barby"},
                            "requestPointDistance": 3911.5,
                            "modelRunDate": "2026-06-01T16:00Z",
                            "timeSeries": [
                                {
                                    "time": "2026-06-01T16:00Z",
                                    "screenTemperature": 17.5,
                                    "mslp": 101060,
                                    "windSpeed10m": 2.83,
                                    "windDirectionFrom10m": 214,
                                    "totalPrecipAmount": 0.17,
                                    "precipitationRate": 0.28,
                                    "screenRelativeHumidity": 78.79,
                                    "significantWeatherCode": 10,
                                }
                            ],
                        },
                    }
                ],
            }

    def fake_get(url, params, headers, timeout):  # noqa: ANN001
        captured_request.update({"url": url, "params": params, "headers": headers, "timeout": timeout})
        return Response()

    monkeypatch.setattr(httpx, "get", fake_get)

    result = MetOfficeWeatherProvider().get_snapshot(WeatherLookupRequest(latitude=52.3555, longitude=-1.1743))

    assert captured_request["params"]["dataSource"] == "BD1"
    assert captured_request["headers"]["apikey"] == "test-key"
    assert result["data_gaps"] == []
    assert result["data"]["source_location_name"] == "Barby"
    assert result["data"]["pressure_hpa"] == 1010.6
    assert result["data"]["air_temp_c"] == 17.5

    get_settings.cache_clear()
