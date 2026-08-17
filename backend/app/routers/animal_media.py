from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import Response
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.authz import Principal, require_farm_scope, require_permission
from app.database import get_db
from app.models import AnimalMedia, LivestockAnimal, new_id
from app.services.animal_media_storage import (
    remove_file,
    save_upload,
    storage_key_from_path,
    storage_path,
    read_file_bytes,
)

router = APIRouter(prefix="/animal-media", tags=["animal-media"])

_ALLOWED_KINDS = {"photo", "document"}




class AnimalMediaReferenceCreate(BaseModel):
    kind: str
    metadata: dict = Field(default_factory=dict)


class AnimalMediaPatch(BaseModel):
    metadata: dict = Field(default_factory=dict)


def _animal_for_principal(
    db: Session,
    principal: Principal,
    animal_id: str,
) -> LivestockAnimal:
    animal = db.scalar(
        select(LivestockAnimal).where(
            LivestockAnimal.id == animal_id,
            LivestockAnimal.company_id == principal.company.id,
            LivestockAnimal.tenant_id == principal.company.tenant_id,
        )
    )

    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Animal não localizado.",
        )

    require_farm_scope(principal, animal.farm_id)
    return animal


def _media_for_principal(
    db: Session,
    principal: Principal,
    *,
    animal_id: str,
    media_id: str,
) -> AnimalMedia:
    _animal_for_principal(db, principal, animal_id)

    media = db.scalar(
        select(AnimalMedia).where(
            AnimalMedia.id == media_id,
            AnimalMedia.animal_id == animal_id,
            AnimalMedia.company_id == principal.company.id,
            AnimalMedia.tenant_id == principal.company.tenant_id,
        )
    )

    if media is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Anexo não localizado.",
        )

    return media


def _payload(media: AnimalMedia) -> dict:
    return {
        "id": media.id,
        "kind": media.kind,
        "animal_id": media.animal_id,
        "farm_id": media.farm_id,
        "original_filename": media.original_filename,
        "content_type": media.content_type,
        "size_bytes": media.size_bytes,
        "sha256": media.sha256,
        "metadata": media.metadata_json or {},
        "has_file": bool(media.storage_key),
        "content_path": (
            f"/animal-media/{media.animal_id}/{media.id}/content"
            if media.storage_key
            else ""
        ),
        "created_at": media.created_at.isoformat(),
        "updated_at": media.updated_at.isoformat(),
    }


@router.get("/{animal_id}")
def list_media(
    animal_id: str,
    kind: str | None = None,
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("animals.read")),
):
    _animal_for_principal(db, principal, animal_id)

    query = select(AnimalMedia).where(
        AnimalMedia.animal_id == animal_id,
        AnimalMedia.company_id == principal.company.id,
        AnimalMedia.tenant_id == principal.company.tenant_id,
    )

    if kind is not None:
        normalized = kind.strip().lower()
        if normalized not in _ALLOWED_KINDS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tipo de anexo inválido.",
            )
        query = query.where(AnimalMedia.kind == normalized)

    items = db.scalars(
        query.order_by(AnimalMedia.created_at.desc())
    ).all()

    return [_payload(item) for item in items]


@router.post("/{animal_id}", status_code=status.HTTP_201_CREATED)
async def create_media(
    animal_id: str,
    kind: str = Form(...),
    metadata_json: str = Form("{}"),
    file: UploadFile | None = File(default=None),
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("animals.update")),
):
    animal = _animal_for_principal(db, principal, animal_id)
    normalized_kind = kind.strip().lower()

    if normalized_kind not in _ALLOWED_KINDS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tipo de anexo inválido.",
        )

    try:
        metadata = json.loads(metadata_json or "{}")
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Metadados JSON inválidos.",
        ) from exc

    if not isinstance(metadata, dict):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Metadados precisam ser um objeto JSON.",
        )

    media = AnimalMedia(
        id=new_id("media"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=animal.farm_id,
        animal_id=animal.id,
        kind=normalized_kind,
        metadata_json=metadata,
        created_by=principal.user.id,
    )

    db.add(media)
    db.flush()

    if file is not None and file.filename:
        destination = storage_path(
            tenant_id=media.tenant_id,
            company_id=media.company_id,
            farm_id=media.farm_id,
            animal_id=media.animal_id,
            media_id=media.id,
            filename=file.filename,
        )
        size_bytes, digest = await save_upload(file, destination)

        media.original_filename = Path(file.filename).name[:255]
        media.content_type = (file.content_type or "")[:160]
        media.size_bytes = size_bytes
        media.sha256 = digest
        media.storage_key = storage_key_from_path(destination)

    db.commit()
    db.refresh(media)
    return _payload(media)




@router.post("/{animal_id}/reference", status_code=status.HTTP_201_CREATED)
def create_reference_media(
    animal_id: str,
    payload: AnimalMediaReferenceCreate,
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("animals.update")),
):
    animal = _animal_for_principal(db, principal, animal_id)
    normalized_kind = payload.kind.strip().lower()

    if normalized_kind != "document":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Somente documentos podem ser referência externa sem arquivo.",
        )

    external = str(payload.metadata.get("externalReference", "")).strip()
    if not external.startswith(("https://", "http://")):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Referência externa precisa usar http:// ou https://.",
        )

    media = AnimalMedia(
        id=new_id("media"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=animal.farm_id,
        animal_id=animal.id,
        kind="document",
        metadata_json=payload.metadata,
        created_by=principal.user.id,
    )
    db.add(media)
    db.commit()
    db.refresh(media)
    return _payload(media)


@router.patch("/{animal_id}/{media_id}")
def update_media(
    animal_id: str,
    media_id: str,
    payload: AnimalMediaPatch,
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("animals.update")),
):
    media = _media_for_principal(
        db,
        principal,
        animal_id=animal_id,
        media_id=media_id,
    )
    media.metadata_json = payload.metadata
    media.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(media)
    return _payload(media)


@router.put("/{animal_id}/{media_id}/content")
async def replace_media_content(
    animal_id: str,
    media_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("animals.update")),
):
    media = _media_for_principal(
        db,
        principal,
        animal_id=animal_id,
        media_id=media_id,
    )

    old_storage_key = media.storage_key
    destination = storage_path(
        tenant_id=media.tenant_id,
        company_id=media.company_id,
        farm_id=media.farm_id,
        animal_id=media.animal_id,
        media_id=media.id,
        filename=file.filename or media.original_filename,
    )

    size_bytes, digest = await save_upload(file, destination)

    new_storage_key = storage_key_from_path(destination)
    if old_storage_key and old_storage_key != new_storage_key:
        remove_file(old_storage_key)

    media.original_filename = Path(file.filename or "").name[:255]
    media.content_type = (file.content_type or "")[:160]
    media.size_bytes = size_bytes
    media.sha256 = digest
    media.storage_key = new_storage_key
    media.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(media)
    return _payload(media)


@router.get("/{animal_id}/{media_id}/content")
def download_media(
    animal_id: str,
    media_id: str,
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("animals.read")),
):
    media = _media_for_principal(
        db,
        principal,
        animal_id=animal_id,
        media_id=media_id,
    )

    if not media.storage_key:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Este registro não possui arquivo armazenado.",
        )

    content = read_file_bytes(media.storage_key)
    filename = media.original_filename or Path(media.storage_key).name
    safe_filename = filename.replace('"', "")
    return Response(
        content=content,
        media_type=media.content_type or "application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="{safe_filename}"'},
    )


@router.delete("/{animal_id}/{media_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_media(
    animal_id: str,
    media_id: str,
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("animals.update")),
):
    media = _media_for_principal(
        db,
        principal,
        animal_id=animal_id,
        media_id=media_id,
    )

    storage_key = media.storage_key
    db.delete(media)
    db.commit()

    if storage_key:
        remove_file(storage_key)

    return None
