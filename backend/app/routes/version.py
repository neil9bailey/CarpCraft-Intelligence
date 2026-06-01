from fastapi import APIRouter

from app.core.version import API_VERSION

router = APIRouter(tags=["version"])


@router.get("/api/v1/version")
def version() -> dict[str, str]:
    return {"version": API_VERSION}
