from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.persistence import AnglingSessionRecord, BlankIntervalRecord, CatchRecord, RecommendationRecord


class LakeBrainService:
    """Summarises private venue memory with sample-size caution."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def summarise_venue(self, venue_id: str) -> dict[str, object]:
        session_ids = select(AnglingSessionRecord.id).where(AnglingSessionRecord.venue_id == venue_id)
        session_count = self.db.scalar(
            select(func.count()).select_from(AnglingSessionRecord).where(AnglingSessionRecord.venue_id == venue_id)
        )
        catch_count = self.db.scalar(select(func.count()).select_from(CatchRecord).where(CatchRecord.session_id.in_(session_ids)))
        blank_count = self.db.scalar(
            select(func.count()).select_from(BlankIntervalRecord).where(BlankIntervalRecord.session_id.in_(session_ids))
        )
        recommendation_count = self.db.scalar(
            select(func.count()).select_from(RecommendationRecord).where(RecommendationRecord.session_id.in_(session_ids))
        )

        session_total = int(session_count or 0)
        catch_total = int(catch_count or 0)
        blank_total = int(blank_count or 0)
        recommendation_total = int(recommendation_count or 0)

        if session_total == 0:
            confidence = 0
            summary = "No persisted sessions have been analysed for this venue yet."
        elif session_total < 10:
            confidence = min(50, session_total * 5)
            summary = "Early venue memory exists, but sample size is still too small for strong pattern claims."
        else:
            confidence = min(85, 50 + ((session_total - 10) * 3))
            summary = "Venue memory has enough sessions for cautious pattern review, with blanks and catches considered together."

        data_gaps: list[str] = []
        if session_total < 10:
            data_gaps.append("Fewer than 10 sessions are logged for this venue.")
        if blank_total == 0:
            data_gaps.append("No blank intervals are logged, so failure patterns are underrepresented.")
        if catch_total == 0:
            data_gaps.append("No catches are logged against this venue yet.")
        if recommendation_total == 0:
            data_gaps.append("No recommendation outcomes have been linked to this venue yet.")
        data_gaps.append("Water readings and weather trends are not yet included in this Lake Brain summary.")

        return {
            "venue_id": venue_id,
            "summary": summary,
            "sample_size": session_total,
            "catch_count": catch_total,
            "blank_interval_count": blank_total,
            "recommendation_count": recommendation_total,
            "confidence": confidence,
            "data_gaps": data_gaps,
            "privacy": "Venue memory is private by default.",
        }
