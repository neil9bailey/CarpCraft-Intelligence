from __future__ import annotations

from app.schemas.domain import ObservationType, RecommendationContext, RecommendationResult

# Compass quarters used to read wind "character" rather than just direction.
_WARM_WIND_QUARTER = {"S", "SSW", "SW", "WSW", "W", "SSE"}
_COLD_WIND_QUARTER = {"N", "NNE", "NE", "ENE", "E", "NNW"}

# Action priority bands (lower number = surfaced first). Welfare always wins.
_PRIORITY_WELFARE = 0
_PRIORITY_LOCATION = 1
_PRIORITY_TIMING = 2
_PRIORITY_PRESENTATION = 3
_PRIORITY_BAITING = 4


class _Plan:
    """Mutable scoring accumulator for a single recommendation pass.

    Keeping all the deterministic state in one place lets each watercraft factor
    contribute evidence, gaps, score nudges and prioritised actions without a web
    of closures, while confidence stays strictly cap-only so the engine can never
    talk itself into overconfidence.
    """

    def __init__(self) -> None:
        self.confidence = 80
        self.location_score = 50
        self.feeding_window_score = 50
        self.presentation_fit_score = 50
        self.oxygen_comfort_score = 70
        self.pressure_risk_score = 40

        self.evidence: list[str] = []
        self.gaps: list[str] = []
        self.tactic_notes: list[str] = []
        self.prime_windows: list[str] = []
        self._actions: list[tuple[int, str]] = []

        self.recommended_zone = "best evidenced water available"
        self.recommended_baiting = "moderate"
        self.recommended_layer = "bottom or low layer"
        self.seasonal_context: str | None = None
        self.barometric_note: str | None = None
        self.fish_welfare_warning: str | None = None

    def cap_confidence(self, limit: int, reason: str) -> None:
        if self.confidence > limit:
            self.confidence = limit
        self.gaps.append(reason)

    def add_action(self, priority: int, text: str) -> None:
        self._actions.append((priority, text))

    def ordered_actions(self) -> list[str]:
        ordered: list[str] = []
        seen: set[str] = set()
        for _, text in sorted(self._actions, key=lambda item: item[0]):
            if text not in seen:
                ordered.append(text)
                seen.add(text)
        return ordered


class RecommendationEngine:
    """Deterministic, evidence-ranked watercraft rules for carp angling.

    The engine ranks logged evidence into a reversible session plan. It never
    guarantees catches, always reports confidence and data gaps, and lets fish
    welfare override tactical opportunity.
    """

    def generate(self, context: RecommendationContext) -> RecommendationResult:
        plan = _Plan()

        self._apply_water_temp(context, plan)
        self._apply_season(context, plan)
        self._apply_time_of_day(context, plan)
        self._apply_water_temp_trend(context, plan)
        self._apply_barometric_pressure(context, plan)
        self._apply_venue_history(context, plan)
        self._apply_oxygen_risk(context, plan)
        self._apply_wind(context, plan)
        self._apply_angling_pressure(context, plan)
        self._apply_observations(context, plan)
        self._apply_recent_form(context, plan)
        self._apply_solunar(context, plan)
        self._apply_spawning(context, plan)

        if not plan.evidence:
            plan.confidence = min(plan.confidence, 45)
            plan.gaps.append(
                "Evidence quality is weak; add observations, readings and outcomes before trusting patterns."
            )

        return self._finalise(plan)

    # ------------------------------------------------------------------
    # Watercraft factors
    # ------------------------------------------------------------------
    def _apply_water_temp(self, context: RecommendationContext, plan: _Plan) -> None:
        if context.water_temp_c is None:
            plan.cap_confidence(65, "Water temperature is missing, so confidence is capped.")
            return

        plan.evidence.append(f"Water temperature logged at {context.water_temp_c:.1f}C.")
        if context.water_temp_c < 8:
            plan.recommended_baiting = "low"
            plan.feeding_window_score -= 15
            plan.tactic_notes.append("Keep baiting low and precise in cold water.")
            plan.add_action(_PRIORITY_BAITING, "Feed little-and-tight; in cold water bait volume rarely earns extra bites.")
        elif 8 <= context.water_temp_c < 14:
            signs = self._count_signs(context)
            plan.recommended_baiting = "light to moderate" if signs else "light"
            plan.feeding_window_score += 5 if signs else -5
            plan.tactic_notes.append("Match baiting to visible signs rather than spreading bait widely.")
        elif 14 <= context.water_temp_c <= 20:
            plan.recommended_baiting = "moderate"
            plan.feeding_window_score += 15
            plan.tactic_notes.append("Feeding potential can improve in this range, but pressure and oxygen still matter.")
        else:
            plan.recommended_baiting = "low to moderate"
            plan.oxygen_comfort_score -= 20
            plan.tactic_notes.append("Warm water raises oxygen risk; avoid heavy baiting until oxygen comfort is clearer.")

    def _apply_season(self, context: RecommendationContext, plan: _Plan) -> None:
        if context.month is None:
            plan.gaps.append("Month is not set, so seasonal watercraft context is not applied.")
            return

        season = self._season_for_month(context.month)
        plan.evidence.append(f"Seasonal context: {season}.")
        if season == "winter":
            plan.feeding_window_score -= 12
            plan.seasonal_context = (
                "Winter: carp metabolism is low and feeding spells are short. Location matters far more than bait volume; "
                "look for stable, deeper water or any spot warmed by winter sun."
            )
            plan.prime_windows.append("Late morning to mid-afternoon, especially in any winter sun.")
            plan.tactic_notes.append("In winter, find the fish first and keep bait minimal and tight.")
            plan.add_action(_PRIORITY_LOCATION, "Prioritise locating wintering fish (deeper, stable or sun-warmed water) before committing bait.")
        elif season == "spring":
            plan.feeding_window_score += 8
            plan.seasonal_context = (
                "Spring: warming water can switch carp on quickly, with strong pre-spawn feeding. Watch for spawning behaviour "
                "as the season progresses and back off if you see it."
            )
            plan.prime_windows.extend(["First light", "Afternoon warmth after mild days", "Dusk"])
            plan.tactic_notes.append("Target the warmest water that catches the sun, especially after a run of mild days.")
            plan.add_action(_PRIORITY_LOCATION, "Check the warmest sun-exposed water first (shallow bays, sun-facing banks).")
        elif season == "summer":
            plan.feeding_window_score += 6
            plan.seasonal_context = (
                "Summer: the best feeding is often at first light, last light and through the night. Watch dissolved oxygen "
                "in heat, and expect fish to hold high in the water in bright, settled spells."
            )
            plan.prime_windows.extend(["First light", "Last light into dark", "Through the night"])
            plan.tactic_notes.append("In bright, hot, settled spells consider surface or zig fishing for fish holding high in the water.")
        else:  # autumn
            plan.feeding_window_score += 12
            plan.seasonal_context = (
                "Autumn: carp often feed hard to build reserves before winter. This is a strong window, and fish will frequently "
                "take a more generous bait application, especially as fronts move through."
            )
            plan.prime_windows.extend(["First light", "Dusk", "After a mild, wet, windy front"])
            plan.tactic_notes.append("Autumn fish will often take a bigger bait application; follow fresh winds and coloured water.")
            plan.add_action(_PRIORITY_LOCATION, "Follow new winds and coloured water as autumn fronts move fish around.")

    def _apply_time_of_day(self, context: RecommendationContext, plan: _Plan) -> None:
        if context.is_first_or_last_light:
            plan.feeding_window_score += 12
            plan.evidence.append("Session is in or near a first/last-light window.")
            plan.tactic_notes.append("You are in or near a prime low-light feeding window; stay alert and keep disturbance low.")
            plan.add_action(_PRIORITY_TIMING, "Fish hard through this low-light window and minimise disturbance.")
            return

        if context.local_hour is None:
            return

        hour = context.local_hour
        if hour in range(4, 8) or hour in range(18, 22):
            plan.feeding_window_score += 10
            plan.evidence.append(f"Local time ({hour:02d}:00) falls in a typical low-light feeding window.")
            plan.tactic_notes.append("Dawn and dusk are reliable carp feeding windows; concentrate effort and stay quiet.")
            plan.add_action(_PRIORITY_TIMING, "Make the most of this dawn/dusk window before the light changes.")
        elif hour in range(11, 16):
            plan.evidence.append(f"Local time ({hour:02d}:00) is the middle of the day.")
            if context.month is not None and self._season_for_month(context.month) == "winter":
                plan.feeding_window_score += 6
                plan.tactic_notes.append("In winter the warmest part of the day can be the best feeding window.")
            else:
                plan.tactic_notes.append("Bright midday spells can be slower; watch for fish moving up in the water.")

    def _apply_water_temp_trend(self, context: RecommendationContext, plan: _Plan) -> None:
        trend = context.water_temp_trend_c_24h
        if trend is None:
            return

        if trend >= 0.5:
            plan.feeding_window_score += 8
            plan.evidence.append(f"Water temperature is rising ({trend:+.1f}C / 24h).")
            plan.tactic_notes.append("A rising water temperature is a positive feeding trigger; fish with intent.")
            plan.add_action(_PRIORITY_TIMING, "Capitalise on rising water temperature, which often lifts feeding activity.")
        elif trend <= -0.5:
            plan.feeding_window_score -= 8
            plan.evidence.append(f"Water temperature is falling ({trend:+.1f}C / 24h).")
            plan.tactic_notes.append("A falling water temperature can slow feeding; scale bait back and expect fewer chances.")
        else:
            plan.evidence.append(f"Water temperature is steady ({trend:+.1f}C / 24h).")

    def _apply_barometric_pressure(self, context: RecommendationContext, plan: _Plan) -> None:
        pressure = context.pressure_hpa
        trend = context.pressure_trend_hpa_3h
        if pressure is None and trend is None:
            plan.gaps.append("Barometric pressure and trend are missing; pressure changes often shift carp feeding.")
            return

        season = self._season_for_month(context.month) if context.month is not None else None

        if trend is not None:
            if trend <= -1.5:
                plan.feeding_window_score += 10
                plan.barometric_note = "Pressure is dropping sharply (a front is approaching); carp often feed hard before unsettled weather arrives."
                plan.evidence.append(f"Barometric pressure is falling ({trend:+.1f} hPa / 3h).")
                plan.add_action(_PRIORITY_TIMING, "Fish ahead of the approaching front while pressure is still falling.")
            elif trend <= -0.5:
                plan.feeding_window_score += 5
                plan.barometric_note = "Pressure is easing lower, which is a mild positive feeding sign."
                plan.evidence.append(f"Barometric pressure is easing ({trend:+.1f} hPa / 3h).")
            elif trend >= 1.5:
                plan.evidence.append(f"Barometric pressure is rising ({trend:+.1f} hPa / 3h).")
                if season == "winter":
                    plan.feeding_window_score += 6
                    plan.barometric_note = "Rising pressure and settling weather can help feeding in cold conditions."
                else:
                    plan.barometric_note = "Rising into higher pressure often settles fish and can push them up in the water."
            elif trend >= 0.5:
                plan.evidence.append(f"Barometric pressure is firming ({trend:+.1f} hPa / 3h).")
            else:
                plan.evidence.append("Barometric pressure is steady.")

        if pressure is not None:
            plan.evidence.append(f"Barometric pressure logged at {pressure:.0f} hPa.")
            if pressure >= 1025:
                if season in {"summer", "spring"} or (context.water_temp_c is not None and context.water_temp_c >= 16):
                    if plan.recommended_layer == "bottom or low layer":
                        plan.recommended_layer = "upper layers or zig presentation"
                    plan.presentation_fit_score -= 5
                    plan.tactic_notes.append("High, settled pressure in warm weather often holds carp high in the water; consider zigs or surface baits.")
                    plan.add_action(_PRIORITY_PRESENTATION, "Try a higher presentation (zig or surface) for fish sitting up under settled high pressure.")
            elif pressure <= 1000:
                plan.pressure_risk_score = min(100, plan.pressure_risk_score + 10)
                plan.tactic_notes.append("Low pressure and unsettled weather can mean active fish but tougher conditions; prioritise safety.")

    def _apply_venue_history(self, context: RecommendationContext, plan: _Plan) -> None:
        if context.venue_history_sessions < 10:
            plan.cap_confidence(50, "Venue history has fewer than 10 sessions, so pattern confidence is weak.")
        else:
            plan.evidence.append(f"Venue history includes {context.venue_history_sessions} sessions.")

    def _apply_oxygen_risk(self, context: RecommendationContext, plan: _Plan) -> None:
        hot_summer_like = (context.air_temp_c is not None and context.air_temp_c >= 24) or (
            context.water_temp_c is not None and context.water_temp_c >= 20
        )
        still_conditions = context.wind_speed_mps is None or context.wind_speed_mps < 2
        weedy = context.weed_density is not None and context.weed_density >= 7

        if hot_summer_like and context.dissolved_oxygen_mg_l is None:
            plan.cap_confidence(65, "Dissolved oxygen is missing in hot summer-like conditions.")

        if context.dissolved_oxygen_mg_l is not None:
            plan.evidence.append(f"Dissolved oxygen logged at {context.dissolved_oxygen_mg_l:.1f} mg/L.")
            if context.dissolved_oxygen_mg_l < 5:
                plan.oxygen_comfort_score -= 30
                plan.recommended_layer = "upper layers, inflows, windward water or shade"
                plan.tactic_notes.append("Low dissolved oxygen makes comfort and fish welfare a priority.")
                plan.add_action(_PRIORITY_LOCATION, "Move towards oxygen-rich water (inflows, windward banks, shade) for fish welfare and feeding.")

        if hot_summer_like and still_conditions and weedy:
            plan.oxygen_comfort_score -= 25
            plan.recommended_layer = "upper layers, inflows, windward water or shaded margins"
            plan.tactic_notes.append("Hot, still and weedy conditions increase oxygen risk.")

    def _apply_wind(self, context: RecommendationContext, plan: _Plan) -> None:
        label = context.wind_direction_label.upper() if context.wind_direction_label else None
        warm_wind = label in _WARM_WIND_QUARTER if label else False
        cold_wind = label in _COLD_WIND_QUARTER if label else False
        season = self._season_for_month(context.month) if context.month is not None else None

        if context.wind_has_pushed_hours is not None and context.wind_has_pushed_hours >= 3:
            plan.location_score += 20
            plan.recommended_zone = "windward bank or water pushed by sustained wind"
            plan.evidence.append("A sustained wind has pushed into a bank for several hours.")
            plan.tactic_notes.append("Give windward water extra attention if it is safe and not over-pressured.")
            plan.add_action(_PRIORITY_LOCATION, "Check the windward bank where sustained wind has been pushing.")
            if warm_wind:
                plan.location_score += 5
                plan.tactic_notes.append(f"A warm {label} wind pushing in is classic follow-the-wind carp water.")

        if cold_wind:
            plan.evidence.append(f"Wind is from a colder quarter ({label}).")
            if season in {"winter", "spring"}:
                plan.tactic_notes.append(
                    f"A cold {label} wind can push fish onto the sheltered back bank; don't always chase the windward water in cold winds."
                )
                plan.add_action(_PRIORITY_LOCATION, "In a cold wind, also check sheltered, warmer water on the back bank.")
        elif warm_wind and (context.wind_has_pushed_hours is None or context.wind_has_pushed_hours < 3):
            plan.evidence.append(f"Wind is from a warmer quarter ({label}).")
            plan.tactic_notes.append(f"A warm {label} wind is worth following if it builds through the session.")

    def _apply_angling_pressure(self, context: RecommendationContext, plan: _Plan) -> None:
        if context.angling_pressure_count is None:
            return
        plan.evidence.append(f"Angling pressure count logged as {context.angling_pressure_count}.")
        plan.pressure_risk_score = min(100, context.angling_pressure_count * 12)
        if context.angling_pressure_count >= 5:
            plan.location_score -= 10
            plan.tactic_notes.append("High pressure favours quieter water, edges or overlooked lines.")
            plan.add_action(_PRIORITY_LOCATION, "Under heavy angling pressure, look for quieter water, margins or overlooked lines.")

    def _apply_observations(self, context: RecommendationContext, plan: _Plan) -> None:
        if any(
            signal.away_from_current_rods and signal.observation_type == ObservationType.show
            for signal in context.observations
        ):
            plan.location_score += 15
            plan.recommended_zone = "area where shows were logged"
            plan.tactic_notes.append("Shows away from the rods support an observation-led move or one mobile rod.")
            plan.add_action(_PRIORITY_LOCATION, "Act on shows away from the rods with an observation-led move or one mobile rod.")

        if context.liners_without_takes or any(
            signal.observation_type == ObservationType.liner for signal in context.observations
        ):
            plan.presentation_fit_score -= 10
            plan.tactic_notes.append("Liners without takes suggest checking presentation, depth or layer.")
            plan.add_action(_PRIORITY_PRESENTATION, "Liners without takes: re-check presentation, depth and whether fish are off bottom.")

    def _apply_recent_form(self, context: RecommendationContext, plan: _Plan) -> None:
        count = context.recent_catch_count_7d
        if count is None:
            return
        if count > 0:
            plan.feeding_window_score += min(count * 2, 8)
            plan.evidence.append(f"{count} catch(es) logged here in the last 7 days; the water has recent form.")
        elif context.venue_history_sessions >= 5:
            plan.gaps.append("No catches logged here in the last 7 days, so recent form is flat.")

    def _apply_solunar(self, context: RecommendationContext, plan: _Plan) -> None:
        if context.moon_phase:
            plan.evidence.append(
                f"Moon phase logged as {context.moon_phase}; treat solunar timing as a minor, low-confidence factor only."
            )

    def _apply_spawning(self, context: RecommendationContext, plan: _Plan) -> None:
        if context.spawning_indicators or any(
            signal.observation_type == ObservationType.spawning_indicator for signal in context.observations
        ):
            plan.confidence = min(plan.confidence, 40)
            plan.fish_welfare_warning = (
                "Possible spawning indicators logged. Do not disturb spawning fish; follow fishery rules and move away if needed."
            )
            plan.tactic_notes.append("Fish welfare overrides tactical opportunity.")
            plan.add_action(_PRIORITY_WELFARE, "Fish welfare first: do not disturb spawning fish; move away if needed and follow fishery rules.")

    # ------------------------------------------------------------------
    # Assembly
    # ------------------------------------------------------------------
    def _finalise(self, plan: _Plan) -> RecommendationResult:
        location_score = self._clamp(plan.location_score)
        feeding_window_score = self._clamp(plan.feeding_window_score)
        presentation_fit_score = self._clamp(plan.presentation_fit_score)
        oxygen_comfort_score = self._clamp(plan.oxygen_comfort_score)
        pressure_risk_score = self._clamp(plan.pressure_risk_score)
        confidence = self._clamp(plan.confidence)

        summary = "Work from the strongest logged evidence, keep the plan reversible, and review outcomes after the session."
        tactic = (
            " ".join(plan.tactic_notes)
            if plan.tactic_notes
            else "Hold a balanced starting approach and gather more evidence before committing."
        )

        actions = plan.ordered_actions()
        if not actions:
            actions = ["Start with observation: read the wind, watch for shows, then commit to the best-evidenced water."]

        return RecommendationResult(
            recommendation_summary=summary,
            location_score=location_score,
            feeding_window_score=feeding_window_score,
            presentation_fit_score=presentation_fit_score,
            oxygen_comfort_score=oxygen_comfort_score,
            pressure_risk_score=pressure_risk_score,
            confidence_score=confidence,
            recommended_zone=plan.recommended_zone,
            recommended_tactic=tactic,
            recommended_baiting_level=plan.recommended_baiting,
            recommended_depth_or_layer=plan.recommended_layer,
            evidence_summary=plan.evidence or ["No strong evidence logged yet."],
            data_gaps=self._dedupe(plan.gaps),
            alternative_plan="If the chosen line stays quiet, keep one option mobile and prioritise fresh observations over old assumptions.",
            fish_welfare_warning=plan.fish_welfare_warning,
            seasonal_context=plan.seasonal_context,
            barometric_note=plan.barometric_note,
            prime_feeding_windows=self._dedupe(plan.prime_windows),
            priority_actions=actions,
        )

    @staticmethod
    def _season_for_month(month: int) -> str:
        if month in (12, 1, 2):
            return "winter"
        if month in (3, 4, 5):
            return "spring"
        if month in (6, 7, 8):
            return "summer"
        return "autumn"

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
