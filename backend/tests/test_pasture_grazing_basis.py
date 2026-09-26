from datetime import datetime, timedelta, timezone

from app.database import SessionLocal, engine
from app.models import Farm, Membership, Company, PastureGrazingBasis
from sqlalchemy import select


def setup(client):
    login = client.post("/api/v1/auth/login", json={"email": "admin@test.local", "password": "Test@123456"})
    assert login.status_code == 200
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    farm = client.post("/api/v1/farms", headers=headers, json={"name": "Pastejo", "area": 50})
    assert farm.status_code == 200
    return headers, farm.json()["id"]


def path(farm):
    return f"/api/v1/livestock/farms/{farm}/grazing-basis"


def payload():
    return {
        "client_operation_id": "grazing-offline-001", "effective_area_ha": 20.5,
        "grazing_animals": 30, "unique_area_confirmed": True,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
    }


def test_retry_conflict_and_history(client):
    headers, farm = setup(client)
    data = payload()
    first = client.post(path(farm), headers=headers, json=data)
    assert first.status_code == 201, first.text
    repeated = client.post(path(farm), headers=headers, json=data)
    assert repeated.status_code == 201
    assert first.json()["id"] == repeated.json()["id"]
    assert first.json()["effective_area_ha"] == 20.5
    assert datetime.fromisoformat(first.json()["recorded_at"]).utcoffset() == timedelta(0)
    assert datetime.fromisoformat(first.json()["created_at"]).utcoffset() == timedelta(0)
    for field, value in [("effective_area_ha", 21), ("grazing_animals", 31),
                         ("recorded_at", (datetime.now(timezone.utc) - timedelta(days=1)).isoformat())]:
        assert client.post(path(farm), headers=headers, json={**data, field: value}).status_code == 409
    second_farm = client.post("/api/v1/farms", headers=headers, json={"name": "Outra"}).json()["id"]
    assert client.post(path(second_farm), headers=headers, json=data).status_code == 409
    assert client.get(path(second_farm), headers=headers).json() == []
    assert len(client.get(path(farm), headers=headers).json()) == 1


def test_invalid_inputs_never_create_records(client):
    headers, farm = setup(client)
    for field, value in [("effective_area_ha", 0), ("effective_area_ha", 51),
                         ("grazing_animals", 0), ("grazing_animals", 1.5),
                         ("unique_area_confirmed", False), ("client_operation_id", "        "),
                         ("recorded_at", "2026-01-01T00:00:00"),
                         ("recorded_at", (datetime.now(timezone.utc) + timedelta(days=1)).isoformat()),
                         ("company_id", "forged")]:
        response = client.post(path(farm), headers=headers, json={**payload(), field: value})
        assert response.status_code == 422, response.text
    assert client.get(path(farm), headers=headers).json() == []


def test_scope_permissions_and_capability(client):
    headers, farm = setup(client)
    assert client.get(path(farm)).status_code == 403
    assert client.get(path(farm) + "/capabilities", headers=headers).json() == {
        "client_operation_id_idempotency": True, "append_only": True,
    }
    with SessionLocal() as db:
        company = Company(id="foreign", tenant_id="foreign-tenant", name="Outra empresa")
        db.add(company)
        db.flush()
        db.add(Farm(id="foreign-farm", tenant_id=company.tenant_id, company_id=company.id, name="Externa"))
        db.commit()
    for suffix in ["", "/capabilities"]:
        assert client.get(path("foreign-farm") + suffix, headers=headers).status_code == 404
    assert client.post(path("foreign-farm"), headers=headers, json=payload()).status_code == 404
    with SessionLocal() as db:
        member = db.scalar(select(Membership))
        member.role = "viewer"
        member.farm_ids = ["different-farm"]
        db.commit()
    login = client.post("/api/v1/auth/login", json={"email": "admin@test.local", "password": "Test@123456"})
    assert login.status_code == 200
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    assert client.get(path(farm), headers=headers).status_code == 403
    assert client.post(path(farm), headers=headers, json=payload()).status_code == 403


def test_history_pagination_and_utc_replay(client):
    headers, farm = setup(client)
    data = payload()
    assert client.post(path(farm), headers=headers, json=data).status_code == 201
    data["recorded_at"] = datetime.fromisoformat(data["recorded_at"]).astimezone(timezone(timedelta(hours=-3))).isoformat()
    assert client.post(path(farm), headers=headers, json=data).status_code == 201
    data["client_operation_id"] = "grazing-offline-002"
    data["recorded_at"] = (datetime.now(timezone.utc) - timedelta(days=2)).isoformat()
    assert client.post(path(farm), headers=headers, json=data).status_code == 201
    first = client.get(path(farm) + "?limit=1", headers=headers).json()
    second = client.get(path(farm) + "?limit=1&offset=1", headers=headers).json()
    assert first[0]["client_operation_id"] == "grazing-offline-001"
    assert second[0]["client_operation_id"] == "grazing-offline-002"
    assert client.get(path(farm) + "?offset=-1", headers=headers).status_code == 422


def test_unmigrated_storage_does_not_advertise_safe_sync(client):
    headers, farm = setup(client)
    PastureGrazingBasis.__table__.drop(engine)
    assert client.get(path(farm) + "/capabilities", headers=headers).json() == {
        "client_operation_id_idempotency": False, "append_only": False,
    }
    assert client.get(path(farm), headers=headers).status_code == 503
    assert client.post(path(farm), headers=headers, json=payload()).status_code == 503
