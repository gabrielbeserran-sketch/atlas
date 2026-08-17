from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(relative: str) -> str:
    path = ROOT / relative
    return path.read_text(encoding="utf-8-sig", errors="ignore") if path.is_file() else ""


def main() -> int:
    compose = read("deploy/free_oracle_duckdns/docker-compose.yml")
    caddy = read("deploy/free_oracle_duckdns/Caddyfile")
    prepare = read("deploy/free_oracle_duckdns/01_prepare_oracle_free_server.sh")
    duckdns = read("deploy/free_oracle_duckdns/02_install_duckdns.sh")
    deploy = read("deploy/free_oracle_duckdns/03_deploy_atlas_free.sh")
    audit = read("deploy/free_oracle_duckdns/04_audit_free_production.sh")
    gate = read("scripts/android/17_marco6_free_gate.ps1")

    checks = {
        "free_duckdns_hostname": ".duckdns.org" in compose,
        "duckdns_updater": "www.duckdns.org/update" in duckdns and "atlas-duckdns.timer" in duckdns,
        "automatic_https": "reverse_proxy api:8000" in caddy and '"443:443"' in compose,
        "database_not_public": "5432:5432" not in compose,
        "redis_not_public": "6379:6379" not in compose,
        "alembic_before_api": "service_completed_successfully" in compose,
        "persistent_database": "atlas_postgres:" in compose,
        "persistent_attachments": "atlas_attachments:" in compose,
        "persistent_backups": "atlas_backups:" in compose,
        "firewall": "ufw allow 80/tcp" in prepare and "ufw allow 443/tcp" in prepare,
        "strong_secrets": "require_secret ATLAS_JWT_SECRET 64" in deploy,
        "self_audit": "ATLAS FREE PRODUCTION AUDIT: APROVADO" in audit,
        "android_free_gate": "16_marco6_gate.ps1" in gate,
    }

    errors = [key for key, value in checks.items() if not value]
    report = {
        "status": "FAIL" if errors else "OK",
        "architecture": "Oracle Cloud Always Free + DuckDNS + Caddy",
        "monthly_cost_target_brl": 0,
        "checks": checks,
        "errors": errors,
    }

    (ROOT / "ATLAS_MARCO6_FREE_INFRASTRUCTURE_CONTRACT.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(
        "\nATLAS MARCO 6 FREE INFRASTRUCTURE CONTRACT:",
        "FAIL" if errors else "OK",
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
