from __future__ import annotations

from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.repositories.json_resource import JsonResourceRepository
from app.repositories.normalized import NormalizedRepository, get_normalized_adapter


def build_repository(db: Session, resource_type: str, model_type: type[BaseModel]) -> JsonResourceRepository | NormalizedRepository:
    adapter = get_normalized_adapter(resource_type)
    if adapter is not None:
        return NormalizedRepository(db, adapter)
    return JsonResourceRepository(db, resource_type, model_type)
