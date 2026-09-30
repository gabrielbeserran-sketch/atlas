"""Exercise authenticated grazing-basis HTTP routes on disposable PostgreSQL.

Only the loopback GitHub Actions database named atlas_ci_probe is accepted.
This intentionally writes synthetic records and must never target production.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from scripts.quality.check_postgres_ci_contract import SEEDED_ROWS, validate_ci_target


_STAGE = "guard"


def _stage(name: str) -> None:
    global _STAGE
    _STAGE = name


def main() -> None:
    _stage("guard")
    validate_ci_target(
        os.environ.get("ATLAS_DATABASE_URL", ""),
        actions=os.environ.get("GITHUB_ACTIONS", ""),
        environment=os.environ.get("ATLAS_ENV", ""),
    )

    from app.database import build_engine, get_db
    from app.models import (
        Company, Farm, Membership, PastureGrazingBasis, RefreshSession,
    )
    from app.routers import livestock
    from app.security import create_access_token

    engine = build_engine(for_migrations=True)
    try:
        _stage("synthetic-membership-and-hidden-farms")
        with Session(engine) as db:
            assert db.scalar(text("SELECT version_num FROM alembic_version")) == "20260929_0059"
            assert db.scalar(select(func.count()).select_from(PastureGrazingBasis)) == SEEDED_ROWS
            db.add_all([
                Membership(
                    id="ci-http-member", user_id="ci-user", company_id="ci-company",
                    role="operator", farm_ids=["ci-farm"],
                ),
                RefreshSession(
                    id="ci-http-session", user_id="ci-user", company_id="ci-company",
                    token_hash="ci-http-token-unused",
                    expires_at=datetime.now(timezone.utc) + timedelta(hours=1),
                ),
                Farm(
                    id="ci-hidden-farm", tenant_id="ci-tenant",
                    company_id="ci-company", name="Fazenda não autorizada",
                ),
                Company(
                    id="ci-other-company", tenant_id="ci-other-tenant",
                    name="Outra empresa descartável",
                ),
                Farm(
                    id="ci-other-farm", tenant_id="ci-other-tenant",
                    company_id="ci-other-company", name="Outra fazenda",
                ),
            ])
            origin = datetime(2026, 9, 1, tzinfo=timezone.utc)
            for farm_id, company_id, tenant_id in (
                ("ci-hidden-farm", "ci-company", "ci-tenant"),
                ("ci-other-farm", "ci-other-company", "ci-other-tenant"),
            ):
                db.add(PastureGrazingBasis(
                    id=f"{farm_id}-basis", tenant_id=tenant_id,
                    company_id=company_id, farm_id=farm_id,
                    client_operation_id=f"{farm_id}-operation",
                    effective_area_ha=3.5, grazing_animals=7,
                    unique_area_confirmed=True, recorded_at=origin,
                    created_at=origin + timedelta(days=1), created_by="ci-user",
                ))
            db.commit()

        app = FastAPI()
        app.include_router(livestock.router, prefix="/api/v1")

        def override_db():
            with Session(engine) as db:
                yield db

        app.dependency_overrides[get_db] = override_db
        token = create_access_token(
            user_id="ci-user", company_id="ci-company", tenant_id="ci-tenant",
            role="operator", extra={"session_id": "ci-http-session"},
        )
        headers = {"Authorization": f"Bearer {token}"}
        base = "/api/v1/livestock/farms/ci-farm/grazing-basis"
        with TestClient(app) as client:
            _stage("authentication-capabilities-and-farm-scope")
            assert client.get(f"{base}/cursor").status_code == 403
            capabilities = client.get(f"{base}/capabilities", headers=headers)
            assert capabilities.status_code == 200, capabilities.text
            assert capabilities.json() == {
                "client_operation_id_idempotency": True, "append_only": True,
            }
            for hidden in ("ci-hidden-farm", "ci-other-farm"):
                response = client.get(
                    f"/api/v1/livestock/farms/{hidden}/grazing-basis/cursor",
                    headers=headers,
                )
                assert response.status_code == 404, response.text

            _stage("first-cursor-page")
            first = client.get(
                f"{base}/cursor", params={"limit": 250}, headers=headers,
            )
            assert first.status_code == 200, first.text
            first_page = first.json()
            assert len(first_page) == 250
            assert first_page[0]["id"] == "ci-grazing-0999"

            _stage("idempotent-write-and-conflict")
            payload = {
                "client_operation_id": "ci-http-operation-1",
                "effective_area_ha": 20.5,
                "grazing_animals": 42,
                "unique_area_confirmed": True,
                "recorded_at": datetime.now(timezone.utc).isoformat(),
            }
            created = client.post(base, json=payload, headers=headers)
            assert created.status_code == 201, created.text
            replay = client.post(base, json=payload, headers=headers)
            assert replay.status_code == 201, replay.text
            assert replay.json()["id"] == created.json()["id"]
            conflict = client.post(
                base, json={**payload, "grazing_animals": 43}, headers=headers,
            )
            assert conflict.status_code == 409, conflict.text

            _stage("stable-cursor-after-concurrent-write")
            seen = [item["id"] for item in first_page]
            page = first_page
            while page:
                after = page[-1]
                response = client.get(
                    f"{base}/cursor",
                    params={
                        "limit": 250,
                        "after_created_at": after["created_at"],
                        "after_id": after["id"],
                    },
                    headers=headers,
                )
                assert response.status_code == 200, response.text
                page = response.json()
                seen.extend(item["id"] for item in page)
            assert len(seen) == len(set(seen)) == SEEDED_ROWS
            assert all(item.startswith("ci-grazing-") for item in seen)
            fresh = client.get(
                f"{base}/cursor", params={"limit": 1}, headers=headers,
            )
            assert fresh.status_code == 200
            assert fresh.json()[0]["id"] == created.json()["id"]
            assert client.get(base, params={"limit": 1}, headers=headers).status_code == 200

            _stage("membership-revocation")
            with Session(engine) as db:
                assert db.scalar(select(func.count()).select_from(PastureGrazingBasis)) == (
                    SEEDED_ROWS + 3
                )
                membership = db.get(Membership, "ci-http-member")
                membership.active = False
                db.commit()
            denied = client.get(f"{base}/cursor", headers=headers)
            assert denied.status_code in {401, 403}, denied.text
    finally:
        engine.dispose()

    print("PostgreSQL CI: JWT, escopo, cursor e idempotência HTTP aprovados.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        last = exc.__traceback__
        while last is not None and last.tb_next is not None:
            last = last.tb_next
        line = last.tb_lineno if last is not None else 0
        print(
            f"::error title=PostgreSQL grazing HTTP CI::"
            f"stage={_STAGE}; type={type(exc).__name__}; line={line}"
        )
        raise
