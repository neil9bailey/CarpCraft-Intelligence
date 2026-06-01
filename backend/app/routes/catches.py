from app.routes._crud import build_crud_router
from app.schemas.domain import Catch

router = build_crud_router(Catch, "catches")
