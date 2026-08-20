from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(relative: str) -> str:
    path = ROOT / relative
    return path.read_text(encoding="utf-8", errors="ignore") if path.is_file() else ""


def main() -> int:
    photo = read(
        "lib/features/animal_photo/data/services/"
        "animal_photo_storage_service.dart"
    )
    document = read(
        "lib/features/animal_document/data/services/"
        "animal_document_storage_service.dart"
    )
    remote = read(
        "lib/features/animal/data/services/animal_media_remote_service.dart"
    )
    router = read("backend/app/routers/animal_media.py")
    model = read("backend/app/models/legacy.py")
    compose = read("docker-compose.yml")
    migration = read(
        "backend/alembic/versions/20260815_0040_animal_media_remote.py"
    )
    tests = read("backend/tests/test_marco5d_animal_media.py")

    checks = {
        "backend_media_table": 'class AnimalMedia' in model,
        "migration_0040": 'revision = "20260815_0040"' in migration,
        "tenant_company_animal_scope": all(
            marker in router
            for marker in (
                "AnimalMedia.company_id == principal.company.id",
                "AnimalMedia.tenant_id == principal.company.tenant_id",
                "require_farm_scope(principal, animal.farm_id)",
            )
        ),
        "authenticated_binary_download": (
            ("FileResponse" in router or "return Response(" in router)
            and 'require_permission("animals.read")' in router
            and "_media_for_principal(" in router
        ),
        "authenticated_upload": (
            "UploadFile" in router
            and 'require_permission("animals.update")' in router
        ),
        "file_type_and_size_validation": (
            "_ALLOWED_CONTENT_TYPES" in read(
                "backend/app/services/animal_media_storage.py"
            )
            and "atlas_attachment_max_mb" in read(
                "backend/app/services/animal_media_storage.py"
            )
        ),
        "persistent_docker_volume": (
            "atlas_attachments:/data/attachments" in compose
        ),
        "photo_remote_authority": (
            "_remote.list" in photo
            and "_remote.create" in photo
            and "atlas_animal_photos_cache_" in photo
        ),
        "document_remote_authority": (
            "_remote.list" in document
            and "_remote.create" in document
            and "atlas_animal_documents_cache_" in document
        ),
        "flutter_binary_upload_download": (
            "uploadFile" in remote and "cacheContent" in remote
        ),
        "shared_preferences_only_cache": (
            "autoridade remota" in photo.lower()
            and "única autoridade" in document.lower()
        ),
        "regression_tests": all(
            marker in tests
            for marker in (
                "test_photo_upload_list_download_patch_and_delete",
                "test_document_external_reference_without_file",
                "test_upload_rejects_unsupported_extension",
            )
        ),
        "tests_create_own_livestock_preconditions": (
            "def _create_animal(client, headers)" in tests
            and '"/api/v1/farms"' in tests
            and '"/api/v1/livestock/lots"' in tests
            and '"/api/v1/livestock/animals"' in tests
            and "_first_animal" not in tests
        ),
    }

    errors = [name for name, ok in checks.items() if not ok]
    report = {
        "status": "FAIL" if errors else "OK",
        "checks": checks,
        "errors": errors,
        "resolved_blockers": ["ATT-001", "ATT-002", "ATT-003"],
        "remaining_production_blockers": [
            "NET-002 rate limit distribuído",
            "BKP-002 restauração homologada",
        ],
        "android_deferred": [],
    }

    (ROOT / "ATLAS_MARCO5D_MEDIA_CONTRACT.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(
        "\nATLAS MARCO 5D MEDIA CONTRACT:",
        "FAIL" if errors else "OK",
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
