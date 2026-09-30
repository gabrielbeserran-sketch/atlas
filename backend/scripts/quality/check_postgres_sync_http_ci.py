"""Authenticated offline-sync proof on the disposable PostgreSQL CI service only."""

from __future__ import annotations

import os
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from threading import Barrier

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import func, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from scripts.quality.check_postgres_ci_contract import validate_ci_target


_STAGE = "guard"


def _stage(value: str) -> None:
    global _STAGE
    _STAGE = value


def _operation(
    *, company: str = "ci-company", tenant: str = "ci-tenant",
    farm: str = "ci-farm", entity: str = "ci-note-a",
    operation: str = "ci-sync-1", key: str = "ci-sync-key-1",
    payload: dict | None = None, base_version: int = 0,
) -> dict:
    return {
        "operation_id": operation, "idempotency_key": key,
        "tenant_id": tenant, "company_id": company, "farm_id": farm,
        "entity_type": "farm_note", "entity_id": entity,
        "operation_type": "update", "payload": payload or {"value": 1},
        "base_version": base_version, "device_id": "ci-device",
    }


def main() -> None:
    _stage("guard")
    validate_ci_target(
        os.environ.get("ATLAS_DATABASE_URL", ""),
        actions=os.environ.get("GITHUB_ACTIONS", ""),
        environment=os.environ.get("ATLAS_ENV", ""),
    )

    from app.database import build_engine, get_db
    from app.models import (
        Company, EntityState, Farm, Membership, RefreshSession, SyncChange, User,
    )
    from app.routers import offline_sync, sync
    from app.security import create_access_token

    engine = build_engine(for_migrations=True)
    try:
        _stage("synthetic-identities")
        with Session(engine) as db:
            assert db.scalar(text("SELECT version_num FROM alembic_version")) == "20260929_0059"
            db.add_all([
                User(
                    id="ci-sync-user-a", name="Operador de sincronização",
                    email="ci-sync-a@atlas.invalid", password_hash="unused",
                ),
                Company(
                    id="ci-sync-company-b", tenant_id="ci-sync-tenant-b",
                    name="Outra empresa de teste",
                ),
                User(
                    id="ci-sync-user-b", name="Outro operador",
                    email="ci-sync-b@atlas.invalid", password_hash="unused",
                ),
            ])
            db.commit()
            db.add_all([
                Membership(
                    id="ci-sync-member-a", user_id="ci-sync-user-a",
                    company_id="ci-company", role="operator", farm_ids=["ci-farm"],
                ),
                RefreshSession(
                    id="ci-sync-session-a", user_id="ci-sync-user-a",
                    company_id="ci-company", token_hash="ci-sync-unused-a",
                    expires_at=datetime.now(timezone.utc) + timedelta(hours=1),
                ),
                Farm(
                    id="ci-sync-hidden-farm", tenant_id="ci-tenant",
                    company_id="ci-company", name="Fazenda fora da carteira",
                ),
                Farm(
                    id="ci-sync-farm-b", tenant_id="ci-sync-tenant-b",
                    company_id="ci-sync-company-b", name="Outra fazenda de teste",
                ),
                Membership(
                    id="ci-sync-member-b", user_id="ci-sync-user-b",
                    company_id="ci-sync-company-b", role="operator",
                    farm_ids=["ci-sync-farm-b"],
                ),
                RefreshSession(
                    id="ci-sync-session-b", user_id="ci-sync-user-b",
                    company_id="ci-sync-company-b", token_hash="ci-sync-unused-b",
                    expires_at=datetime.now(timezone.utc) + timedelta(hours=1),
                ),
            ])
            try:
                db.commit()
            except IntegrityError as exc:
                constraint = getattr(getattr(exc.orig, "diag", None), "constraint_name", None)
                print(f"::error title=PostgreSQL sync fixture::constraint={constraint or 'unknown'}")
                raise

        app = FastAPI()
        app.include_router(sync.router, prefix="/api/v1")
        app.include_router(offline_sync.router, prefix="/api/v1")

        def override_db():
            with Session(engine) as db:
                yield db

        app.dependency_overrides[get_db] = override_db
        a = {"Authorization": "Bearer " + create_access_token(
            user_id="ci-sync-user-a", company_id="ci-company", tenant_id="ci-tenant",
            role="operator", extra={"session_id": "ci-sync-session-a"},
        )}
        b = {"Authorization": "Bearer " + create_access_token(
            user_id="ci-sync-user-b", company_id="ci-sync-company-b",
            tenant_id="ci-sync-tenant-b", role="operator",
            extra={"session_id": "ci-sync-session-b"},
        )}
        with TestClient(app) as client:
            _stage("jwt-and-batch-scope")
            assert client.get("/api/v1/offline/status").status_code in {401, 403}
            batch = client.post("/api/v1/offline/push-batch", headers=a, json={
                "operations": [
                    _operation(),
                    _operation(
                        farm="ci-sync-hidden-farm", entity="ci-hidden-note",
                        operation="ci-sync-hidden", key="ci-sync-hidden-key",
                    ),
                ],
            })
            assert batch.status_code == 200, batch.text
            assert (batch.json()["accepted"], batch.json()["rejected"]) == (1, 1)
            assert batch.json()["results"][1]["retryable"] is False
            assert batch.json()["results"][1]["remote_payload"] == {}

            _stage("idempotency-conflict-and-cursor")
            replay = client.post("/api/v1/sync/push", headers=a, json=_operation())
            assert replay.status_code == 200 and replay.json()["accepted"]
            assert replay.json()["remote_version"] == 1
            changed_replay = client.post("/api/v1/sync/push", headers=a, json={
                **_operation(), "payload": {"private": "changed"},
            })
            assert changed_replay.status_code == 200
            assert changed_replay.json()["accepted"] is False
            assert changed_replay.json()["remote_payload"] == {}
            conflict = client.post("/api/v1/offline/push-batch", headers=a, json={
                "operations": [_operation(
                    operation="ci-sync-conflict", key="ci-sync-conflict-key",
                    payload={"value": 2},
                )],
            })
            assert conflict.status_code == 200 and conflict.json()["conflicts"] == 1
            first = client.get(
                "/api/v1/offline/pull-page", params={"limit": 1}, headers=a,
            )
            assert first.status_code == 200, first.text
            assert [row["entity_id"] for row in first.json()["changes"]] == ["ci-note-a"]
            assert client.get(
                "/api/v1/offline/pull-page", headers=a,
                params={"farm_id": "ci-sync-hidden-farm"},
            ).status_code == 403
            assert client.get("/api/v1/offline/pull-page", headers=b).json()["changes"] == []
            assert client.get("/api/v1/offline/conflicts", headers=b).json() == []

            _stage("conflict-resolution-and-company-isolation")
            conflict_id = client.get("/api/v1/offline/conflicts", headers=a).json()[0]["id"]
            path = f"/api/v1/offline/conflicts/{conflict_id}/resolve"
            assert client.post(path, json={"resolution": "keep_local"}, headers=b).status_code == 404
            resolved = client.post(path, json={"resolution": "keep_local"}, headers=a)
            assert resolved.status_code == 200, resolved.text
            assert resolved.json()["version"] == 2
            second = client.get(
                "/api/v1/offline/pull-page", headers=a,
                params={"cursor": first.json()["next_cursor"]},
            )
            assert second.status_code == 200
            assert [row["version"] for row in second.json()["changes"]] == [2]
            assert second.json()["changes"][0]["payload"] == {"value": 2}
            other = client.post("/api/v1/sync/push", headers=b, json=_operation(
                company="ci-sync-company-b", tenant="ci-sync-tenant-b",
                farm="ci-sync-farm-b", entity="ci-note-b",
                operation="ci-sync-b", key="ci-sync-key-b",
                payload={"private": "company-b"},
            ))
            assert other.status_code == 200 and other.json()["accepted"]
            assert [row["entity_id"] for row in client.get(
                "/api/v1/offline/pull-page", headers=b,
            ).json()["changes"]] == ["ci-note-b"]
            assert all(row["entity_id"] != "ci-note-b" for row in client.get(
                "/api/v1/offline/pull-page", headers=a,
            ).json()["changes"])

            _stage("two-device-version-race")
            barrier = Barrier(3)
            first_race = _operation(
                operation="ci-sync-race-1", key="ci-sync-race-key-1",
                payload={"device": "one"}, base_version=2,
            )
            second_race = _operation(
                operation="ci-sync-race-2", key="ci-sync-race-key-2",
                payload={"device": "two"}, base_version=2,
            )

            def online_push():
                barrier.wait(timeout=10)
                return client.post("/api/v1/sync/push", headers=a, json=first_race)

            def offline_push():
                barrier.wait(timeout=10)
                return client.post(
                    "/api/v1/offline/push-batch", headers=a,
                    json={"operations": [second_race]},
                )

            with ThreadPoolExecutor(max_workers=2) as pool:
                online_future = pool.submit(online_push)
                offline_future = pool.submit(offline_push)
                barrier.wait(timeout=10)
                online = online_future.result(timeout=20)
                offline = offline_future.result(timeout=20)
            assert online.status_code == offline.status_code == 200
            outcomes = [online.json(), offline.json()["results"][0]]
            assert sorted(result["accepted"] for result in outcomes) == [False, True]
            accepted = next(result for result in outcomes if result["accepted"])
            rejected = next(result for result in outcomes if not result["accepted"])
            assert accepted["remote_version"] == rejected["remote_version"] == 3
            assert rejected["conflict"] is True
            assert rejected["remote_payload"] == accepted["remote_payload"]
            assert accepted["remote_payload"] in (
                {"device": "one"}, {"device": "two"},
            )

            _stage("durability-and-revocation")
            with Session(engine) as db:
                assert db.scalar(select(func.count()).select_from(EntityState)) == 2
                assert db.scalar(select(func.count()).select_from(SyncChange)) == 4
                assert db.scalar(select(EntityState).where(
                    EntityState.entity_id == "ci-note-a",
                )).payload == accepted["remote_payload"]
                db.get(Membership, "ci-sync-member-a").active = False
                db.commit()
            assert client.get("/api/v1/offline/status", headers=a).status_code == 401
            assert client.get("/api/v1/offline/status", headers=b).status_code == 200
    finally:
        engine.dispose()

    print("PostgreSQL CI: sincronização HTTP, isolamento e conflito aprovados.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        last = exc.__traceback__
        while last is not None and last.tb_next is not None:
            last = last.tb_next
        line = last.tb_lineno if last is not None else 0
        print(
            f"::error title=PostgreSQL sync HTTP CI::"
            f"stage={_STAGE}; type={type(exc).__name__}; line={line}"
        )
        raise
