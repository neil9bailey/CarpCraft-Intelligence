from __future__ import annotations

from typing import Any

import httpx

from app.core.config import get_settings
from app.schemas.domain import (
    AIEvidenceItem,
    AnglingAIBaitCalculatorRequest,
    AnglingAIByelawCheckRequest,
    AnglingAIFishDiseaseRequest,
    AnglingAILakeMapFromLocationRequest,
    AnglingAIProviderResponse,
    AnglingAIRigBuilderRequest,
    AnglingAISolunarRequest,
    AnglingAISpawnAlertRequest,
    AnglingAISwimSelectorRequest,
    AnglingAIVenueResearchRequest,
    AnglingAIVisionRequest,
    AnglingAIWeatherRequest,
    AnglingAIWaterTempRequest,
    ExternalAIProviderStatus,
)


class AnglingAIService:
    provider_name = "AnglingAI"
    docs_url = "https://anglingai.co.uk/docs"

    @staticmethod
    def _is_configured(value: str | None) -> bool:
        return bool(value and value not in {"replace-in-key-vault", "not-configured"})

    def status(self) -> ExternalAIProviderStatus:
        settings = get_settings()
        configured = self._is_configured(settings.anglingai_api_key)
        return ExternalAIProviderStatus(
            provider_name=self.provider_name,
            configured=configured,
            base_url=settings.anglingai_base_url,
            summary=(
                "AnglingAI provider is configured for server-side calls."
                if configured
                else "Set ANGLINGAI_API_KEY to enable optional AnglingAI venue, weather and vision enrichment."
            ),
            data_gaps=[] if configured else ["No AnglingAI API key is configured."],
        )

    def venue_research(self, request: AnglingAIVenueResearchRequest) -> AnglingAIProviderResponse:
        return self._post(
            "venue-research",
            {
                "venueName": request.venue_name,
                "location": request.location,
                "targetSpecies": request.target_species,
            },
            evidence_summary=f"AnglingAI venue research requested for {request.venue_name}.",
        )

    def swim_selector(self, request: AnglingAISwimSelectorRequest) -> AnglingAIProviderResponse:
        return self._post(
            "swim-selector",
            {
                "waterType": request.water_type,
                "targetSpecies": request.target_species,
                "windDirection": request.wind_direction,
                "season": request.season,
                "venueFeatures": request.venue_features,
            },
            evidence_summary="AnglingAI swim-selector context requested for current watercraft conditions.",
        )

    def water_temp(self, request: AnglingAIWaterTempRequest) -> AnglingAIProviderResponse:
        return self._post(
            "water-temp",
            {
                "location": request.location,
                "waterType": request.water_type,
            },
            evidence_summary=f"AnglingAI water temperature context requested for {request.location}.",
        )

    def weather(self, request: AnglingAIWeatherRequest) -> AnglingAIProviderResponse:
        return self._post(
            "weather",
            {
                "location": request.location,
                "targetSpecies": request.target_species,
            },
            evidence_summary=f"AnglingAI weather interpretation requested for {request.location}.",
        )

    def solunar(self, request: AnglingAISolunarRequest) -> AnglingAIProviderResponse:
        return self._post(
            "solunar",
            {
                "location": request.location,
                "days": request.days,
            },
            evidence_summary=f"AnglingAI solunar context requested for {request.location}.",
        )

    def spawn_alert(self, request: AnglingAISpawnAlertRequest) -> AnglingAIProviderResponse:
        return self._post(
            "spawn-alert",
            {
                "waterTemperature": request.water_temperature,
                "species": request.species,
            },
            evidence_summary="AnglingAI spawning threshold context requested.",
        )

    def byelaw_check(self, request: AnglingAIByelawCheckRequest) -> AnglingAIProviderResponse:
        return self._post(
            "byelaw-check",
            {
                "waterType": request.water_type,
                "date": request.date,
                "species": request.species,
                "region": request.region,
            },
            evidence_summary="AnglingAI UK byelaw context requested.",
        )

    def bait_calculator(self, request: AnglingAIBaitCalculatorRequest) -> AnglingAIProviderResponse:
        return self._post(
            "bait-calculator",
            {
                "durationHours": request.duration_hours,
                "targetSpecies": request.target_species,
                "methods": request.methods,
                "waterType": request.water_type,
                "season": request.season,
            },
            evidence_summary="AnglingAI bait quantity context requested.",
        )

    def rig_builder(self, request: AnglingAIRigBuilderRequest) -> AnglingAIProviderResponse:
        return self._post(
            "rig-builder",
            {
                "targetSpecies": request.target_species,
                "waterType": request.water_type,
                "method": request.method,
                "generateImage": request.generate_image,
            },
            evidence_summary="AnglingAI rig specification context requested.",
        )

    def fish_disease(self, request: AnglingAIFishDiseaseRequest) -> AnglingAIProviderResponse:
        return self._post(
            "fish-disease",
            {
                "imageUrl": request.image_url,
                "context": request.context,
            },
            evidence_summary="AnglingAI fish health image analysis requested for a user-supplied image URL.",
        )

    def lake_map_from_location(self, request: AnglingAILakeMapFromLocationRequest) -> AnglingAIProviderResponse:
        return self._post(
            "lake-map/from-location",
            {
                "lat": request.lat,
                "lng": request.lng,
                "name": request.name,
                "pegCount": request.peg_count,
                "amenities": request.amenities,
                "features": request.features,
            },
            evidence_summary=f"AnglingAI lake-map generation requested for {request.name}.",
            timeout=60,
        )

    def locations(self) -> AnglingAIProviderResponse:
        return self._get(
            "locations",
            evidence_summary="AnglingAI saved locations requested for account-backed venue import.",
        )

    def vision(self, request: AnglingAIVisionRequest) -> AnglingAIProviderResponse:
        return self._post(
            "fish-id",
            {
                "imageUrl": request.image_url,
                "prompt": request.prompt,
            },
            evidence_summary="AnglingAI vision/fish-id analysis requested for a user-supplied image URL.",
        )

    def _post(
        self,
        endpoint: str,
        payload: dict[str, Any],
        evidence_summary: str,
        timeout: float = 15,
    ) -> AnglingAIProviderResponse:
        settings = get_settings()
        if not self._is_configured(settings.anglingai_api_key):
            return AnglingAIProviderResponse(
                endpoint=endpoint,
                configured=False,
                status="not_configured",
                data_gaps=["Set ANGLINGAI_API_KEY on the backend or in Azure Key Vault before calling this provider."],
            )

        cleaned_payload = {key: value for key, value in payload.items() if value is not None}
        try:
            response = httpx.post(
                f"{settings.anglingai_base_url.rstrip('/')}/{endpoint}",
                json=cleaned_payload,
                headers={
                    "Authorization": f"Bearer {settings.anglingai_api_key}",
                    "Content-Type": "application/json",
                },
                timeout=timeout,
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            return AnglingAIProviderResponse(
                endpoint=endpoint,
                configured=True,
                status="request_failed",
                data_gaps=[f"AnglingAI {endpoint} request failed: {exc}"],
            )

        result, text = self._parse_response(response)
        return AnglingAIProviderResponse(
            endpoint=endpoint,
            configured=True,
            status="active",
            result=result,
            text=text,
            evidence=[
                AIEvidenceItem(
                    source_type="external_ai_provider",
                    summary=evidence_summary,
                    confidence=65,
                    url=self.docs_url,
                )
            ],
            data_gaps=[
                "Treat third-party AI output as advisory evidence until reviewed against CarpCraft logs, fishery rules and source facts."
            ],
        )

    def _get(self, endpoint: str, evidence_summary: str, timeout: float = 15) -> AnglingAIProviderResponse:
        settings = get_settings()
        if not self._is_configured(settings.anglingai_api_key):
            return AnglingAIProviderResponse(
                endpoint=endpoint,
                configured=False,
                status="not_configured",
                data_gaps=["Set ANGLINGAI_API_KEY on the backend or in Azure Key Vault before calling this provider."],
            )

        try:
            response = httpx.get(
                f"{settings.anglingai_base_url.rstrip('/')}/{endpoint}",
                headers={"Authorization": f"Bearer {settings.anglingai_api_key}"},
                timeout=timeout,
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            return AnglingAIProviderResponse(
                endpoint=endpoint,
                configured=True,
                status="request_failed",
                data_gaps=[f"AnglingAI {endpoint} request failed: {exc}"],
            )

        result, text = self._parse_response(response)
        return AnglingAIProviderResponse(
            endpoint=endpoint,
            configured=True,
            status="active",
            result=result,
            text=text,
            evidence=[
                AIEvidenceItem(
                    source_type="external_ai_provider",
                    summary=evidence_summary,
                    confidence=65,
                    url=self.docs_url,
                )
            ],
            data_gaps=[
                "Treat third-party account data as private user data unless explicit export/sharing consent is recorded."
            ],
        )

    @staticmethod
    def _parse_response(response: httpx.Response) -> tuple[dict[str, object] | None, str | None]:
        content_type = response.headers.get("content-type", "").lower()
        if "json" not in content_type:
            return None, response.text
        payload = response.json()
        if isinstance(payload, dict):
            return payload, None
        return {"items": payload} if isinstance(payload, list) else None, str(payload)
