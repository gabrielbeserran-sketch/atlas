"""Auditable attachments for financial entries."""
from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import Response
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.authz import Principal, require_farm_scope, require_permission
from app.config import get_settings
from app.database import get_db
from app.models import FinancialDocument, FinancialEntry, new_id
from app.services.animal_media_storage import (
    read_file_bytes,
    remove_file,
    save_upload,
    storage_key_from_path,
    storage_path,
)
from app.services.audit import record_audit
from app.services.financial_document_ocr import OcrFailed, OcrUnavailable, suggest

router = APIRouter(prefix="/financial-documents", tags=["financial-documents"])


class ReviewPayload(BaseModel):
    status: str = Field(pattern="^(pending|reviewed|rejected)$")
    extracted_data: dict = Field(default_factory=dict)
    notes: str = Field(default="", max_length=4000)


def _entry(db: Session, principal: Principal, entry_id: str) -> FinancialEntry:
    item = db.scalar(select(FinancialEntry).where(
        FinancialEntry.id == entry_id,
        FinancialEntry.company_id == principal.company.id,
        FinancialEntry.tenant_id == principal.company.tenant_id,
    ))
    if item is None:
        raise HTTPException(status_code=404, detail="Lançamento financeiro não localizado.")
    require_farm_scope(principal, item.farm_id)
    return item


def _document(db: Session, principal: Principal, document_id: str) -> FinancialDocument:
    item = db.scalar(select(FinancialDocument).where(
        FinancialDocument.id == document_id,
        FinancialDocument.company_id == principal.company.id,
        FinancialDocument.tenant_id == principal.company.tenant_id,
    ))
    if item is None:
        raise HTTPException(status_code=404, detail="Documento financeiro não localizado.")
    require_farm_scope(principal, item.farm_id)
    return item


def _payload(item: FinancialDocument) -> dict:
    return {"id": item.id, "financial_entry_id": item.financial_entry_id,
            "original_filename": item.original_filename, "content_type": item.content_type,
            "size_bytes": item.size_bytes, "sha256": item.sha256,
            "review_status": item.review_status, "extracted_data": item.extracted_data or {},
            "review_notes": item.review_notes, "created_at": item.created_at.isoformat(),
            "updated_at": item.updated_at.isoformat(),
            "content_path": f"/financial-documents/{item.id}/content" if item.storage_key else ""}


@router.get("/entries/{entry_id}")
def list_documents(entry_id: str, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("finance.read"))):
    _entry(db, principal, entry_id)
    rows = db.scalars(select(FinancialDocument).where(FinancialDocument.financial_entry_id == entry_id, FinancialDocument.company_id == principal.company.id).order_by(FinancialDocument.created_at.desc())).all()
    return [_payload(row) for row in rows]


@router.post("/entries/{entry_id}", status_code=status.HTTP_201_CREATED)
async def upload_document(entry_id: str, file: UploadFile = File(...), db: Session = Depends(get_db), principal: Principal = Depends(require_permission("finance.write"))):
    entry = _entry(db, principal, entry_id)
    item = FinancialDocument(id=new_id("finance_document"), tenant_id=principal.company.tenant_id,
        company_id=principal.company.id, farm_id=entry.farm_id, financial_entry_id=entry.id,
        original_filename=Path(file.filename or "documento").name[:255],
        content_type=(file.content_type or "")[:160], created_by=principal.user.id)
    db.add(item)
    db.flush()
    destination = storage_path(tenant_id=item.tenant_id, company_id=item.company_id,
        farm_id=item.farm_id, animal_id="financial-documents", media_id=item.id,
        filename=item.original_filename)
    size_bytes, digest = await save_upload(file, destination)
    item.size_bytes, item.sha256, item.storage_key = size_bytes, digest, storage_key_from_path(destination)
    record_audit(db, principal=principal, action="financial_document_uploaded", module="finance",
        entity_type="financial_document", entity_id=item.id, farm_id=item.farm_id,
        description="Documento financeiro anexado.", after={"entry_id": entry.id, "sha256": digest, "size_bytes": size_bytes})
    db.commit(); db.refresh(item)
    return _payload(item)

@router.post("/ocr-preview")
async def ocr_preview(
    farm_id: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("finance.write")),
):
    require_farm_scope(principal, farm_id)
    content = await file.read()
    if not content or len(content) > get_settings().atlas_attachment_max_mb * 1024 * 1024:
        raise HTTPException(status_code=422, detail="Imagem inválida ou maior que o limite.")
    try:
        data = await suggest(content, file.content_type or "image/jpeg")
    except OcrUnavailable as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except OcrFailed as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    record_audit(
        db,
        principal=principal,
        action="financial_document_ocr_previewed",
        module="finance",
        entity_type="financial_document_preview",
        entity_id="preview",
        farm_id=farm_id,
        description="Sugestão OCR gerada para revisão.",
        after={"fields": sorted(data.keys())},
    )
    db.commit()
    return {"suggested_data": data, "requires_review": True}


@router.patch("/{document_id}/review")
def review_document(document_id: str, payload: ReviewPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("finance.write"))):
    item = _document(db, principal, document_id)
    before = {"review_status": item.review_status, "extracted_data": item.extracted_data or {}}
    item.review_status, item.extracted_data, item.review_notes = payload.status, payload.extracted_data, payload.notes.strip()
    record_audit(db, principal=principal, action="financial_document_reviewed", module="finance",
        entity_type="financial_document", entity_id=item.id, farm_id=item.farm_id,
        description="Revisão de documento financeiro registrada.", before=before,
        after={"review_status": item.review_status, "extracted_data": item.extracted_data})
    db.commit(); db.refresh(item)
    return _payload(item)


@router.get("/{document_id}/content")
def download_document(document_id: str, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("finance.read"))):
    item = _document(db, principal, document_id)
    if not item.storage_key:
        raise HTTPException(status_code=404, detail="Arquivo não localizado.")
    safe_filename = item.original_filename.replace('"', '')
    return Response(read_file_bytes(item.storage_key), media_type=item.content_type or "application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="{safe_filename}"'})
