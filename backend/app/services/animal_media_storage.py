from __future__ import annotations

import hashlib
import re
from pathlib import Path
from urllib.parse import quote

import httpx
from fastapi import HTTPException, UploadFile, status

from app.config import get_settings

settings = get_settings()

_ALLOWED_CONTENT_TYPES = {
    "image/jpeg", "image/png", "image/webp", "application/pdf",
    "text/plain", "text/csv", "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
}
_ALLOWED_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp", ".pdf", ".txt", ".csv", ".doc", ".docx", ".xls", ".xlsx"}


def _safe_suffix(filename: str) -> str:
    suffix = Path(filename or "").suffix.lower()
    return suffix if suffix in _ALLOWED_SUFFIXES else ""


def _safe_segment(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_.-]+", "_", value.strip())
    return cleaned[:120] or "unknown"


def storage_path(*, tenant_id: str, company_id: str, farm_id: str, animal_id: str, media_id: str, filename: str) -> Path:
    suffix = _safe_suffix(filename)
    return Path(_safe_segment(tenant_id)) / _safe_segment(company_id) / _safe_segment(farm_id) / _safe_segment(animal_id) / f"{_safe_segment(media_id)}{suffix}"


def storage_key_from_path(path: Path) -> str:
    return path.as_posix().lstrip("/")


def _validate_upload(upload: UploadFile) -> tuple[str, str]:
    content_type = (upload.content_type or "").lower().strip()
    suffix = _safe_suffix(upload.filename or "")
    if not suffix:
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail="Extensão de arquivo não permitida.")
    if content_type and content_type not in _ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail="Tipo de arquivo não permitido.")
    return content_type or "application/octet-stream", suffix


def _supabase_headers_for_key(
    key: str,
    content_type: str | None = None,
) -> dict[str, str]:
    normalized = key.strip()
    headers = {"apikey": normalized}

    # Chaves legadas service_role são JWTs e podem ser usadas como Bearer.
    # As novas sb_secret_* são opaque API keys e devem permanecer no header
    # apikey; o gateway Supabase traduz a identidade server-side.
    if normalized and not normalized.startswith("sb_secret_"):
        headers["Authorization"] = f"Bearer {normalized}"

    if content_type:
        headers["Content-Type"] = content_type

    return headers


def _supabase_headers(content_type: str | None = None) -> dict[str, str]:
    return _supabase_headers_for_key(
        settings.atlas_supabase_service_role_key,
        content_type,
    )


def _supabase_object_url(storage_key: str, *, authenticated: bool = False) -> str:
    base = settings.atlas_supabase_url.rstrip("/")
    bucket = quote(settings.atlas_supabase_storage_bucket.strip(), safe="")
    key = quote(storage_key, safe="/")
    segment = "object/authenticated" if authenticated else "object"
    return f"{base}/storage/v1/{segment}/{bucket}/{key}"


async def save_upload(upload: UploadFile, destination: Path) -> tuple[int, str]:
    content_type, _ = _validate_upload(upload)
    max_bytes = settings.atlas_attachment_max_mb * 1024 * 1024
    digest = hashlib.sha256()
    total = 0
    chunks: list[bytes] = []
    try:
        while True:
            chunk = await upload.read(1024 * 1024)
            if not chunk:
                break
            total += len(chunk)
            if total > max_bytes:
                raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail=f"Arquivo excede o limite de {settings.atlas_attachment_max_mb} MB.")
            digest.update(chunk)
            chunks.append(chunk)

        if settings.atlas_attachment_backend == "supabase":
            storage_key = storage_key_from_path(destination)
            headers = _supabase_headers(content_type)
            headers["x-upsert"] = "true"
            try:
                async with httpx.AsyncClient(timeout=60.0) as client:
                    response = await client.post(_supabase_object_url(storage_key), headers=headers, content=b"".join(chunks))
                if response.status_code not in {200, 201}:
                    raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Falha ao gravar anexo no Supabase Storage.")
            except httpx.HTTPError as exc:
                raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Supabase Storage indisponível.") from exc
        else:
            local = settings.attachment_dir / storage_key_from_path(destination)
            local.parent.mkdir(parents=True, exist_ok=True)
            temporary = local.with_suffix(local.suffix + ".uploading")
            try:
                temporary.write_bytes(b"".join(chunks))
                temporary.replace(local)
            finally:
                temporary.unlink(missing_ok=True)
        return total, digest.hexdigest()
    finally:
        await upload.close()


def remove_file(storage_key: str) -> None:
    if not storage_key:
        return
    if settings.atlas_attachment_backend == "supabase":
        try:
            with httpx.Client(timeout=30.0) as client:
                response = client.delete(_supabase_object_url(storage_key), headers=_supabase_headers())
            if response.status_code not in {200, 204, 404}:
                raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Falha ao excluir anexo do Supabase Storage.")
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Supabase Storage indisponível.") from exc
        return
    candidate = absolute_local_path(storage_key, require_exists=False)
    candidate.unlink(missing_ok=True)


def absolute_local_path(storage_key: str, *, require_exists: bool = True) -> Path:
    root = settings.attachment_dir.resolve()
    candidate = (settings.attachment_dir / storage_key).resolve()
    try:
        candidate.relative_to(root)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Arquivo não localizado.") from exc
    if require_exists and not candidate.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Arquivo não localizado.")
    return candidate


def absolute_from_storage_key(storage_key: str) -> Path:
    return absolute_local_path(storage_key)


def read_file_bytes(storage_key: str) -> bytes:
    if settings.atlas_attachment_backend == "supabase":
        try:
            with httpx.Client(timeout=60.0) as client:
                response = client.get(_supabase_object_url(storage_key, authenticated=True), headers=_supabase_headers())
            if response.status_code == 404:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Arquivo não localizado.")
            if response.status_code != 200:
                raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Falha ao ler anexo do Supabase Storage.")
            return response.content
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Supabase Storage indisponível.") from exc
    return absolute_local_path(storage_key).read_bytes()
