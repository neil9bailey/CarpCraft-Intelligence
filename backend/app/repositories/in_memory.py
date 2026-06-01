from __future__ import annotations

from typing import Generic, TypeVar

from pydantic import BaseModel

ModelT = TypeVar("ModelT", bound=BaseModel)


class InMemoryRepository(Generic[ModelT]):
    def __init__(self) -> None:
        self._items: dict[str, ModelT] = {}

    def list(self) -> list[ModelT]:
        return list(self._items.values())

    def get(self, item_id: str) -> ModelT | None:
        return self._items.get(item_id)

    def create(self, item: ModelT) -> ModelT:
        item_id = str(getattr(item, "id"))
        self._items[item_id] = item
        return item

    def update(self, item_id: str, item: ModelT) -> ModelT | None:
        if item_id not in self._items:
            return None
        updated = item.model_copy(update={"id": item_id})
        self._items[item_id] = updated
        return updated

    def delete(self, item_id: str) -> bool:
        return self._items.pop(item_id, None) is not None
