from fastapi import APIRouter, Depends

from app.core.auth import Principal, get_current_principal
from app.schemas.domain import (
    AnglingAIProviderResponse,
    AnglingAISwimSelectorRequest,
    AnglingAIVenueResearchRequest,
    AnglingAIVisionRequest,
    AnglingAIWaterTempRequest,
    ExternalAIProviderStatus,
)
from app.services.anglingai_service import AnglingAIService

router = APIRouter(tags=["anglingai"])


@router.get("/status", response_model=ExternalAIProviderStatus)
def provider_status(principal: Principal = Depends(get_current_principal)) -> ExternalAIProviderStatus:
    return AnglingAIService().status()


@router.post("/venue-research", response_model=AnglingAIProviderResponse)
def venue_research(
    request: AnglingAIVenueResearchRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().venue_research(request)


@router.post("/swim-selector", response_model=AnglingAIProviderResponse)
def swim_selector(
    request: AnglingAISwimSelectorRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().swim_selector(request)


@router.post("/water-temp", response_model=AnglingAIProviderResponse)
def water_temp(
    request: AnglingAIWaterTempRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().water_temp(request)


@router.post("/vision", response_model=AnglingAIProviderResponse)
def vision(
    request: AnglingAIVisionRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().vision(request)
