from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from app.schemas.domain import (
    PrivacyLevel,
    Venue,
    VenueIntelligenceReport,
    VenueMapAsset,
    VenueNewsItem,
    VenueSourceEvidence,
    VenueSwimIntelligence,
    VenueType,
    VenueWeatherIntelligence,
)
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
                "The intelligence pack links official waters, map, rules, Catch booking references and latest-catch pages."
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
                    stock_notes="Listed by Linear as a day-ticket water and referenced for Catch bookings.",
                    source_url="https://www.linear-fisheries.co.uk/index.cfm?fuseaction=waters.start",
                ),
                VenueSwimIntelligence(
                    name="Manor Farm Lake",
                    stock_notes="Listed by Linear as a day-ticket water and referenced for Catch bookings.",
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
            "news_items": [
                _news(
                    title="Catch booking reference",
                    summary="Linear states that Manor Farm, Hunts Corner and Tar Farm Lakes bookings are available through GoCatch/Catch.",
                    url="https://www.linear-fisheries.co.uk/",
                    source_name="Linear Fisheries",
                )
            ],
            "source_evidence": [
                _source(
                    "Linear Fisheries",
                    "official_fishery_site",
                    "https://www.linear-fisheries.co.uk/",
                    "Official Linear Fisheries homepage",
                    "Official source for fishery overview, rules, maps, latest catches and Catch booking references.",
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
                    "Catch / GoCatch",
                    "booking_directory",
                    "https://www.gocatch.fish/",
                    "Catch venue and booking platform",
                    "Linear links bookings for selected waters through the GoCatch/Catch platform.",
                    75,
                ),
            ],
            "data_gaps": [
                "Individual swim boundaries and detailed bathymetry are not normalized yet from official Linear map images.",
                "Catch App and Facebook group data should be consumed through official APIs, user-provided links or explicit venue permission.",
                "Do not infer current form from latest-catch reports without your own session evidence.",
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
                    "official_depth_map",
                    "https://www.embryoangling.org/venue/pettitts-lake/",
                    "Pettitt's Lake depth-map page",
                    "Official page links a high-resolution/downloadable depth map and explains lake features.",
                    95,
                ),
            ],
            "data_gaps": [
                "Public Facebook and Instagram updates are referenced by Embryo but should not be scraped without permission or a proper connector.",
                "Depth maps need licensing review before caching image copies inside the app.",
                "Current catch reports should be separated from static stock lists before feeding recommendation logic.",
            ],
        },
    ),
}


class VenueIntelligenceService:
    def __init__(self, weather_service: WeatherService | None = None) -> None:
        self.weather_service = weather_service or WeatherService()

    def lookup(self, query: str) -> VenueIntelligenceReport:
        source_key, source_pack = self._match_pack(query)
        raw = source_pack.report
        venue = raw["suggested_venue"]
        weather = self._weather_for_venue(venue)
        return VenueIntelligenceReport(
            query=query,
            matched_key=source_key,
            confidence_score=88 if source_key == "linear-fisheries" else 92,
            suggested_venue=venue,
            summary=raw["summary"],
            swims=list(raw.get("swims", [])),
            map_assets=list(raw.get("map_assets", [])),
            news_items=list(raw.get("news_items", [])),
            catch_reports=list(raw.get("catch_reports", [])),
            source_evidence=list(raw.get("source_evidence", [])),
            weather=weather,
            data_gaps=list(raw.get("data_gaps", [])),
            ethical_warnings=[
                "Never disturb spawning fish.",
                "Follow fishery rules, fish care requirements and local law before acting on any recommendation.",
            ],
        )

    def _match_pack(self, query: str) -> tuple[str, VenueIntelligenceSourcePack]:
        normalized = query.strip().lower()
        for key, pack in SOURCE_PACKS.items():
            if any(alias in normalized for alias in pack.aliases):
                return key, pack
        supported = ", ".join(sorted(SOURCE_PACKS))
        raise ValueError(f"No grounded venue intelligence pack found for '{query}'. Supported test packs: {supported}.")

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
