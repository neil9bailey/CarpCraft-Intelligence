from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from typing import Any

import httpx

from app.core.config import get_settings


@dataclass(slots=True)
class WeatherLookupRequest:
    latitude: float | None
    longitude: float | None
    location_label: str | None = None


class WeatherProvider:
    name = "unknown"

    def get_snapshot(self, request: WeatherLookupRequest) -> dict[str, object]:
        raise NotImplementedError


class OpenMeteoWeatherProvider(WeatherProvider):
    name = "open_meteo"

    def get_snapshot(self, request: WeatherLookupRequest) -> dict[str, object]:
        if request.latitude is None or request.longitude is None:
            return {
                "source": self.name,
                "data": {},
                "data_gaps": ["Open-Meteo needs latitude and longitude."],
            }
        settings = get_settings()
        response = httpx.get(
            f"{settings.open_meteo_base_url.rstrip('/')}/v1/forecast",
            params={
                "latitude": request.latitude,
                "longitude": request.longitude,
                "current": ",".join(
                    [
                        "temperature_2m",
                        "relative_humidity_2m",
                        "rain",
                        "cloud_cover",
                        "pressure_msl",
                        "wind_speed_10m",
                        "wind_direction_10m",
                    ]
                ),
                "wind_speed_unit": "ms",
                "timezone": "UTC",
            },
            timeout=8,
        )
        response.raise_for_status()
        current = response.json().get("current", {})
        return {
            "source": self.name,
            "data": {
                "captured_at": current.get("time"),
                "air_temp_c": current.get("temperature_2m"),
                "pressure_hpa": current.get("pressure_msl"),
                "wind_speed_mps": current.get("wind_speed_10m"),
                "wind_direction_degrees": current.get("wind_direction_10m"),
                "rainfall_mm": current.get("rain"),
                "cloud_cover_percent": current.get("cloud_cover"),
                "humidity_percent": current.get("relative_humidity_2m"),
            },
            "data_gaps": [],
        }


class MetOfficeWeatherProvider(WeatherProvider):
    name = "met_office"

    @staticmethod
    def _normalize_response(payload: dict[str, Any]) -> tuple[dict[str, object], list[str]]:
        features = payload.get("features")
        if not isinstance(features, list) or not features:
            return {}, ["Met Office response did not include forecast features."]
        feature = features[0]
        if not isinstance(feature, dict):
            return {}, ["Met Office response feature shape was not recognised."]
        properties = feature.get("properties")
        if not isinstance(properties, dict):
            return {}, ["Met Office response did not include forecast properties."]
        time_series = properties.get("timeSeries")
        if not isinstance(time_series, list) or not time_series:
            return {}, ["Met Office response did not include a time series."]
        current = time_series[0]
        if not isinstance(current, dict):
            return {}, ["Met Office time series item shape was not recognised."]

        pressure = current.get("mslp")
        pressure_hpa = pressure / 100 if isinstance(pressure, int | float) and pressure > 2000 else pressure
        location = properties.get("location") if isinstance(properties.get("location"), dict) else {}
        return (
            {
                "captured_at": current.get("time"),
                "model_run_at": properties.get("modelRunDate"),
                "source_location_name": location.get("name") if isinstance(location, dict) else None,
                "request_point_distance_m": properties.get("requestPointDistance"),
                "air_temp_c": current.get("screenTemperature"),
                "pressure_hpa": pressure_hpa,
                "wind_speed_mps": current.get("windSpeed10m"),
                "wind_direction_degrees": current.get("windDirectionFrom10m"),
                "rainfall_mm": current.get("totalPrecipAmount"),
                "rainfall_rate_mm_h": current.get("precipitationRate"),
                "cloud_cover_percent": current.get("totalCloudCover"),
                "humidity_percent": current.get("screenRelativeHumidity"),
                "weather_code": current.get("significantWeatherCode"),
            },
            [],
        )

    def get_snapshot(self, request: WeatherLookupRequest) -> dict[str, object]:
        settings = get_settings()
        if not settings.met_office_api_key:
            return {
                "source": self.name,
                "data": {},
                "data_gaps": ["MET_OFFICE_API_KEY is not configured."],
            }
        if request.latitude is None or request.longitude is None:
            return {
                "source": self.name,
                "data": {},
                "data_gaps": ["Met Office DataHub needs latitude and longitude."],
            }

        # Site-specific DataHub products vary by subscription. Keep the adapter
        # isolated so the configured product can be swapped without changing API contracts.
        response = httpx.get(
            f"{settings.met_office_base_url.rstrip('/')}/sitespecific/v0/point/hourly",
            params={
                "dataSource": "BD1",
                "latitude": request.latitude,
                "longitude": request.longitude,
                "includeLocationName": "true",
            },
            headers={"apikey": settings.met_office_api_key},
            timeout=8,
        )
        response.raise_for_status()
        data, data_gaps = self._normalize_response(response.json())
        return {
            "source": self.name,
            "data": data,
            "data_gaps": data_gaps,
        }


class WeatherService:
    """Combines credible weather providers without hiding data gaps."""

    def __init__(self, providers: list[WeatherProvider] | None = None) -> None:
        self.providers = providers or [OpenMeteoWeatherProvider(), MetOfficeWeatherProvider()]

    def get_snapshot(self, request: WeatherLookupRequest) -> dict[str, object]:
        provider_results: list[dict[str, object]] = []
        data_gaps: list[str] = []
        primary_data: dict[str, Any] = {}

        for provider in self.providers:
            try:
                result = provider.get_snapshot(request)
            except httpx.HTTPError as exc:
                result = {
                    "source": provider.name,
                    "data": {},
                    "data_gaps": [f"{provider.name} request failed: {exc}"],
                }
            provider_results.append(result)
            data_gaps.extend(str(gap) for gap in result.get("data_gaps", []))
            if not primary_data:
                data = result.get("data")
                if isinstance(data, dict) and data:
                    primary_data = data

        return {
            "source": "multi_provider",
            "requested_location": asdict(request),
            "captured_at": primary_data.get("captured_at") or datetime.now(UTC).isoformat(),
            "air_temp_c": primary_data.get("air_temp_c"),
            "pressure_hpa": primary_data.get("pressure_hpa"),
            "wind_speed_mps": primary_data.get("wind_speed_mps"),
            "wind_direction_degrees": primary_data.get("wind_direction_degrees"),
            "rainfall_mm": primary_data.get("rainfall_mm"),
            "cloud_cover_percent": primary_data.get("cloud_cover_percent"),
            "humidity_percent": primary_data.get("humidity_percent"),
            "providers": provider_results,
            "data_gaps": data_gaps,
        }
