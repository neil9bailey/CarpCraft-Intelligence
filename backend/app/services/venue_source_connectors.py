from __future__ import annotations

from dataclasses import dataclass, field
from typing import Protocol

import httpx

from app.core.config import get_settings
from app.schemas.domain import Venue, VenueConnectorStatus, VenueExternalPlace, VenueSourceEvidence


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


class GooglePlacesConnector:
    connector_name = "google_places"

    def enrich(self, query: str, venue: Venue) -> VenueConnectorResult:
        settings = get_settings()
        api_key = settings.google_places_api_key or settings.google_maps_api_key
        if not api_key:
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


class CatchGoCatchConnector:
    connector_name = "catch_gocatch"

    def enrich(self, query: str, venue: Venue) -> VenueConnectorResult:
        evidence = [
            _source(
                "Catch / GoCatch",
                "partner_booking_directory",
                "https://www.gocatch.fish/",
                "Catch venue and booking platform",
                "Catch publishes venue booking/directory information, but CarpCraft has no public API contract in this build.",
                70,
                "Use official partner API access, fishery-provided links, or manual verification before importing availability or catch reports.",
            )
        ]
        return VenueConnectorResult(
            status=_status(
                self.connector_name,
                "Catch / GoCatch",
                "partner_required",
                "Ready for a partner/API connector; current release records source links and gaps only.",
                evidence_count=len(evidence),
                data_gaps=["Partner API credentials or fishery-provided Catch venue links are required for live availability/catch-report ingestion."],
            ),
            evidence=evidence,
        )


class SwimbookerConnector:
    connector_name = "swimbooker"

    def enrich(self, query: str, venue: Venue) -> VenueConnectorResult:
        evidence = [
            _source(
                "swimbooker",
                "booking_directory",
                "https://swimbooker.com/",
                "swimbooker fisheries directory",
                "swimbooker publishes fishery booking/directory information, but no stable public API is wired in this build.",
                68,
                "Use official partner/API access or manually verified fishery profile links before importing availability or user catch reports.",
            )
        ]
        return VenueConnectorResult(
            status=_status(
                self.connector_name,
                "swimbooker",
                "manual_directory",
                "Ready for manual source links or future partner API integration.",
                evidence_count=len(evidence),
                data_gaps=["No public Swimbooker API contract is configured for automated venue/catch-report import."],
            ),
            evidence=evidence,
        )


class FacebookGroupsConnector:
    connector_name = "facebook_groups"

    def enrich(self, query: str, venue: Venue) -> VenueConnectorResult:
        return VenueConnectorResult(
            status=_status(
                self.connector_name,
                "Facebook groups",
                "blocked_by_policy",
                "Facebook group scraping/import is disabled; use explicit user-provided links or fishery-owned public pages only.",
                data_gaps=[
                    "Facebook Groups API access is not available for CarpCraft automated group ingestion.",
                    "Do not scrape private or public groups without explicit permission and a compliant connector.",
                ],
            )
        )


def default_venue_source_connectors() -> list[VenueSourceConnector]:
    return [
        GooglePlacesConnector(),
        CatchGoCatchConnector(),
        SwimbookerConnector(),
        FacebookGroupsConnector(),
    ]
