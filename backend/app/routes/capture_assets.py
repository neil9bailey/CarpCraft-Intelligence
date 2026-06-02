from app.routes._crud import build_crud_router
from app.schemas.domain import CaptureAsset

router = build_crud_router(CaptureAsset, "capture-assets")
