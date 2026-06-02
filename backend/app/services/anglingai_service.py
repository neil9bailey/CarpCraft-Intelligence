from __future__ import annotations

from typing import Any

import httpx

from app.core.config import get_settings
from app.schemas.domain import (
    AIEvidenceItem,
    AnglingAIProviderResponse,
    AnglingAISwimSelectorRequest,
    AnglingAIVenueResearchRequest,
    AnglingAIVisionRequest,
    AnglingAIWaterTempRequest,
    ExternalAIProviderStatus,
)


class AnglingAIService:
    provider_name = "AnglingAI"
    docs_url = "https://anglingai.co.uk/docs"

    def status(self) -> ExternalAIProviderStatus:
        settings = get_settings()
        configured = bool(settings.anglingai_api_key)
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
                "venue_name": request.venue_name,
                "location": request.location,
                "target_species": request.target_species,
            },
            evidence_summary=f"AnglingAI venue research requested for {request.venue_name}.",
        )

    def swim_selector(self, request: AnglingAISwimSelectorRequest) -> AnglingAIProviderResponse:
        return self._post(
            "swim-selector",
            {
                "water_type": request.water_type,
                "target_species": request.target_species,
                "wind_direction": request.wind_direction,
                "season": request.season,
                "venue_features": request.venue_features,
            },
            evidence_summary="AnglingAI swim-selector context requested for current watercraft conditions.",
        )

    def water_temp(self, request: AnglingAIWaterTempRequest) -> AnglingAIProviderResponse:
        return self._post(
            "water-temp",
            {
                "location": request.location,
                "water_type": request.water_type,
            },
            evidence_summary=f"AnglingAI water temperature context requested for {request.location}.",
        )

    def vision(self, request: AnglingAIVisionRequest) -> AnglingAIProviderResponse:
        return self._post(
            "fish-id",
            {
                "image_url": request.image_url,
                "prompt": request.prompt,
            },
            evidence_summary="AnglingAI vision/fish-id analysis requested for a user-supplied image URL.",
        )

    def _post(self, endpoint: str, payload: dict[str, Any], evidence_summary: str) -> AnglingAIProviderResponse:
        settings = get_settings()
        if not settings.anglingai_api_key:
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
                timeout=15,
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

    @staticmethod
    def _parse_response(response: httpx.Response) -> tuple[dict[str, object] | None, str | None]:
        content_type = response.headers.get("content-type", "").lower()
        if "json" not in content_type:
            return None, response.text
        payload = response.json()
        if isinstance(payload, dict):
            return payload, None
        return {"items": payload} if isinstance(payload, list) else None, str(payload)
