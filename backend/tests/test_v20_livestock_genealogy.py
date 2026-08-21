from __future__ import annotations


def _login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@test.local", "password": "Test@123456"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_genealogy_uses_canonical_livestock_animal(client):
    headers = _login(client)

    farm_response = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Fazenda Genealogia V20", "city": "Brasília", "state": "DF"},
    )
    assert farm_response.status_code == 200
    farm_id = farm_response.json()["id"]

    lot_response = client.post(
        "/api/v1/livestock/lots",
        headers=headers,
        json={"farm_id": farm_id, "name": "Matrizes V20", "category": "Matrizes"},
    )
    assert lot_response.status_code == 201
    lot_id = lot_response.json()["id"]

    mother_response = client.post(
        "/api/v1/livestock/animals",
        headers=headers,
        json={
            "farm_id": farm_id,
            "lot_id": lot_id,
            "tag": "V20-MAE-001",
            "name": "Mãe V20",
            "sex": "Fêmea",
            "breed": "Nelore",
            "category": "Matriz",
            "status": "active",
        },
    )
    assert mother_response.status_code == 201
    mother_id = mother_response.json()["id"]

    child_response = client.post(
        "/api/v1/livestock/animals",
        headers=headers,
        json={
            "farm_id": farm_id,
            "lot_id": lot_id,
            "tag": "V20-FILHA-001",
            "name": "Filha V20",
            "sex": "Fêmea",
            "breed": "Nelore",
            "category": "Novilha",
            "status": "active",
            "mother_id": mother_id,
        },
    )
    assert child_response.status_code == 201
    child_id = child_response.json()["id"]

    genealogy = client.get(
        f"/api/v1/livestock/animals/{child_id}/genealogy",
        headers=headers,
    )
    assert genealogy.status_code == 200
    payload = genealogy.json()
    assert payload["animal"]["id"] == child_id
    assert payload["animal"]["tag"] == "V20-FILHA-001"
    assert payload["mother"]["id"] == mother_id
    assert payload["mother"]["tag"] == "V20-MAE-001"

    # O erro que motivou a correção: o domínio legado não conhece o ID
    # criado em livestock_animals e não pode voltar a ser usado pelo Flutter.
    legacy = client.get(f"/api/v1/animals/{child_id}/genealogy", headers=headers)
    assert legacy.status_code == 404
