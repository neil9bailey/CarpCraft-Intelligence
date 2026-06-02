from __future__ import annotations

from app.core.auth import Principal
from app.schemas.domain import (
    AIEvidenceItem,
    AIIntelligenceBrief,
    AIIntelligenceBriefInput,
    BottomCondition,
    WeedCondition,
)


def _enum_values(values: list[object]) -> set[str]:
    return {getattr(value, "value", str(value)) for value in values}


class AIIntelligenceService:
    """Grounded advisory brief builder for future AI/MCP orchestration."""

    def build_brief(self, context: AIIntelligenceBriefInput, principal: Principal) -> AIIntelligenceBrief:
        evidence: list[AIEvidenceItem] = []
        recommendations: list[str] = []
        data_gaps: list[str] = []
        confidence = 25

        if context.weather is None:
            data_gaps.append("Live weather has not been attached to this session.")
        else:
            weather = context.weather
            if weather.air_temp_c is not None:
                evidence.append(
                    AIEvidenceItem(
                        source_type="weather",
                        summary=f"Air temperature {weather.air_temp_c:.1f} C from {weather.source}.",
                        confidence=70,
                    )
                )
                confidence += 8
            if weather.approx_surface_temp_c is not None:
                evidence.append(
                    AIEvidenceItem(
                        source_type="weather",
                        summary=(
                            f"Approximate surface temperature {weather.approx_surface_temp_c:.1f} C "
                            f"({weather.approx_surface_temp_confidence}% confidence)."
                        ),
                        confidence=weather.approx_surface_temp_confidence,
                    )
                )
                confidence += 10
            if weather.wind_speed_mps is not None and weather.wind_direction_label:
                recommendations.append(
                    f"Check water pushed by the {weather.wind_direction_label} wind first, then validate with shows or liners before committing bait."
                )
                confidence += 8
            if weather.precipitation_intensity in {"moderate", "heavy"}:
                recommendations.append("Keep notes on water clarity and runoff; heavy rain can move fish but also change presentation confidence.")
            data_gaps.extend(weather.data_gaps[:4])

        if context.observations:
            confidence += min(len(context.observations) * 5, 15)
            evidence.append(
                AIEvidenceItem(
                    source_type="observation",
                    summary="User observations: " + "; ".join(context.observations[:4]),
                    confidence=80,
                )
            )
            recommendations.append("Give recent visual evidence more weight than historical form until the session produces a repeatable pattern.")
        else:
            data_gaps.append("No live observations have been logged yet.")

        if context.bottom_conditions:
            bottom_values = _enum_values(context.bottom_conditions)
            evidence.append(
                AIEvidenceItem(
                    source_type="bottom_condition",
                    summary="Bottom notes: " + ", ".join(sorted(bottom_values)),
                    confidence=75,
                )
            )
            confidence += 8
            if BottomCondition.silt.value in bottom_values:
                recommendations.append("On silt, record lead feel and favour presentations that avoid burying the hook bait.")
            if BottomCondition.gravel.value in bottom_values or BottomCondition.smooth_clay.value in bottom_values:
                recommendations.append("Harder spots are worth validating with repeat casts before increasing bait.")

        if context.weed_conditions:
            weed_values = _enum_values(context.weed_conditions)
            evidence.append(
                AIEvidenceItem(
                    source_type="weed_condition",
                    summary="Weed notes: " + ", ".join(sorted(weed_values)),
                    confidence=75,
                )
            )
            confidence += 8
            if weed_values - {WeedCondition.none.value, WeedCondition.unknown.value}:
                recommendations.append("Where weed is present, mark clear presentation pockets and record any cleaned-off rigs.")

        if context.recent_captures:
            evidence.append(
                AIEvidenceItem(
                    source_type="capture_asset",
                    summary=f"{len(context.recent_captures)} private capture asset(s) are available for this brief.",
                    confidence=70,
                )
            )
            confidence += min(len(context.recent_captures) * 4, 12)
        else:
            data_gaps.append("No photos, annotated maps or rig/catch captures are attached yet.")

        safety_warnings = [
            "Never disturb spawning fish.",
            "Follow current fishery rules, fish care requirements and local law.",
        ]
        if context.spawning_indicators:
            recommendations = ["Pause angling pressure around suspected spawning activity and move away from fish showing spawning behaviour."]
            safety_warnings.insert(0, "Spawning indicators were logged; welfare overrides tactical recommendations.")
            confidence = min(confidence, 45)

        if not recommendations:
            recommendations.append("Start with observation: wind, shows, liners, water clarity, depth and bottom feel before committing a main area.")

        if context.venue_id is None:
            data_gaps.append("Venue is missing, so fishery-specific rules and lake profile evidence cannot be used.")
        if context.session_id is None:
            data_gaps.append("Session is missing, so the brief is not attached to a live log yet.")

        return AIIntelligenceBrief(
            owner_user_id=principal.user_id,
            session_id=context.session_id,
            confidence_score=min(confidence, 82),
            headline="Grounded live-session brief",
            recommendations=recommendations,
            evidence=evidence,
            data_gaps=list(dict.fromkeys(data_gaps)),
            safety_warnings=safety_warnings,
        )

    def example_brief(self, principal: Principal) -> AIIntelligenceBrief:
        context = AIIntelligenceBriefInput(
            session_id="example-live-session",
            venue_id="example-fishery",
            live_session_notes="First light session with wind pushing into reed corner.",
            observations=["Two shows at 70-80 yards off the reedline", "One liner on the middle rod"],
            bottom_conditions=[BottomCondition.silt, BottomCondition.gravel],
            weed_conditions=[WeedCondition.silk_weed],
        )
        return self.build_brief(context, principal)
