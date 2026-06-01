from app.routes._crud import build_crud_router
from app.schemas.domain import Swim

router = build_crud_router(Swim, "swims")
