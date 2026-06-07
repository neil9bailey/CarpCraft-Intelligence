from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Any

from app.schemas.domain import (
    PrivacyLevel,
    Venue,
    VenueConnectorStatus,
    VenueExternalPlace,
    VenueIntelligenceReport,
    VenueMapAsset,
    VenueNewsItem,
    VenueSourceEvidence,
    VenueSwimIntelligence,
    VenueType,
    VenueWeatherIntelligence,
)
from app.services.venue_source_connectors import VenueSourceConnector, default_venue_source_connectors
from app.services.weather_service import WeatherLookupRequest, WeatherService


@dataclass(frozen=True, slots=True)
class VenueIntelligenceSourcePack:
    aliases: tuple[str, ...]
    report: dict[str, Any]


def _source(
    source_name: str,
    source_type: str,
    url: str,
    title: str,
    summary: str,
    confidence: int = 85,
) -> VenueSourceEvidence:
    return VenueSourceEvidence(
        source_name=source_name,
        source_type=source_type,
        url=url,
        title=title,
        summary=summary,
        confidence=confidence,
    )


def _news(title: str, summary: str, url: str, source_name: str, published_on: str | None = None) -> VenueNewsItem:
    return VenueNewsItem(
        title=title,
        published_on=published_on,
        summary=summary,
        url=url,
        source_name=source_name,
    )


SOURCE_PACKS: dict[str, VenueIntelligenceSourcePack] = {
    "linear-fisheries": VenueIntelligenceSourcePack(
        aliases=("linear", "linear fisheries", "linear oxford", "linear fisheries oxford"),
        report={
            "suggested_venue": Venue(
                id="linear-fisheries-oxford",
                name="Linear Fisheries Oxford",
                type=VenueType.day_ticket,
                location_label="B4449 between Stanton Harcourt and A415 Witney road, SatNav OX29 7QF",
                approximate_latitude=51.74778,
                approximate_longitude=-1.44076,
                stock_notes=(
                    "Official site describes multiple day-ticket and syndicate carp waters at Oxford. "
                    "Latest-catch evidence should be treated as recent public reports, not guaranteed form."
                ),
                rules_notes="Read official Linear rules before fishing; rules are enforced and fish care is central.",
                privacy_level=PrivacyLevel.private,
            ),
            "summary": (
                "Linear Fisheries is a large Oxfordshire carp complex with day-ticket, Tar Farm and syndicate waters. "
                "The intelligence pack links official waters, map, rules, prices and latest-catch pages."
            ),
            "swims": [
                VenueSwimIntelligence(
                    name="Brasenose One",
                    stock_notes="Listed by Linear as a day-ticket water.",
                    source_url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=waters.start",
                ),
                VenueSwimIntelligence(
                    name="Brasenose Two",
                    stock_notes="Listed by Linear as a day-ticket water.",
                    source_url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=waters.start",
                ),
                VenueSwimIntelligence(
                    name="Hardwick Lake and Smiths Pool",
                    stock_notes="Listed by Linear as a day-ticket water.",
                    source_url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=waters.start",
                ),
                VenueSwimIntelligence(
                    name="Hunts Corner Lake",
                    stock_notes="Listed by Linear as a day-ticket water.",
                    source_url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=waters.start",
                ),
                VenueSwimIntelligence(
                    name="Manor Farm Lake",
                    stock_notes="Listed by Linear as a day-ticket water.",
                    source_url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=waters.start",
                ),
                VenueSwimIntelligence(
                    name="Unity Lake",
                    stock_notes="Listed by Linear as a syndicate water with recent public latest-catch reports.",
                    source_url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=latestcatches.start",
                ),
                VenueSwimIntelligence(
                    name="Tar Farm Lake No. 5",
                    stock_notes="Listed by Linear as a Tar Farm day-ticket water with recent public latest-catch reports.",
                    source_url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=latestcatches.start",
                ),
            ],
            "map_assets": [
                VenueMapAsset(
                    title="Linear Fisheries site map",
                    url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=main.map",
                    asset_type="official_site_map",
                    notes="Official complex map page; use as a source link until map image licensing is reviewed.",
                    license_status="source_link_only_pending_permission",
                    cache_allowed=False,
                    attribution="Linear Fisheries",
                )
            ],
            "catch_reports": [
                _news(
                    title="Tar Farm Lake No. 5 public latest catch report",
                    published_on="2026-05-20",
                    summary="Linear latest-catches page reports a short session with multiple fish from Tar Farm Lake No. 5.",
                    url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=latestcatches.start",
                    source_name="Linear Fisheries",
                ),
                _news(
                    title="Unity Lake public latest catch reports",
                    published_on="2026-05-14",
                    summary="Linear latest-catches page includes repeated public reports of multiple Unity Lake captures.",
                    url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=latestcatches.start",
                    source_name="Linear Fisheries",
                ),
            ],
            "news_items": [],
            "source_evidence": [
                _source(
                    "Linear Fisheries",
                    "official_fishery_site",
                    "https://www.linear-fisheries.co.uk/",
                    "Official Linear Fisheries homepage",
                    "Official source for fishery overview, rules, maps, prices and latest catches.",
                    95,
                ),
                _source(
                    "Linear Fisheries",
                    "official_map",
                    "https://www.linear-fisheries.co.uk/index.cfm?fuseaction=main.map",
                    "Official site map and location",
                    "Gives fishery location guidance and SatNav postcode OX29 7QF.",
                    90,
                ),
                _source(
                    "Linear Fisheries",
                    "official_opening_times",
                    "https://www.linear-fisheries.co.uk/index.cfm?fuseaction=main.openingtimes",
                    "Official opening times and gate lock-up",
                    "Confirms 24-hour fishing, overnight gate lock-up times and early-arrival car park guidance.",
                    95,
                ),
                _source(
                    "Linear Fisheries",
                    "official_prices",
                    "https://www.linear-fisheries.co.uk/index.cfm?fuseaction=main.prices",
                    "Official prices and booking notes",
                    "Lists day-ticket pricing and current official booking notes for selected waters.",
                    95,
                ),
                _source(
                    "Linear Fisheries",
                    "official_facilities",
                    "https://www.linear-fisheries.co.uk/index.cfm?fuseaction=main.showers",
                    "Official showers and toilet block",
                    "Describes the shower/toilet block, drinking-water tap, parking areas and porta loos.",
                    90,
                ),
            ],
            "data_gaps": [
                "Individual swim boundaries and detailed bathymetry are not normalized yet from official Linear map images.",
                "Third-party booking and social data is not integrated in this build; use official fishery pages and live AnglingAI/Google evidence only.",
                "Do not infer current form from latest-catch reports without your own session evidence.",
            ],
            "costs_notes": (
                "Official Linear prices page lists current day-ticket and selected-water booking notes; always verify current prices before travelling."
            ),
            "how_to_book_notes": (
                "Use Linear's official pricing and water pages for the current booking route before travelling."
            ),
            "access_notes": [
                "Waters are described by Linear as open for 24-hour fishing, with gates locked overnight for security.",
                "Anglers arriving during lock-up must wait in the early-arrival car park and must not block locked gates.",
            ],
            "opening_times_notes": ["Linear's official opening-times page says waters are open for 24-hour fishing."],
            "gate_closure_notes": [
                "Official opening-times page: March 1 to October 31 gates are locked at 9pm and opened again by 7:30am.",
                "Official opening-times page: November 1 to end of February gates are locked at 7pm and opened again by 7:30am.",
            ],
            "parking_notes": [
                "Use the early-arrival car park during lock-up times; do not park in front of or block locked gates.",
                "The shower/toilet block page references parking areas between St Johns and Manor Farm plus short-term shower-block parking.",
            ],
            "facilities": [
                "Shower and toilet block between St Johns and Manor Farm near the fishery office.",
                "Drinking water tap outside the shower block.",
                "Porta loos positioned around the complex.",
            ],
            "rules": [
                "Do not leave rods unattended.",
                "Do not park on grass, block gates, light fires, leave litter, or abuse bailiffs/staff.",
                "Check lake-specific rules and safe-rig requirements before fishing.",
            ],
        },
    ),
    "embryo-norton-disney": VenueIntelligenceSourcePack(
        aliases=("embryo", "norton disney", "embryo norton disney", "norton disney fishery"),
        report={
            "suggested_venue": Venue(
                id="embryo-norton-disney",
                name="Embryo Norton Disney",
                type=VenueType.day_ticket,
                location_label="Swinderby Road / Butt Lane, Norton Disney, LN6 9QH",
                approximate_latitude=53.123845,
                approximate_longitude=-0.675704,
                acreage=140,
                stock_notes=(
                    "Official page describes a 6-lake complex with fish to 30lb+ in every lake and a complex record of 53lb."
                ),
                rules_notes="Cashless site. Report to lodge. Swim choice is first come, first served. Read official rules before attending.",
                privacy_level=PrivacyLevel.private,
            ),
            "summary": (
                "Embryo Norton Disney is a six-lake Lincolnshire day-ticket complex. Public official pages expose lake sizes, "
                "swim counts, stock notes, named fish lists and depth-map links for lake-level intelligence."
            ),
            "swims": [
                VenueSwimIntelligence(
                    name="Pettitt's Lake",
                    acreage=16,
                    swim_count=13,
                    stock_notes="Official page describes Pettitt's as the big-fish lake with a lake record of 52lb.",
                    feature_notes="Official page says the lake bed resembles an egg box in places and has depth-map guidance.",
                    depth_map_url="https://www.embryoangling.org/wp-content/uploads/2020/07/Pettitts_Depth_Map_Website.jpg",
                    source_url="https://www.embryoangling.org/venue/pettitts-lake/",
                ),
                VenueSwimIntelligence(
                    name="Holden's Lake",
                    acreage=11,
                    stock_notes="Official Norton Disney page describes Holden's as a deep specimen lake with 400+ fish.",
                    source_url="https://www.embryoangling.org/venue/holdens-lake/",
                ),
                VenueSwimIntelligence(
                    name="Turner's Lake",
                    acreage=18,
                    stock_notes="Official Norton Disney page describes Turner's as holding a big head of twenties and thirties to over 40lb.",
                    feature_notes="Official Norton Disney page notes a fairly uniform lakebed where bait is often the feature.",
                    source_url="https://www.embryoangling.org/venue/turners-lake/",
                ),
                VenueSwimIntelligence(
                    name="Billy's Lake",
                    acreage=27,
                    stock_notes="Official Norton Disney page describes Billy's as a large gravel pit with 1000+ carp to over 40lb.",
                    source_url="https://www.embryoangling.org/venue/billys-lake/",
                ),
                VenueSwimIntelligence(
                    name="Hodgett's Lake",
                    acreage=10,
                    stock_notes="Official Norton Disney page describes Hodgett's as higher-stock-density and suited to bites.",
                    source_url="https://www.embryoangling.org/norton-disney/",
                ),
                VenueSwimIntelligence(
                    name="Stock's Lake",
                    acreage=8,
                    stock_notes="Official Norton Disney page describes Stock's as 750+ fish with short-range and social options.",
                    source_url="https://www.embryoangling.org/norton-disney/",
                ),
            ],
            "map_assets": [
                VenueMapAsset(
                    title="Pettitt's Lake depth map",
                    url="https://www.embryoangling.org/wp-content/uploads/2020/07/Pettitts_Depth_Map_Website.jpg",
                    asset_type="official_depth_map",
                    notes="Official high-resolution/downloadable depth map linked from Embryo's Pettitt's Lake page.",
                    license_status="source_link_only_pending_permission",
                    cache_allowed=False,
                    attribution="Embryo Angling",
                )
            ],
            "news_items": [
                _news(
                    title="Norton Disney official page",
                    summary="Embryo says Norton Disney is a six-lake day-ticket complex in Lincolnshire with 80+ swims.",
                    url="https://www.embryoangling.org/norton-disney/",
                    source_name="Embryo Angling",
                )
            ],
            "catch_reports": [
                _news(
                    title="Pettitt's named fish list",
                    summary="Embryo publishes named fish and weights on the Pettitt's Lake page; treat as stock evidence rather than current catch form.",
                    url="https://www.embryoangling.org/venue/pettitts-lake/",
                    source_name="Embryo Angling",
                )
            ],
            "source_evidence": [
                _source(
                    "Embryo Angling",
                    "official_fishery_site",
                    "https://www.embryoangling.org/norton-disney/",
                    "Official Norton Disney overview",
                    "Official source for complex overview, address, pricing, rules, lake list, swim count and stock notes.",
                    95,
                ),
                _source(
                    "Embryo Angling",
                    "official_visit_guidance",
                    "https://www.embryoangling.org/norton-disney-about-your-visit/",
                    "Official Norton Disney visit guidance",
                    "Confirms ticket prices, gate opening hours, lodge arrival, cashless payment and provided fish-care equipment.",
                    95,
                ),
                _source(
                    "Embryo Angling",
                    "official_rules",
                    "https://www.embryoangling.org/norton-disney-day-ticket-rules/",
                    "Official Norton Disney day-ticket rules",
                    "Source for Norton Disney rules and fish-care handling requirements.",
                    95,
                ),
                _source(
                    "Embryo Angling",
                    "official_depth_map",
                    "https://www.embryoangling.org/venue/pettitts-lake/",
                    "Pettitt's Lake depth-map page",
                    "Official page links a high-resolution/downloadable depth map and explains lake features.",
                    95,
                ),
            ],
            "data_gaps": [
                "Social updates are not integrated in this build; use official fishery pages and live AnglingAI/Google evidence only.",
                "Depth maps need licensing review before caching image copies inside the app.",
                "Current catch reports should be separated from static stock lists before feeding recommendation logic.",
            ],
            "costs_notes": (
                "Official Norton Disney visit page lists day and 24-hour ticket pricing plus concession pricing; verify the current page before booking."
            ),
            "how_to_book_notes": "Report to the lodge on arrival; use current Embryo booking/day-ticket instructions before travelling.",
            "access_notes": [
                "Anglers must report to the lodge on arrival where on-site bailiffs assist with tickets and information.",
                "Norton Disney is described by Embryo as cashless, so payments are card only.",
            ],
            "opening_times_notes": [
                "Official visit page says anglers can start sessions during main fishery gate opening hours."
            ],
            "gate_closure_notes": [
                "Official visit page: November 1 to March 31 main fishery gate opening times are 8am to 5pm.",
                "Official visit page: April 1 to October 31 main fishery gate opening times are 7am to 8pm.",
            ],
            "parking_notes": [
                "Parking details need source review from the current official visit page or fishery team before normalization."
            ],
            "facilities": [
                "On-site lodge for arrival, tickets and information.",
                "Nets, mats and slings are provided for anglers according to the official visit page.",
                "Cashless card payment site.",
            ],
            "rules": [
                "Read rules before attending; rule breaches can lead to removal without refund.",
                "Take all litter home.",
                "Do not bring your own nets, mats or slings onto site.",
                "Under-18 anglers must be accompanied by a responsible adult.",
            ],
        },
    ),
}


class VenueIntelligenceService:
    def __init__(
        self,
        weather_service: WeatherService | None = None,
        source_connectors: list[VenueSourceConnector] | None = None,
    ) -> None:
        self.weather_service = weather_service or WeatherService()
        self.source_connectors = source_connectors if source_connectors is not None else default_venue_source_connectors()

    def lookup(self, query: str) -> VenueIntelligenceReport:
        try:
            source_key, source_pack = self._match_pack(query)
        except ValueError:
            return self._lookup_dynamic(query)
        raw = source_pack.report
        venue = raw["suggested_venue"]
        weather = self._weather_for_venue(venue)
        connector_statuses, connector_evidence, external_place = self._run_source_connectors(query, venue)
        enriched_venue = self._venue_with_external_location(venue, external_place)
        map_assets = list(raw.get("map_assets", []))
        return VenueIntelligenceReport(
            query=query,
            matched_key=source_key,
            confidence_score=88 if source_key == "linear-fisheries" else 92,
            suggested_venue=enriched_venue,
            summary=raw["summary"],
            external_place=external_place,
            swims=list(raw.get("swims", [])),
            map_assets=map_assets,
            news_items=list(raw.get("news_items", [])),
            catch_reports=list(raw.get("catch_reports", [])),
            source_evidence=[*list(raw.get("source_evidence", [])), *connector_evidence],
            connector_statuses=connector_statuses,
            weather=weather,
            licensing_notes=self._licensing_notes(map_assets),
            data_gaps=list(raw.get("data_gaps", [])),
            ethical_warnings=[
                "Never disturb spawning fish.",
                "Follow fishery rules, fish care requirements and local law before acting on any recommendation.",
            ],
        )

    def _lookup_dynamic(self, query: str) -> VenueIntelligenceReport:
        venue_name = " ".join(query.strip().split()) or "Unknown fishery"
        matched_key = f"dynamic-{self._slug(venue_name)}"[:64]
        venue = Venue(
            id=matched_key,
            name=venue_name,
            type=VenueType.unknown,
            location_label=None,
            privacy_level=PrivacyLevel.private,
        )
        connector_statuses, connector_evidence, external_place = self._run_source_connectors(query, venue)
        enriched_venue = self._venue_with_external_location(venue, external_place)
        weather = self._weather_for_venue(enriched_venue)
        anglingai_active = any(
            status.connector_name == "anglingai_venue_research" and status.status == "active"
            for status in connector_statuses
        )
        if not anglingai_active:
            raise ValueError(
                f"AnglingAI venue research did not return live data for '{venue_name}'. "
                "Check the backend AnglingAI key, quota and endpoint availability."
            )
        google_active = external_place is not None
        confidence_score = 72 if anglingai_active and google_active else 60 if anglingai_active else 45
        advisory_items = [
            evidence.summary
            for evidence in connector_evidence
            if evidence.source_type.startswith("external_ai")
        ]
        location_tail = f" near {external_place.formatted_address}" if external_place and external_place.formatted_address else ""
        summary = (
            f"{venue_name}{location_tail} has a dynamic CarpCraft profile built from AnglingAI venue research and directory/source links. "
            "Treat this profile as advisory until fishery rules, costs, access and maps are reviewed from cited sources."
        )
        if advisory_items:
            summary = f"{summary} AnglingAI returned advisory context for: {', '.join(self._advisory_titles(connector_evidence))}."
        return VenueIntelligenceReport(
            query=query,
            matched_key=matched_key,
            confidence_score=confidence_score,
            suggested_venue=enriched_venue,
            summary=summary,
            external_place=external_place,
            swims=[],
            map_assets=[],
            news_items=[],
            catch_reports=[],
            source_evidence=connector_evidence,
            connector_statuses=connector_statuses,
            weather=weather,
            licensing_notes=[],
            data_gaps=[
                "Dynamic profile is not source-pack verified; review cited official fishery pages before trusting rules, costs, access or lake details.",
                "AnglingAI output is advisory evidence and must be grounded against current fishery sources and your private session logs.",
                "Lake/swim/depth maps need fishery-approved links or licensing review before caching.",
            ],
            ethical_warnings=[
                "Never disturb spawning fish.",
                "Follow fishery rules, fish care requirements and local law before acting on any recommendation.",
            ],
        )

    @staticmethod
    def _slug(value: str) -> str:
        normalized = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
        return normalized or "fishery"

    @staticmethod
    def _advisory_titles(evidence: list[VenueSourceEvidence]) -> list[str]:
        titles = [
            item.title
            for item in evidence
            if item.source_name == "AnglingAI" and item.source_type == "external_ai_advisory_context"
        ]
        return titles[:5] or ["venue research"]

    def _match_pack(self, query: str) -> tuple[str, VenueIntelligenceSourcePack]:
        normalized = query.strip().lower()
        for key, pack in SOURCE_PACKS.items():
            if any(alias in normalized for alias in pack.aliases):
                return key, pack
        supported = ", ".join(sorted(SOURCE_PACKS))
        raise ValueError(f"No grounded venue intelligence pack found for '{query}'. Supported test packs: {supported}.")

    def _run_source_connectors(
        self,
        query: str,
        venue: Venue,
    ) -> tuple[list[VenueConnectorStatus], list[VenueSourceEvidence], VenueExternalPlace | None]:
        statuses: list[VenueConnectorStatus] = []
        evidence: list[VenueSourceEvidence] = []
        external_place: VenueExternalPlace | None = None
        for connector in self.source_connectors:
            result = connector.enrich(query, venue)
            statuses.append(result.status)
            evidence.extend(result.evidence)
            if external_place is None and result.external_place is not None:
                external_place = result.external_place
        return statuses, evidence, external_place

    @staticmethod
    def _venue_with_external_location(venue: Venue, external_place: VenueExternalPlace | None) -> Venue:
        if external_place is None:
            return venue
        if venue.approximate_latitude is not None and venue.approximate_longitude is not None:
            return venue
        if external_place.latitude is None or external_place.longitude is None:
            return venue
        return venue.model_copy(
            update={
                "approximate_latitude": external_place.latitude,
                "approximate_longitude": external_place.longitude,
                "location_label": venue.location_label or external_place.formatted_address,
            }
        )

    @staticmethod
    def _licensing_notes(map_assets: list[VenueMapAsset]) -> list[str]:
        if not map_assets:
            return []
        notes = [
            "Public map and depth-map assets are stored as links only unless a licensing review marks them cacheable.",
        ]
        for asset in map_assets:
            if not asset.cache_allowed:
                notes.append(f"{asset.title}: cache blocked ({asset.license_status}).")
        return notes

    def _weather_for_venue(self, venue: Venue) -> VenueWeatherIntelligence | None:
        if venue.approximate_latitude is None or venue.approximate_longitude is None:
            return None
        snapshot = self.weather_service.get_snapshot(
            WeatherLookupRequest(
                latitude=venue.approximate_latitude,
                longitude=venue.approximate_longitude,
                location_label=venue.location_label,
            )
        )
        return VenueWeatherIntelligence(
            source=str(snapshot.get("source", "multi_provider")),
            air_temp_c=snapshot.get("air_temp_c") if isinstance(snapshot.get("air_temp_c"), int | float) else None,
            pressure_hpa=snapshot.get("pressure_hpa") if isinstance(snapshot.get("pressure_hpa"), int | float) else None,
            wind_speed_mps=snapshot.get("wind_speed_mps") if isinstance(snapshot.get("wind_speed_mps"), int | float) else None,
            wind_direction_degrees=snapshot.get("wind_direction_degrees")
            if isinstance(snapshot.get("wind_direction_degrees"), int | float)
            else None,
            rainfall_mm=snapshot.get("rainfall_mm") if isinstance(snapshot.get("rainfall_mm"), int | float) else None,
            humidity_percent=snapshot.get("humidity_percent") if isinstance(snapshot.get("humidity_percent"), int | float) else None,
            data_gaps=[str(gap) for gap in snapshot.get("data_gaps", [])],
        )
