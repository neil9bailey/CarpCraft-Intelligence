from __future__ import annotations

from typing import Any, TypeVar

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.repositories.factory import build_repository
from app.schemas.domain import Session as AnglingSession
from app.schemas.domain import Venue

ModelT = TypeVar("ModelT", bound=BaseModel)

OWNER_FIELDS = {
    "venues": "owner_user_id",
    "sessions": "user_id",
}

PARENT_SCOPE_FIELDS = {
    "swims": "venue_id",
    "spots": "venue_id",
    "rod-sets": "session_id",
    "bait-applications": "session_id",
    "observations": "session_id",
    "water-readings": "session_id",
    "weather-snapshots": "session_id",
    "bite-events": "session_id",
    "catches": "session_id",
    "blanks": "session_id",
    "recommendations": "session_id",
    "recommendation-outcomes": "session_id",
}


def _owner_field(resource_type: str, model_type: type[BaseModel]) -> str | None:
    field_name = OWNER_FIELDS.get(resource_type)
    if field_name is None or field_name not in model_type.model_fields:
        return None
    return field_name


def _parent_scope_field(resource_type: str, model_type: type[BaseModel]) -> str | None:
    field_name = PARENT_SCOPE_FIELDS.get(resource_type)
    if field_name is None or field_name not in model_type.model_fields:
        return None
    return field_name


def _is_directly_owned_by(item: BaseModel, owner_field: str | None, principal: Principal) -> bool:
    if owner_field is None:
        return True
    return getattr(item, owner_field) == principal.user_id


def _parent_is_owned_by(
    item: BaseModel,
    parent_field: str | None,
    db: Session,
    principal: Principal,
) -> bool:
    if parent_field is None:
        return True
    parent_id = getattr(item, parent_field)
    if parent_id is None:
        return False
    if parent_field == "venue_id":
        venue = build_repository(db, "venues", Venue).get(parent_id)
        return venue is not None and venue.owner_user_id == principal.user_id
    if parent_field == "session_id":
        session = build_repository(db, "sessions", AnglingSession).get(parent_id)
        return session is not None and session.user_id == principal.user_id
    return False


def _is_accessible_by(
    item: BaseModel,
    owner_field: str | None,
    parent_field: str | None,
    db: Session,
    principal: Principal,
) -> bool:
    return _is_directly_owned_by(item, owner_field, principal) and _parent_is_owned_by(
        item,
        parent_field,
        db,
        principal,
    )


def _not_found(tag: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"{tag} item not found")


def build_crud_router(model_type: type[ModelT], tag: str) -> APIRouter:
    router = APIRouter(tags=[tag])
    resource_type = tag
    owner_field = _owner_field(resource_type, model_type)
    parent_field = _parent_scope_field(resource_type, model_type)

    @router.get("", response_model=list[model_type])  # type: ignore[valid-type]
    def list_items(
        db: Session = Depends(get_db),
        principal: Principal = Depends(get_current_principal),
    ) -> list[ModelT]:
        items = build_repository(db, resource_type, model_type).list()
        return [item for item in items if _is_accessible_by(item, owner_field, parent_field, db, principal)]

    @router.post("", response_model=model_type, status_code=status.HTTP_201_CREATED)  # type: ignore[valid-type]
    def create_item(
        item: dict[str, Any],
        db: Session = Depends(get_db),
        principal: Principal = Depends(get_current_principal),
    ) -> ModelT:
        try:
            parsed = model_type.model_validate(item)
            if owner_field is not None:
                requested_owner = getattr(parsed, owner_field)
                if requested_owner is not None and requested_owner != principal.user_id:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail=f"{tag} item belongs to a different user",
                    )
                parsed = parsed.model_copy(update={owner_field: principal.user_id})
            if not _parent_is_owned_by(parsed, parent_field, db, principal):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"{tag} parent belongs to a different user or does not exist",
                )
            return build_repository(db, resource_type, model_type).create(parsed)
        except IntegrityError as exc:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"{tag} item already exists",
            ) from exc

    @router.get("/{item_id}", response_model=model_type)  # type: ignore[valid-type]
    def get_item(
        item_id: str,
        db: Session = Depends(get_db),
        principal: Principal = Depends(get_current_principal),
    ) -> ModelT:
        item = build_repository(db, resource_type, model_type).get(item_id)
        if item is None or not _is_accessible_by(item, owner_field, parent_field, db, principal):
            raise _not_found(tag)
        return item

    @router.put("/{item_id}", response_model=model_type)  # type: ignore[valid-type]
    def update_item(
        item_id: str,
        item: dict[str, Any],
        db: Session = Depends(get_db),
        principal: Principal = Depends(get_current_principal),
    ) -> ModelT:
        repository = build_repository(db, resource_type, model_type)
        existing = repository.get(item_id)
        if existing is None or not _is_accessible_by(existing, owner_field, parent_field, db, principal):
            raise _not_found(tag)
        parsed = model_type.model_validate(item)
        if owner_field is not None:
            parsed = parsed.model_copy(update={owner_field: principal.user_id})
        if not _parent_is_owned_by(parsed, parent_field, db, principal):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"{tag} parent belongs to a different user or does not exist",
            )
        updated = repository.update(item_id, parsed)
        if updated is None:
            raise _not_found(tag)
        return updated

    @router.delete("/{item_id}", status_code=status.HTTP_200_OK)
    def delete_item(
        item_id: str,
        db: Session = Depends(get_db),
        principal: Principal = Depends(get_current_principal),
    ) -> dict[str, bool]:
        repository = build_repository(db, resource_type, model_type)
        existing = repository.get(item_id)
        if existing is None or not _is_accessible_by(existing, owner_field, parent_field, db, principal):
            raise _not_found(tag)
        deleted = repository.delete(item_id)
        if not deleted:
            raise _not_found(tag)
        return {"deleted": True}

    return router
