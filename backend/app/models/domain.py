from dataclasses import dataclass
from datetime import datetime
from typing import Any


@dataclass(slots=True)
class DomainEvent:
    event_type: str
    entity_id: str
    occurred_at: datetime
    payload: dict[str, Any]


@dataclass(slots=True)
class PersistenceNote:
    entity_name: str
    table_name: str
    postgres_ready: bool = True
    postgis_candidate: bool = False
    pgvector_candidate: bool = False
