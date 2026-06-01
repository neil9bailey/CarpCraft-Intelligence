from app.routes._crud import build_crud_router
from app.schemas.domain import Observation

router = build_crud_router(Observation, "observations")
