from __future__ import annotations

from dataclasses import dataclass, field
from json import dumps
from typing import Protocol

import httpx

from app.core.config import get_settings
from app.schemas.domain import (
    AnglingAIVenueResearchRequest,
    Venue,
    VenueConnectorStatus,
    VenueExternalPlace,
    VenueSourceEvidence,
)
from app.services.anglingai_service import AnglingAIService


@dataclass(slots=True)
class VenueConnectorResult:
    status: VenueConnectorStatus
    evidence: list[VenueSourceEvidence] = field(default_factory=list)
    external_place: VenueExternalPlace | None = None


class VenueSourceConnector(Protocol):
    connector_name: str

    def enrich(self, query: str, venue: Venue) -> VenueConnectorResult:
        raise NotImplementedError


def _status(
    connector_name: str,
    display_name: str,
    status: str,
    summary: str,
    evidence_count: int = 0,
    data_gaps: list[str] | None = None,
) -> VenueConnectorStatus:
    return VenueConnectorStatus(
        connector_name=connector_name,
        display_name=display_name,
        status=status,
        summary=summary,
        evidence_count=evidence_count,
        data_gaps=data_gaps or [],
    )


def _source(
    source_name: str,
    source_type: str,
    url: str,
    title: str,
    summary: str,
    confidence: int,
    usage_notes: str | None = None,
) -> VenueSourceEvidence:
    return VenueSourceEvidence(
        source_name=source_name,
        source_type=source_type,
        url=url,
        title=title,
        summary=summary,
        confidence=confidence,
        attribution_required=True,
        usage_notes=usage_notes,
    )


def _is_configured_secret(value: str | None) -> bool:
    return bool(value and value not in {"replace-in-key-vault", "not-configured"})


class GooglePlacesConnector:
    connector_name = "google_places"

    def enrich(self, query: str, venue: Venue) -> VenueConnectorResult:
        settings = get_settings()
        api_key = (
            settings.google_places_api_key
            if _is_configured_secret(settings.google_places_api_key)
            else settings.google_maps_api_key
        )
        if not _is_configured_secret(api_key):
            return VenueConnectorResult(
                status=_status(
                    self.connector_name,
                    "Google Places",
                    "not_configured",
                    "Google Places enrichment was skipped because no backend Places API key is configured.",
                    data_gaps=["Set GOOGLE_PLACES_API_KEY with Places API enabled for backend enrichment."],
                )
            )

        text_query = f"{venue.name} {venue.location_label or query}".strip()
        try:
            response = httpx.post(
                f"{settings.google_places_base_url.rstrip('/')}/v1/places:searchText",
                json={
                    "textQuery": text_query,
                    "regionCode": "GB",
                    "maxResultCount": 1,
                },
                headers={
                    "Content-Type": "application/json",
                    "X-Goog-Api-Key": api_key,
                    "X-Goog-FieldMask": (
                        "places.id,places.displayName,places.formattedAddress,"
                        "places.location,places.googleMapsUri,places.websiteUri"
                    ),
                },
                timeout=8,
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            return VenueConnectorResult(
                status=_status(
                    self.connector_name,
                    "Google Places",
                    "request_failed",
                    "Google Places was configured but the lookup failed.",
                    data_gaps=[
                        f"Google Places request failed: {exc}",
                        "Verify Places API is enabled and the backend key allows server-side web-service calls.",
                    ],
                )
            )

        payload = response.json()
        places = payload.get("places")
        if not isinstance(places, list) or not places:
            return VenueConnectorResult(
                status=_status(
                    self.connector_name,
                    "Google Places",
                    "no_match",
                    "Google Places returned no candidate for this venue query.",
                    data_gaps=["Confirm the fishery name/address or add a Google Place URL manually."],
                )
            )

        place = places[0] if isinstance(places[0], dict) else {}
        location = place.get("location") if isinstance(place.get("location"), dict) else {}
        display_name = place.get("displayName") if isinstance(place.get("displayName"), dict) else {}
        external_place = VenueExternalPlace(
            source_name="Google Places",
            place_id=str(place.get("id")) if place.get("id") else None,
            display_name=str(display_name.get("text")) if display_name.get("text") else None,
            formatted_address=str(place.get("formattedAddress")) if place.get("formattedAddress") else None,
            latitude=location.get("latitude") if isinstance(location.get("latitude"), int | float) else None,
            longitude=location.get("longitude") if isinstance(location.get("longitude"), int | float) else None,
            google_maps_uri=str(place.get("googleMapsUri")) if place.get("googleMapsUri") else None,
            website_uri=str(place.get("websiteUri")) if place.get("websiteUri") else None,
            confidence=82,
        )
        evidence = [
            _source(
                "Google Places",
                "places_directory",
                external_place.google_maps_uri or "https://maps.google.com/",
                external_place.display_name or venue.name,
                "Google Places candidate for map/location verification. Treat as directory metadata, not fishery-rule evidence.",
                82,
                "Display Google attribution and comply with Maps Platform terms when showing this result.",
            )
        ]
        return VenueConnectorResult(
            status=_status(
                self.connector_name,
                "Google Places",
                "active",
                "Google Places returned a map candidate for this venue.",
                evidence_count=len(evidence),
            ),
            evidence=evidence,
            external_place=external_place,
        )


class AnglingAIVenueResearchConnector:
    connector_name = "anglingai_venue_research"
    advisory_fields = {
        "location": "Location",
        "recommendedMethods": "Recommended methods",
        "baits": "Bait notes",
        "bestSpots": "Best spots",
        "seasonalPatterns": "Seasonal patterns",
        "access": "Access information",
        "accessInfo": "Access information",
        "openingTimes": "Opening times",
        "facilities": "Facilities",
        "ticketInfo": "Ticket information",
        "pricing": "Pricing",
        "booking": "Booking information",
        "approximateSize": "Lake information",
        "lakeInfo": "Lake information",
        "stock": "Stock notes",
        "practicalTips": "Practical tips",
        "boatFishing": "Boat fishing",
        "venueType": "Venue type",
        "rules": "Rules",
    }

    @staticmethod
    def _confidence(data: dict[str, object]) -> int:
        confidence = data.get("confidence")
        if isinstance(confidence, dict):
            score = confidence.get("score")
            if isinstance(score, int | float):
                return max(0, min(100, int(score)))
        return 70

    @staticmethod
    def _sources(data: dict[str, object]) -> list[dict[str, object]]:
        sources = data.get("sources")
        if not isinstance(sources, list):
            return []
        return [source for source in sources if isinstance(source, dict)]

    @staticmethod
    def _summary(data: dict[str, object], venue: Venue) -> str:
        sections = [
            section
            for section in ("targetSpecies", "location", "recommendedMethods", "baits", "bestSpots", "seasonalPatterns", "access", "rules")
            if data.get(section)
        ]
        if sections:
            return (
                f"AnglingAI Pro venue research returned {', '.join(sections)} for {venue.name}. "
                "Treat as advisory until source links and fishery rules are reviewed."
            )
        return f"AnglingAI Pro venue research returned advisory context for {venue.name}; review source links before importing facts."

    @staticmethod
    def _compact(value: object) -> str:
        if isinstance(value, str):
            return value[:700]
        return dumps(value, ensure_ascii=True)[:700]

    def enrich(self, query: str, venue: Venue) -> VenueConnectorResult:
        response = AnglingAIService().venue_research(
            AnglingAIVenueResearchRequest(
                venue_name=venue.name,
                location=venue.location_label or query,
                target_species="Carp",
            )
        )
        if response.status == "not_configured":
            return VenueConnectorResult(
                status=_status(
                    self.connector_name,
                    "AnglingAI Pro venue research",
                    "not_configured",
                    "AnglingAI venue research was skipped because ANGLINGAI_API_KEY is not configured.",
                    data_gaps=response.data_gaps,
                )
            )
        if response.status != "active" or not isinstance(response.result, dict):
            return VenueConnectorResult(
                status=_status(
                    self.connector_name,
                    "AnglingAI Pro venue research",
                    "request_failed",
                    "AnglingAI venue research was configured but did not return usable structured data.",
                    data_gaps=response.data_gaps or ["Review AnglingAI API key plan, quota and endpoint availability."],
                )
            )

        raw_data = response.result.get("data")
        data = raw_data if isinstance(raw_data, dict) else {}
        confidence = self._confidence(data)
        sources = self._sources(data)
        evidence = [
            _source(
                "AnglingAI",
                "external_ai_venue_research",
                response.source_url,
                f"AnglingAI Pro venue research for {venue.name}",
                self._summary(data, venue),
                confidence,
                "Use as external advisory evidence only. Import fishery facts after reviewing cited sources and current fishery rules.",
            )
        ]
        for field_name, title in self.advisory_fields.items():
            value = data.get(field_name)
            if value in (None, "", [], {}):
                continue
            evidence.append(
                _source(
                    "AnglingAI",
                    "external_ai_advisory_context",
                    response.source_url,
                    f"{title} for {venue.name}",
                    self._compact(value),
                    max(0, confidence - 5),
                    "Advisory AnglingAI output. Review cited source links before normalizing as venue fact.",
                )
            )
        for source in sources[:5]:
            url = source.get("url")
            title = source.get("title")
            if not url or not title:
                continue
            evidence.append(
                _source(
                    "AnglingAI cited source",
                    "external_ai_citation",
                    str(url),
                    str(title),
                    f"Source cited by AnglingAI venue research for {venue.name}.",
                    max(0, confidence - 10),
                    "Review the source directly before normalizing venue rules, costs, swims or catch history.",
                )
            )

        source_count = response.result.get("sourceCount")
        source_count_text = f"{source_count} cited source(s)" if isinstance(source_count, int) else "source-bound output"
        return VenueConnectorResult(
            status=_status(
                self.connector_name,
                "AnglingAI Pro venue research",
                "active",
                f"AnglingAI venue research returned {source_count_text} with confidence {confidence}.",
                evidence_count=len(evidence),
                data_gaps=[
                    "AnglingAI Pro does not expose a general all-fisheries directory through this key; use seeded venue names from approved source lists."
                ],
            ),
            evidence=evidence,
        )


def default_venue_source_connectors() -> list[VenueSourceConnector]:
    return [
        GooglePlacesConnector(),
        AnglingAIVenueResearchConnector(),
    ]
