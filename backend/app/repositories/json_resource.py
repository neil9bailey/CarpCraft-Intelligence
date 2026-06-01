from __future__ import annotations

from typing import TypeVar

from pydantic import BaseModel
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models.persistence import JsonResourceRecord

ModelT = TypeVar("ModelT", bound=BaseModel)


class JsonResourceRepository:
    def __init__(self, db: Session, resource_type: str, model_type: type[ModelT]) -> None:
        self.db = db
        self.resource_type = resource_type
        self.model_type = model_type

    def list(self) -> list[ModelT]:
        records = self.db.scalars(
            select(JsonResourceRecord)
            .where(JsonResourceRecord.resource_type == self.resource_type)
            .order_by(JsonResourceRecord.created_at.asc())
        ).all()
        return [self.model_type.model_validate(record.payload) for record in records]

    def get(self, item_id: str) -> ModelT | None:
        record = self.db.get(JsonResourceRecord, {"resource_type": self.resource_type, "id": item_id})
        if record is None:
            return None
        return self.model_type.model_validate(record.payload)

    def create(self, item: ModelT) -> ModelT:
        item_id = str(getattr(item, "id"))
        record = JsonResourceRecord(
            resource_type=self.resource_type,
            id=item_id,
            payload=item.model_dump(mode="json"),
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return self.model_type.model_validate(record.payload)

    def upsert(self, item: ModelT) -> ModelT:
        item_id = str(getattr(item, "id"))
        record = self.db.get(JsonResourceRecord, {"resource_type": self.resource_type, "id": item_id})
        if record is None:
            return self.create(item)
        record.payload = item.model_dump(mode="json")
        self.db.commit()
        self.db.refresh(record)
        return self.model_type.model_validate(record.payload)

    def update(self, item_id: str, item: ModelT) -> ModelT | None:
        record = self.db.get(JsonResourceRecord, {"resource_type": self.resource_type, "id": item_id})
        if record is None:
            return None
        updated = item.model_copy(update={"id": item_id})
        record.payload = updated.model_dump(mode="json")
        self.db.commit()
        self.db.refresh(record)
        return self.model_type.model_validate(record.payload)

    def delete(self, item_id: str) -> bool:
        result = self.db.execute(
            delete(JsonResourceRecord).where(
                JsonResourceRecord.resource_type == self.resource_type,
                JsonResourceRecord.id == item_id,
            )
        )
        self.db.commit()
        return result.rowcount > 0
