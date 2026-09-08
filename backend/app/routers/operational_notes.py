"""Farm-scoped notes that can be promoted once into the operational agenda."""
from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.authz import Principal, require_farm_scope, require_permission
from app.database import get_db
from app.models import Farm, OperationalNote, OperationalTask, new_id
from app.services.audit import record_audit

router = APIRouter(prefix="/operational-notes", tags=["operational-notes"])


class NoteCreatePayload(BaseModel):
    farm_id: str = Field(min_length=1, max_length=80)
    content: str = Field(min_length=1, max_length=12000)
    source: str = Field(default="text", pattern="^(text|voice_transcription)$")
    transcript: str = Field(default="", max_length=12000)


class TaskFromNotePayload(BaseModel):
    title: str = Field(default="", max_length=220)
    due_at: datetime | None = None
    priority: str = Field(default="medium", pattern="^(low|medium|high|urgent)$")


def _note_payload(item: OperationalNote) -> dict:
    return {
        "id": item.id,
        "farm_id": item.farm_id,
        "author_user_id": item.author_user_id,
        "content": item.content,
        "source": item.source,
        "transcript": item.transcript,
        "created_at": item.created_at.isoformat(),
        "updated_at": item.updated_at.isoformat(),
    }


def _farm(db: Session, principal: Principal, farm_id: str) -> Farm:
    item = db.scalar(
        select(Farm).where(
            Farm.id == farm_id,
            Farm.company_id == principal.company.id,
            Farm.tenant_id == principal.company.tenant_id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Fazenda não localizada.")
    require_farm_scope(principal, item.id)
    return item


def _note(db: Session, principal: Principal, note_id: str) -> OperationalNote:
    item = db.scalar(
        select(OperationalNote).where(
            OperationalNote.id == note_id,
            OperationalNote.company_id == principal.company.id,
            OperationalNote.tenant_id == principal.company.tenant_id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Anotação não localizada.")
    require_farm_scope(principal, item.farm_id)
    return item


@router.get("")
def list_notes(
    farm_id: str,
    principal: Principal = Depends(require_permission("operations.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    _farm(db, principal, farm_id)
    rows = db.scalars(
        select(OperationalNote)
        .where(
            OperationalNote.company_id == principal.company.id,
            OperationalNote.farm_id == farm_id,
        )
        .order_by(OperationalNote.created_at.desc())
    ).all()
    return [_note_payload(row) for row in rows]


@router.post("", status_code=status.HTTP_201_CREATED)
def create_note(
    payload: NoteCreatePayload,
    principal: Principal = Depends(require_permission("operations.manage")),
    db: Session = Depends(get_db),
) -> dict:
    _farm(db, principal, payload.farm_id)
    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=422, detail="Escreva ou dite uma anotação.")
    item = OperationalNote(
        id=new_id("note"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        author_user_id=principal.user.id,
        content=content,
        source=payload.source,
        transcript=payload.transcript.strip(),
    )
    db.add(item)
    record_audit(
        db,
        principal=principal,
        action="operational_note_created",
        module="operations",
        entity_type="operational_note",
        entity_id=item.id,
        farm_id=item.farm_id,
        description="Anotação operacional registrada.",
        after={"source": item.source, "content_length": len(item.content)},
    )
    db.commit()
    db.refresh(item)
    return _note_payload(item)


@router.post("/{note_id}/task", status_code=status.HTTP_201_CREATED)
def create_task_from_note(
    note_id: str,
    payload: TaskFromNotePayload,
    principal: Principal = Depends(require_permission("operations.manage")),
    db: Session = Depends(get_db),
) -> dict:
    note = _note(db, principal, note_id)
    existing = db.scalar(
        select(OperationalTask).where(
            OperationalTask.company_id == principal.company.id,
            OperationalTask.source_type == "operational_note",
            OperationalTask.source_id == note.id,
        )
    )
    if existing is not None:
        return {"task_id": existing.id, "created": False}

    title = payload.title.strip() or note.content.splitlines()[0][:220]
    task = OperationalTask(
        id=new_id("task"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=note.farm_id,
        source_type="operational_note",
        source_id=note.id,
        title=title,
        description=note.content,
        priority=payload.priority,
        due_at=payload.due_at,
    )
    db.add(task)
    record_audit(
        db,
        principal=principal,
        action="operational_note_promoted_to_task",
        module="agenda",
        entity_type="operational_task",
        entity_id=task.id,
        farm_id=task.farm_id,
        description="Anotação transformada em compromisso da Agenda.",
        after={"source_note_id": note.id, "priority": task.priority},
    )
    db.commit()
    return {"task_id": task.id, "created": True}
