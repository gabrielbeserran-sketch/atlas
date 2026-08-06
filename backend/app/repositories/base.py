from typing import Generic, TypeVar
from sqlalchemy import select
from sqlalchemy.orm import Session

ModelT = TypeVar("ModelT")


class Repository(Generic[ModelT]):
    def __init__(self, session: Session, model: type[ModelT]):
        self.session = session
        self.model = model

    def get(self, entity_id: str) -> ModelT | None:
        return self.session.get(self.model, entity_id)

    def add(self, entity: ModelT) -> ModelT:
        self.session.add(entity)
        self.session.flush()
        return entity

    def list(self, *, limit: int = 100, offset: int = 0) -> list[ModelT]:
        return list(self.session.scalars(select(self.model).offset(offset).limit(limit)))
