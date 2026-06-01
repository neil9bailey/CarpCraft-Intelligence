from app.routes._crud import build_crud_router
from app.schemas.domain import BiteEvent

router = build_crud_router(BiteEvent, "bite-events")
