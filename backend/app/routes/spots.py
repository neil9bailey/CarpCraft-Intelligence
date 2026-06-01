from app.routes._crud import build_crud_router
from app.schemas.domain import Spot

router = build_crud_router(Spot, "spots")
