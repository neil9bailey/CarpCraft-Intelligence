from __future__ import annotations

from app.schemas.domain import RichWeatherCondition, WeatherConditionKind


def _number(value: object) -> float | None:
    if isinstance(value, int | float):
        return float(value)
    return None


def _integer(value: object) -> int | None:
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return round(value)
    return None


class WeatherConditionService:
    """Adds angling-friendly condition labels without pretending to measure water temperature."""

    def enrich_snapshot(self, snapshot: dict[str, object]) -> RichWeatherCondition:
        air_temp_c = _number(snapshot.get("air_temp_c"))
        wind_speed_mps = _number(snapshot.get("wind_speed_mps"))
        wind_direction_degrees = _number(snapshot.get("wind_direction_degrees"))
        pressure_hpa = _number(snapshot.get("pressure_hpa"))
        rainfall_mm = _number(snapshot.get("rainfall_mm"))
        rainfall_rate_mm_h = _number(snapshot.get("rainfall_rate_mm_h"))
        cloud_cover_percent = _integer(snapshot.get("cloud_cover_percent"))
        humidity_percent = _integer(snapshot.get("humidity_percent"))
        providers = snapshot.get("providers") if isinstance(snapshot.get("providers"), list) else []
        data_gaps = [str(gap) for gap in snapshot.get("data_gaps", []) if gap]

        surface_temp, surface_confidence, approximation_notes, surface_gaps = self._approximate_surface_temp(
            air_temp_c=air_temp_c,
            wind_speed_mps=wind_speed_mps,
            rainfall_rate_mm_h=rainfall_rate_mm_h if rainfall_rate_mm_h is not None else rainfall_mm,
            cloud_cover_percent=cloud_cover_percent,
            provider_count=len(providers),
        )
        data_gaps.extend(surface_gaps)

        intensity = self._precipitation_intensity(rainfall_rate_mm_h if rainfall_rate_mm_h is not None else rainfall_mm)
        condition = self._condition_kind(air_temp_c, cloud_cover_percent, intensity)

        return RichWeatherCondition(
            source=str(snapshot.get("source", "multi_provider")),
            requested_location=snapshot.get("requested_location") if isinstance(snapshot.get("requested_location"), dict) else {},
            captured_at=str(snapshot.get("captured_at")) if snapshot.get("captured_at") else None,
            air_temp_c=air_temp_c,
            approx_surface_temp_c=surface_temp,
            approx_surface_temp_confidence=surface_confidence,
            pressure_hpa=pressure_hpa,
            wind_speed_mps=wind_speed_mps,
            wind_direction_degrees=wind_direction_degrees,
            wind_direction_label=self._wind_direction_label(wind_direction_degrees),
            rainfall_mm=rainfall_mm,
            rainfall_rate_mm_h=rainfall_rate_mm_h,
            precipitation_intensity=intensity,
            cloud_cover_percent=cloud_cover_percent,
            humidity_percent=humidity_percent,
            condition=condition,
            storm_risk=condition == WeatherConditionKind.storm or (rainfall_rate_mm_h or 0) >= 20,
            hail_risk=condition == WeatherConditionKind.hail,
            sleet_or_snow_risk=condition in {WeatherConditionKind.sleet, WeatherConditionKind.snow},
            provider_count=len(providers),
            provider_evidence=[provider for provider in providers if isinstance(provider, dict)],
            approximation_notes=approximation_notes,
            data_gaps=data_gaps,
        )

    @staticmethod
    def _approximate_surface_temp(
        *,
        air_temp_c: float | None,
        wind_speed_mps: float | None,
        rainfall_rate_mm_h: float | None,
        cloud_cover_percent: int | None,
        provider_count: int,
    ) -> tuple[float | None, int, list[str], list[str]]:
        if air_temp_c is None:
            return None, 0, [], ["Approximate surface temperature needs an air temperature."]

        estimate = air_temp_c
        notes = ["Approximate surface temperature is inferred from air, cloud, wind and rain; it is not a measured water reading."]
        confidence = 35 + min(provider_count, 2) * 5
        gaps: list[str] = ["Use a thermometer reading when surface temperature matters for decisions."]

        if cloud_cover_percent is None:
            gaps.append("Cloud cover is missing from the weather feed.")
        elif cloud_cover_percent <= 25:
            estimate += 0.6
            confidence += 10
        elif cloud_cover_percent >= 85:
            estimate -= 0.2
            confidence += 8
        else:
            confidence += 8

        if wind_speed_mps is None:
            gaps.append("Wind speed is missing from the weather feed.")
        elif wind_speed_mps >= 9:
            estimate -= 0.8
            confidence += 8
        elif wind_speed_mps >= 5:
            estimate -= 0.4
            confidence += 9
        else:
            confidence += 8

        if rainfall_rate_mm_h is None:
            gaps.append("Rainfall intensity is missing from the weather feed.")
        elif rainfall_rate_mm_h >= 8:
            estimate -= 0.8
            confidence += 8
        elif rainfall_rate_mm_h > 0:
            estimate -= 0.3
            confidence += 8
        else:
            confidence += 8

        return round(estimate, 1), min(confidence, 75), notes, gaps

    @staticmethod
    def _precipitation_intensity(rate_mm_h: float | None) -> str:
        if rate_mm_h is None:
            return "unknown"
        if rate_mm_h <= 0:
            return "none"
        if rate_mm_h < 0.5:
            return "drizzle"
        if rate_mm_h < 2:
            return "light"
        if rate_mm_h < 8:
            return "moderate"
        return "heavy"

    @staticmethod
    def _condition_kind(air_temp_c: float | None, cloud_cover_percent: int | None, intensity: str) -> WeatherConditionKind:
        if intensity == "heavy":
            return WeatherConditionKind.heavy_rain
        if intensity == "moderate":
            return WeatherConditionKind.moderate_rain
        if intensity == "light":
            if air_temp_c is not None and air_temp_c <= 1:
                return WeatherConditionKind.sleet
            return WeatherConditionKind.light_rain
        if intensity == "drizzle":
            return WeatherConditionKind.drizzle
        if cloud_cover_percent is None:
            return WeatherConditionKind.unknown
        if cloud_cover_percent <= 15:
            return WeatherConditionKind.sunny
        if cloud_cover_percent <= 45:
            return WeatherConditionKind.partly_cloudy
        if cloud_cover_percent <= 85:
            return WeatherConditionKind.cloudy
        return WeatherConditionKind.overcast

    @staticmethod
    def _wind_direction_label(degrees: float | None) -> str | None:
        if degrees is None:
            return None
        labels = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
        index = round((degrees % 360) / 45) % 8
        return labels[index]
