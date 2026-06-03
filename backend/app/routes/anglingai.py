from fastapi import APIRouter, Depends

from app.core.auth import Principal, get_current_principal
from app.schemas.domain import (
    AnglingAIBaitCalculatorRequest,
    AnglingAIByelawCheckRequest,
    AnglingAIFishDiseaseRequest,
    AnglingAILakeMapFromLocationRequest,
    AnglingAIProviderResponse,
    AnglingAIRigBuilderRequest,
    AnglingAISolunarRequest,
    AnglingAISpawnAlertRequest,
    AnglingAISwimSelectorRequest,
    AnglingAIVenueResearchRequest,
    AnglingAIVisionRequest,
    AnglingAIWeatherRequest,
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


@router.post("/weather", response_model=AnglingAIProviderResponse)
def weather(
    request: AnglingAIWeatherRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().weather(request)


@router.post("/solunar", response_model=AnglingAIProviderResponse)
def solunar(
    request: AnglingAISolunarRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().solunar(request)


@router.post("/spawn-alert", response_model=AnglingAIProviderResponse)
def spawn_alert(
    request: AnglingAISpawnAlertRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().spawn_alert(request)


@router.post("/byelaw-check", response_model=AnglingAIProviderResponse)
def byelaw_check(
    request: AnglingAIByelawCheckRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().byelaw_check(request)


@router.post("/bait-calculator", response_model=AnglingAIProviderResponse)
def bait_calculator(
    request: AnglingAIBaitCalculatorRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().bait_calculator(request)


@router.post("/rig-builder", response_model=AnglingAIProviderResponse)
def rig_builder(
    request: AnglingAIRigBuilderRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().rig_builder(request)


@router.post("/fish-disease", response_model=AnglingAIProviderResponse)
def fish_disease(
    request: AnglingAIFishDiseaseRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().fish_disease(request)


@router.post("/lake-map/from-location", response_model=AnglingAIProviderResponse)
def lake_map_from_location(
    request: AnglingAILakeMapFromLocationRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().lake_map_from_location(request)


@router.get("/locations", response_model=AnglingAIProviderResponse)
def locations(principal: Principal = Depends(get_current_principal)) -> AnglingAIProviderResponse:
    return AnglingAIService().locations()


@router.post("/vision", response_model=AnglingAIProviderResponse)
def vision(
    request: AnglingAIVisionRequest,
    principal: Principal = Depends(get_current_principal),
) -> AnglingAIProviderResponse:
    return AnglingAIService().vision(request)
