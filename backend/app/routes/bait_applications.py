from app.routes._crud import build_crud_router
from app.schemas.domain import BaitApplication

router = build_crud_router(BaitApplication, "bait-applications")
