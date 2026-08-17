from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def source(relative: str) -> str:
    path = ROOT / relative
    return path.read_text(encoding="utf-8", errors="ignore") if path.is_file() else ""


def item(
    code: str,
    title: str,
    status: str,
    next_marco: str,
    evidence: str,
    recommendation: str,
) -> dict[str, str]:
    return {
        "code": code,
        "title": title,
        "status": status,
        "next_marco": next_marco,
        "evidence": evidence,
        "recommendation": recommendation,
    }


def main() -> int:
    config = source("backend/app/config.py")
    security = source("backend/app/security.py")
    auth = source("backend/app/routers/auth.py")
    middleware = source("backend/app/services/security_middleware.py")
    backup = source("backend/app/services/backup.py")
    photo = source(
        "lib/features/animal_photo/data/services/animal_photo_storage_service.dart"
    )
    document = source(
        "lib/features/animal_document/data/services/animal_document_storage_service.dart"
    )
    document_screen = source(
        "lib/features/animal_document/presentation/screens/animal_document_list_screen.dart"
    )
    photo_form = source(
        "lib/features/animal_photo/presentation/screens/animal_photo_form_screen.dart"
    )

    checks: list[dict[str, str]] = []

    checks.append(item(
        "SEC-001",
        "PostgreSQL obrigatório fora do desenvolvimento",
        "ready" if 'staging/production exigem PostgreSQL' in config else "blocker",
        "5B",
        "Settings.validate_secure_environment",
        "Manter PostgreSQL obrigatório em staging/production.",
    ))
    checks.append(item(
        "SEC-002",
        "JWT secreto forte fora do desenvolvimento",
        "ready" if 'ATLAS_JWT_SECRET deve ter ao menos 32 caracteres' in config else "blocker",
        "5B",
        "Settings.validate_secure_environment",
        "Manter rejeição de segredo padrão/fraco.",
    ))
    checks.append(item(
        "SEC-003",
        "Bootstrap desabilitado em produção",
        "ready" if "ATLAS_BOOTSTRAP_ENABLED deve ser false" in config else "blocker",
        "5B",
        "Settings rejeita bootstrap habilitado em staging/production.",
        "Manter o bloqueio coberto por teste.",
    ))
    checks.append(item(
        "SEC-004",
        "Swagger/OpenAPI desabilitado em produção",
        "ready" if "ATLAS_DOCS_ENABLED deve ser false em production" in config else "blocker",
        "5B",
        "Settings rejeita documentação habilitada em production.",
        "Manter documentação desligada no ambiente de produção.",
    ))
    checks.append(item(
        "SEC-005",
        "URL pública HTTPS em produção",
        "ready" if "ATLAS_PUBLIC_BASE_URL deve usar https://" in config else "blocker",
        "5B",
        "Settings exige HTTPS em staging/production e rejeita host local em production.",
        "Manter URL pública HTTPS real no deploy.",
    ))
    checks.append(item(
        "SEC-006",
        "Chave IoT padrão proibida em produção",
        "ready" if "ATLAS_IOT_INGEST_KEY deve ter ao menos 32 caracteres" in config else "blocker",
        "5B",
        "Settings exige chave IoT forte e sem marcador inseguro em staging/production.",
        "Gerar chave IoT por secret manager e rotacioná-la quando necessário.",
    ))
    auth_markers = (
        '@router.post("/login"', '@router.post("/refresh"', '@router.post("/logout"',
        '@router.get("/sessions"', '@router.post("/password/request"',
        '@router.post("/password/confirm"', '@router.post("/mfa/setup"',
        '@router.post("/mfa/verify"',
    )
    checks.append(item(
        "AUTH-001",
        "Sessões, refresh, recuperação e MFA",
        "ready" if all(marker in auth for marker in auth_markers) and 'validate_password_strength' in security else "blocker",
        "5C",
        "auth.py expõe login/refresh/logout/sessions/password/MFA e security.py valida força de senha.",
        "Homologar com testes negativos, revogação e isolamento por tenant.",
    ))
    checks.append(item(
        "NET-001",
        "Headers HTTP de segurança",
        "ready" if all(marker in middleware for marker in ('X-Content-Type-Options', 'X-Frame-Options', 'Strict-Transport-Security')) else "blocker",
        "5B",
        "security_middleware aplica nosniff, DENY, Referrer/Permissions e HSTS em ambiente production-like.",
        "Manter e cobrir por teste.",
    ))
    checks.append(item(
        "NET-002",
        "Rate limit compartilhado entre instâncias",
        "ready" if "DistributedRateLimiter" in middleware and "Redis.from_url" in middleware else "blocker",
        "5F",
        "Rate limiter usa Redis compartilhado; fallback local existe apenas fora de production-like.",
        "Manter Redis disponível e monitorado em produção.",
    ))
    checks.append(item(
        "NET-003",
        "Confiança de proxy/X-Forwarded-For",
        "ready" if all(marker in middleware for marker in (
            "resolve_client_ip",
            "_peer_is_trusted_proxy",
            "atlas_trust_proxy_headers",
        )) else "blocker",
        "5B",
        "Forwarded headers só são honrados quando habilitados e o peer direto pertence a CIDR confiável.",
        "Manter proxy trust explícito e desabilitado por padrão.",
    ))
    checks.append(item(
        "ATT-001",
        "Fotos multi-dispositivo com autoridade remota",
        "ready" if (
            "AnimalMediaRemoteService" in photo
            and "_remote.list" in photo
            and "_remote.create" in photo
            and "atlas_animal_photos_cache_" in photo
        ) else "blocker",
        "5D",
        "Backend animal-media é autoridade; SharedPreferences guarda somente snapshot confirmado/cache.",
        "Manter cache local subordinado ao backend.",
    ))
    checks.append(item(
        "ATT-002",
        "Documentos multi-dispositivo com autoridade remota",
        "ready" if (
            "AnimalMediaRemoteService" in document
            and "_remote.list" in document
            and "_remote.create" in document
            and "atlas_animal_documents_cache_" in document
        ) else "blocker",
        "5D",
        "Backend animal-media é autoridade; SharedPreferences guarda somente snapshot confirmado/cache.",
        "Manter cache local subordinado ao backend.",
    ))
    checks.append(item(
        "ATT-003",
        "Anexos Android portáveis",
        "deferred_marco6" if ("Process.start('cmd'" in document_screen or 'Caminho da imagem' in photo_form) else "ready",
        "6",
        "Abertura de documento ainda contém comando Windows e foto pressupõe caminho manual.",
        "No Marco 6 usar picker/câmera/intent compatíveis com Android.",
    ))
    checks.append(item(
        "BKP-001",
        "Backup PostgreSQL",
        "ready" if 'pg_dump' in backup and 'cleanup' in backup else "blocker",
        "5G",
        "BackupService usa pg_dump custom format e retenção.",
        "Homologar execução real e retenção.",
    ))
    checks.append(item(
        "BKP-002",
        "Restauração testável",
        "ready" if ("pg_restore" in backup and "verify_restore" in backup and "dropdb" in backup) else "blocker",
        "5G",
        "BackupService cria bundle banco+anexos e verifica restore em banco temporário.",
        "Manter prova periódica de restore no ambiente operacional.",
    ))

    blockers = [row for row in checks if row["status"] == "blocker"]
    ready = [row for row in checks if row["status"] == "ready"]
    deferred = [row for row in checks if row["status"].startswith("deferred")]

    expected_blocker_codes = set()
    actual_blocker_codes = {row["code"] for row in blockers}
    inventory_errors: list[str] = []
    if actual_blocker_codes != expected_blocker_codes:
        inventory_errors.append(
            "Conjunto de bloqueadores mudou sem reclassificação explícita: "
            f"esperado={sorted(expected_blocker_codes)} atual={sorted(actual_blocker_codes)}"
        )

    report = {
        "status": "INVENTORIED" if not inventory_errors else "FAIL",
        "ready_count": len(ready),
        "blocker_count": len(blockers),
        "deferred_count": len(deferred),
        "inventory_errors": inventory_errors,
        "checks": checks,
        "recommended_sequence": [
            "5A baseline imutável + inventário de produção",
            "5B configuração, secrets, HTTPS/proxy e superfície da API",
            "5C autenticação, sessões, MFA, recuperação e isolamento tenant/fazenda",
            "5D Fotos/Documentos com armazenamento remoto autenticado",
            "5E transações, concorrência e idempotência dos fluxos críticos",
            "5F rate limit distribuído, resiliência e observabilidade",
            "5G backup + restauração comprovada",
            "5H gate estrito de produção e release candidate",
            "Marco 6 Android V1 e experiência nativa de anexos",
        ],
    }
    (ROOT / "ATLAS_MARCO5A_PRODUCTION_READINESS.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if inventory_errors:
        print("ATLAS MARCO 5A PRODUCTION READINESS: FAIL")
        return 1
    print("ATLAS MARCO 5A PRODUCTION READINESS: INVENTORIED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
