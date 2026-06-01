from app.routes._crud import build_crud_router
from app.schemas.domain import RodSet

router = build_crud_router(RodSet, "rod-sets")
