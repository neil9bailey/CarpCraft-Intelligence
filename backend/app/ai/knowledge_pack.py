from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class KnowledgeSnippet:
    """A single grounded carp-watercraft knowledge note.

    Snippets are curated, source-attributed watercraft principles. They are not
    venue facts, catch history or fishery rules, and they never guarantee
    catches. Private venue notes are stored separately and access-controlled.
    """

    category: str
    title: str
    snippet: str
    keywords: tuple[str, ...] = field(default_factory=tuple)
    source: str = "CarpCraft curated watercraft knowledge"


# A compact, grounded corpus. Each note encodes a widely accepted carp
# watercraft principle phrased cautiously so downstream wording stays honest.
KNOWLEDGE_PACK: tuple[KnowledgeSnippet, ...] = (
    KnowledgeSnippet(
        category="carp_biology",
        title="Carp are ectotherms",
        snippet=(
            "Carp are cold-blooded, so their metabolism, digestion and willingness to feed track water "
            "temperature closely. Expect shorter, less frequent feeding spells as water cools."
        ),
        keywords=("metabolism", "temperature", "feeding", "cold", "ectotherm", "biology"),
    ),
    KnowledgeSnippet(
        category="water_temperature_and_metabolism",
        title="Temperature bands and baiting",
        snippet=(
            "Below roughly 8C, feeding is slow and bait should stay minimal and tight. Between about 14-20C "
            "feeding potential rises. A rising water temperature is often a stronger feeding trigger than the "
            "absolute value."
        ),
        keywords=("temperature", "baiting", "rising", "trend", "metabolism", "cold", "warm"),
    ),
    KnowledgeSnippet(
        category="dissolved_oxygen_and_weed_dynamics",
        title="Oxygen risk in heat",
        snippet=(
            "Hot, still, weedy water can drop in dissolved oxygen, especially overnight and at dawn. In these "
            "conditions fish welfare comes first: look to inflows, windward water, shade and upper layers."
        ),
        keywords=("oxygen", "dissolved", "weed", "heat", "summer", "welfare", "inflow", "windward"),
    ),
    KnowledgeSnippet(
        category="seasonal_behaviour_and_spawning",
        title="Seasonal location shifts",
        snippet=(
            "In spring carp seek the warmest sun-exposed water; in autumn they often feed hard before winter; "
            "in winter location matters far more than bait volume. Never disturb fish showing spawning behaviour."
        ),
        keywords=("season", "spring", "autumn", "winter", "spawning", "location", "welfare"),
    ),
    KnowledgeSnippet(
        category="weather_wind_pressure_and_light",
        title="Pressure and wind",
        snippet=(
            "Falling barometric pressure ahead of a front often triggers a feeding spell. Warm winds (commonly "
            "south-westerly in the UK) are worth following onto the windward bank, while cold winds can push fish "
            "onto sheltered, warmer back banks. Low light at dawn and dusk is frequently the most productive window."
        ),
        keywords=("pressure", "barometric", "wind", "front", "windward", "dawn", "dusk", "light", "weather"),
    ),
    KnowledgeSnippet(
        category="baiting_strategy",
        title="Match bait to evidence",
        snippet=(
            "Let visible signs and conditions set bait volume rather than a fixed amount. Feed lightly and tightly "
            "when fish are scarce or cold, and only scale up when activity, temperature and recent form support it."
        ),
        keywords=("bait", "baiting", "feed", "volume", "tight", "spread", "strategy"),
    ),
    KnowledgeSnippet(
        category="rig_and_presentation_logic",
        title="Reading presentation from indications",
        snippet=(
            "Repeated liners without takes suggest fish are present but the presentation, depth or layer is off. "
            "Under bright, settled high pressure in warm weather, fish may sit high in the water, where zigs or "
            "surface baits can score."
        ),
        keywords=("rig", "presentation", "liner", "zig", "surface", "depth", "layer"),
    ),
    KnowledgeSnippet(
        category="fish_care_and_welfare",
        title="Welfare overrides tactics",
        snippet=(
            "Use appropriate unhooking mats, slings and care kit, retain fish for the shortest time, and in low "
            "oxygen or spawning conditions reduce angling pressure. Welfare always overrides tactical opportunity."
        ),
        keywords=("welfare", "care", "unhooking", "mat", "spawning", "oxygen", "ethics"),
    ),
    KnowledgeSnippet(
        category="fishery_rules",
        title="Defer to local fishery rules",
        snippet=(
            "Fishery rules, byelaws and close seasons take precedence over any general tactic. Confirm current "
            "rules from the official fishery source before fishing; this knowledge pack does not replace them."
        ),
        keywords=("rules", "byelaw", "close season", "fishery", "compliance"),
    ),
)


def snippets_for_categories(categories: list[str]) -> list[KnowledgeSnippet]:
    requested = set(categories)
    return [snippet for snippet in KNOWLEDGE_PACK if snippet.category in requested]
