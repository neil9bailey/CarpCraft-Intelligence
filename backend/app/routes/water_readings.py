from app.routes._crud import build_crud_router
from app.schemas.domain import WaterReading

router = build_crud_router(WaterReading, "water-readings")
