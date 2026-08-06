from sqlalchemy import select

from app.database import SessionLocal
from app.models import Membership, User


def _login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "admin@test.local",
            "password": "Test@123456",
        },
    )
    assert response.status_code == 200
    return response.json()


def _headers(token):
    return {"Authorization": f"Bearer {token}"}


def test_rebanho_enterprise_crud_and_audit(client):
    auth = _login(client)
    headers = _headers(auth["access_token"])

    farm = client.post(
        "/api/v1/farms",
        json={
            "name": "Fazenda Rebanho",
            "city": "Brasília",
            "state": "DF",
        },
        headers=headers,
    )
    assert farm.status_code == 200
    farm_id = farm.json()["id"]

    created = client.post(
        "/api/v1/animals",
        json={
            "farm_id": farm_id,
            "group_name": "Matrizes",
            "tag": "A-001",
            "name": "Estrela",
            "sex": "Fêmea",
            "breed": "Nelore",
            "weight": 420,
            "status": "Ativo",
        },
        headers=headers,
    )
    assert created.status_code == 200
    animal = created.json()
    assert animal["tag"] == "A-001"
    assert animal["version"] == 1

    listed = client.get(
        f"/api/v1/animals?farm_id={farm_id}&group_name=Matrizes",
        headers=headers,
    )
    assert listed.status_code == 200
    assert len(listed.json()) == 1

    updated = client.patch(
        f"/api/v1/animals/{animal['id']}",
        json={"weight": 438, "body_condition_score": 3.5},
        headers=headers,
    )
    assert updated.status_code == 200
    assert updated.json()["weight"] == 438
    assert updated.json()["version"] == 2

    deleted = client.delete(
        f"/api/v1/animals/{animal['id']}",
        headers=headers,
    )
    assert deleted.status_code == 200

    listed_after = client.get(
        f"/api/v1/animals?farm_id={farm_id}",
        headers=headers,
    )
    assert listed_after.status_code == 200
    assert listed_after.json() == []

    audit = client.get(
        "/api/v1/audit?limit=100",
        headers=headers,
    )
    assert audit.status_code == 200
    actions = {
        item["action"]
        for item in audit.json()
        if item["module"] == "animals"
    }
    assert {"create", "update", "delete"}.issubset(actions)


def test_rebanho_permissions_are_enforced(client):
    auth = _login(client)
    admin_headers = _headers(auth["access_token"])

    farm = client.post(
        "/api/v1/farms",
        json={
            "name": "Fazenda Protegida",
            "city": "Formosa",
            "state": "GO",
        },
        headers=admin_headers,
    ).json()

    with SessionLocal() as db:
        user = db.scalar(
            select(User).where(User.email == "admin@test.local")
        )
        membership = db.scalar(
            select(Membership).where(
                Membership.user_id == user.id,
                Membership.company_id == auth["company_id"],
            )
        )
        membership.role = "viewer"
        membership.permission_overrides = {
            "animals.read": "deny",
            "animals.create": "deny",
            "animals.update": "deny",
            "animals.delete": "deny",
        }
        db.commit()

    viewer = _login(client)
    headers = _headers(viewer["access_token"])

    read = client.get(
        f"/api/v1/animals?farm_id={farm['id']}",
        headers=headers,
    )
    assert read.status_code == 403
    assert "animals.read" in read.json()["detail"]

    create = client.post(
        "/api/v1/animals",
        json={"farm_id": farm["id"], "tag": "B-001"},
        headers=headers,
    )
    assert create.status_code == 403
    assert "animals.create" in create.json()["detail"]
