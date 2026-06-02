from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.routes import (
    ai_intelligence,
    anglingai,
    bait_applications,
    bite_events,
    blanks,
    catches,
    capture_assets,
    fishery_profiles,
    health,
    mcp_agent_runs,
    observations,
    recommendations,
    rod_sets,
    sessions,
    spots,
    swims,
    venues,
    version,
    water_readings,
    weather_snapshots,
)

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.api_version,
    description="Evidence-ranked watercraft API scaffold for CarpCraft Intelligence.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://127.0.0.1"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(version.router)
app.include_router(venues.router, prefix="/api/v1/venues")
app.include_router(fishery_profiles.router, prefix="/api/v1/fishery-profiles")
app.include_router(swims.router, prefix="/api/v1/swims")
app.include_router(spots.router, prefix="/api/v1/spots")
app.include_router(sessions.router, prefix="/api/v1/sessions")
app.include_router(capture_assets.router, prefix="/api/v1/capture-assets")
app.include_router(rod_sets.router, prefix="/api/v1/rod-sets")
app.include_router(bait_applications.router, prefix="/api/v1/bait-applications")
app.include_router(observations.router, prefix="/api/v1/observations")
app.include_router(water_readings.router, prefix="/api/v1/water-readings")
app.include_router(weather_snapshots.router, prefix="/api/v1/weather-snapshots")
app.include_router(bite_events.router, prefix="/api/v1/bite-events")
app.include_router(catches.router, prefix="/api/v1/catches")
app.include_router(blanks.router, prefix="/api/v1/blanks")
app.include_router(recommendations.router, prefix="/api/v1/recommendations")
app.include_router(ai_intelligence.router, prefix="/api/v1/ai-intelligence")
app.include_router(anglingai.router, prefix="/api/v1/anglingai")
app.include_router(mcp_agent_runs.router, prefix="/api/v1/mcp-agent-runs")
