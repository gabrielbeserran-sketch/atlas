from __future__ import annotations

from datetime import datetime, timezone


def _headers(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@test.local", "password": "Test@123456"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _animal(client, headers, farm_id, lot_id, tag):
    response = client.post(
        "/api/v1/livestock/animals",
        headers=headers,
        json={
            "farm_id": farm_id,
            "lot_id": lot_id,
            "tag": tag,
            "name": tag,
            "sex": "Fêmea",
            "breed": "Nelore",
            "category": "Matriz",
            "status": "active",
            "current_weight": 400,
        },
    )
    assert response.status_code == 201
    return response.json()["id"]


def _setup(client):
    headers = _headers(client)
    farm = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Fazenda Pesagens", "city": "Goiânia", "state": "GO"},
    )
    assert farm.status_code == 200
    farm_id = farm.json()["id"]
    lot = client.post(
        "/api/v1/livestock/lots",
        headers=headers,
        json={"farm_id": farm_id, "name": "Matrizes", "category": "Vacas"},
    )
    assert lot.status_code == 201
    lot_id = lot.json()["id"]
    return headers, (
        _animal(client, headers, farm_id, lot_id, "BR-01"),
        _animal(client, headers, farm_id, lot_id, "BR-02"),
    )


def _path(animal_id):
    return f"/api/v1/livestock/animals/{animal_id}/weights"


def test_weight_sync_capability_requires_login_and_confirms_idempotency(client):
    path = "/api/v1/livestock/weight-sync-capabilities"
    assert client.get(path).status_code == 403
    response = client.get(path, headers=_headers(client))
    assert response.status_code == 200
    assert response.json() == {"client_operation_id_idempotency": True}


def test_weight_retry_reuses_record_without_duplicate(client):
    headers, (first_animal, _) = _setup(client)
    payload = {
        "client_operation_id": "weight-offline-001",
        "weight": 445,
        "body_condition_score": 3.5,
        "source": "Balança do curral",
        "equipment": "B-1",
        "measured_at": datetime(2026, 9, 23, 12, tzinfo=timezone.utc).isoformat(),
        "notes": "Jejum de 12 horas",
    }
    first = client.post(_path(first_animal), headers=headers, json=payload)
    repeated = client.post(_path(first_animal), headers=headers, json=payload)

    assert first.status_code == 201
    assert repeated.status_code == 201
    assert repeated.json()["id"] == first.json()["id"]
    assert repeated.json()["client_operation_id"] == "weight-offline-001"
    history = client.get(_path(first_animal), headers=headers)
    assert history.status_code == 200
    assert len(history.json()) == 1
    animal = client.get(
        f"/api/v1/livestock/animals/{first_animal}", headers=headers
    )
    assert animal.json()["current_weight"] == 445


def test_weight_operation_id_rejects_changed_payload_or_animal(client):
    headers, (first_animal, second_animal) = _setup(client)
    payload = {"client_operation_id": "weight-offline-002", "weight": 430}
    first = client.post(_path(first_animal), headers=headers, json=payload)
    assert first.status_code == 201

    changed_weight = client.post(
        _path(first_animal), headers=headers, json={**payload, "weight": 431}
    )
    changed_animal = client.post(_path(second_animal), headers=headers, json=payload)
    assert changed_weight.status_code == 409
    assert changed_animal.status_code == 409
    assert len(client.get(_path(first_animal), headers=headers).json()) == 1
    assert client.get(_path(second_animal), headers=headers).json() == []


def test_legacy_weight_posts_without_key_remain_distinct(client):
    headers, (first_animal, _) = _setup(client)
    first = client.post(_path(first_animal), headers=headers, json={"weight": 410})
    second = client.post(_path(first_animal), headers=headers, json={"weight": 410})
    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["id"] != second.json()["id"]
    assert first.json()["client_operation_id"] is None
    assert len(client.get(_path(first_animal), headers=headers).json()) == 2


def test_short_operation_id_is_rejected(client):
    headers, (first_animal, _) = _setup(client)
    response = client.post(
        _path(first_animal),
        headers=headers,
        json={"weight": 410, "client_operation_id": "short"},
    )
    assert response.status_code == 422
