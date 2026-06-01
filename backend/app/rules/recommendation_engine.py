from __future__ import annotations

from app.schemas.domain import ObservationType, RecommendationContext, RecommendationResult


class RecommendationEngine:
    """Deterministic watercraft rules for the first intelligence version."""

    def generate(self, context: RecommendationContext) -> RecommendationResult:
        confidence = 80
        location_score = 50
        feeding_window_score = 50
        presentation_fit_score = 50
        oxygen_comfort_score = 70
        pressure_risk_score = 40

        evidence: list[str] = []
        gaps: list[str] = []
        tactic_notes: list[str] = []
        recommended_zone = "best evidenced water available"
        recommended_baiting = "moderate"
        recommended_layer = "bottom or low layer"
        fish_welfare_warning: str | None = None

        def cap_confidence(limit: int, reason: str) -> None:
            nonlocal confidence
            if confidence > limit:
                confidence = limit
            gaps.append(reason)

        if context.water_temp_c is None:
            cap_confidence(65, "Water temperature is missing, so confidence is capped.")
        else:
            evidence.append(f"Water temperature logged at {context.water_temp_c:.1f}C.")
            if context.water_temp_c < 8:
                recommended_baiting = "low"
                feeding_window_score -= 15
                tactic_notes.append("Keep baiting low and precise in cold water.")
            elif 8 <= context.water_temp_c < 14:
                signs = self._count_signs(context)
                recommended_baiting = "light to moderate" if signs else "light"
                feeding_window_score += 5 if signs else -5
                tactic_notes.append("Match baiting to visible signs rather than spreading bait widely.")
            elif 14 <= context.water_temp_c <= 20:
                recommended_baiting = "moderate"
                feeding_window_score += 15
                tactic_notes.append("Feeding potential can improve in this range, but pressure and oxygen still matter.")
            else:
                recommended_baiting = "low to moderate"
                oxygen_comfort_score -= 20
                tactic_notes.append("Warm water raises oxygen risk; avoid heavy baiting until oxygen comfort is clearer.")

        if context.venue_history_sessions < 10:
            cap_confidence(50, "Venue history has fewer than 10 sessions, so pattern confidence is weak.")
        else:
            evidence.append(f"Venue history includes {context.venue_history_sessions} sessions.")

        hot_summer_like = (context.air_temp_c is not None and context.air_temp_c >= 24) or (
            context.water_temp_c is not None and context.water_temp_c >= 20
        )
        still_conditions = context.wind_speed_mps is None or context.wind_speed_mps < 2
        weedy = context.weed_density is not None and context.weed_density >= 7

        if hot_summer_like and context.dissolved_oxygen_mg_l is None:
            cap_confidence(65, "Dissolved oxygen is missing in hot summer-like conditions.")

        if context.dissolved_oxygen_mg_l is not None:
            evidence.append(f"Dissolved oxygen logged at {context.dissolved_oxygen_mg_l:.1f} mg/L.")
            if context.dissolved_oxygen_mg_l < 5:
                oxygen_comfort_score -= 30
                recommended_layer = "upper layers, inflows, windward water or shade"
                tactic_notes.append("Low dissolved oxygen makes comfort and fish welfare a priority.")

        if hot_summer_like and still_conditions and weedy:
            oxygen_comfort_score -= 25
            recommended_layer = "upper layers, inflows, windward water or shaded margins"
            tactic_notes.append("Hot, still and weedy conditions increase oxygen risk.")

        if context.wind_has_pushed_hours is not None and context.wind_has_pushed_hours >= 3:
            location_score += 20
            recommended_zone = "windward bank or water pushed by sustained wind"
            evidence.append("A sustained wind has pushed into a bank for several hours.")
            tactic_notes.append("Give windward water extra attention if it is safe and not over-pressured.")

        if context.angling_pressure_count is not None:
            evidence.append(f"Angling pressure count logged as {context.angling_pressure_count}.")
            pressure_risk_score = min(100, context.angling_pressure_count * 12)
            if context.angling_pressure_count >= 5:
                location_score -= 10
                tactic_notes.append("High pressure favours quieter water, edges or overlooked lines.")

        if any(signal.away_from_current_rods and signal.observation_type == ObservationType.show for signal in context.observations):
            location_score += 15
            recommended_zone = "area where shows were logged"
            tactic_notes.append("Shows away from the rods support an observation-led move or one mobile rod.")

        if context.liners_without_takes or any(signal.observation_type == ObservationType.liner for signal in context.observations):
            presentation_fit_score -= 10
            tactic_notes.append("Liners without takes suggest checking presentation, depth or layer.")

        if context.spawning_indicators or any(
            signal.observation_type == ObservationType.spawning_indicator for signal in context.observations
        ):
            confidence = min(confidence, 40)
            fish_welfare_warning = "Possible spawning indicators logged. Do not disturb spawning fish; follow fishery rules and move away if needed."
            tactic_notes.append("Fish welfare overrides tactical opportunity.")

        if not evidence:
            confidence = min(confidence, 45)
            gaps.append("Evidence quality is weak; add observations, readings and outcomes before trusting patterns.")

        location_score = self._clamp(location_score)
        feeding_window_score = self._clamp(feeding_window_score)
        presentation_fit_score = self._clamp(presentation_fit_score)
        oxygen_comfort_score = self._clamp(oxygen_comfort_score)
        pressure_risk_score = self._clamp(pressure_risk_score)
        confidence = self._clamp(confidence)

        summary = "Work from the strongest logged evidence, keep the plan reversible, and review outcomes after the session."
        tactic = " ".join(tactic_notes) if tactic_notes else "Hold a balanced starting approach and gather more evidence before committing."

        return RecommendationResult(
            recommendation_summary=summary,
            location_score=location_score,
            feeding_window_score=feeding_window_score,
            presentation_fit_score=presentation_fit_score,
            oxygen_comfort_score=oxygen_comfort_score,
            pressure_risk_score=pressure_risk_score,
            confidence_score=confidence,
            recommended_zone=recommended_zone,
            recommended_tactic=tactic,
            recommended_baiting_level=recommended_baiting,
            recommended_depth_or_layer=recommended_layer,
            evidence_summary=evidence or ["No strong evidence logged yet."],
            data_gaps=self._dedupe(gaps),
            alternative_plan="If the chosen line stays quiet, keep one option mobile and prioritise fresh observations over old assumptions.",
            fish_welfare_warning=fish_welfare_warning,
        )

    @staticmethod
    def _count_signs(context: RecommendationContext) -> int:
        positive_types = {
            ObservationType.show,
            ObservationType.fizzing,
            ObservationType.bubbling,
            ObservationType.rolling,
            ObservationType.crashing,
            ObservationType.slick,
            ObservationType.clouding,
        }
        return sum(signal.count for signal in context.observations if signal.observation_type in positive_types)

    @staticmethod
    def _clamp(value: int) -> int:
        return max(0, min(100, round(value)))

    @staticmethod
    def _dedupe(items: list[str]) -> list[str]:
        seen: set[str] = set()
        output: list[str] = []
        for item in items:
            if item not in seen:
                output.append(item)
                seen.add(item)
        return output
