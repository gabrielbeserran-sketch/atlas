from fastapi.testclient import TestClient


def _headers(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@test.local", "password": "Test@123456"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_folder_is_listed_after_creation_and_decision_note_is_idempotent(
    client: TestClient,
) -> None:
    headers = _headers(client)
    farm = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Fazenda Anotações", "city": "Formosa", "state": "GO"},
    )
    assert farm.status_code == 200
    farm_id = farm.json()["id"]

    folder = client.post(
        "/api/v1/operational-notes/folders",
        headers=headers,
        json={"farm_id": farm_id, "name": "Sanidade"},
    )
    assert folder.status_code == 201
    folder_id = folder.json()["id"]

    folders = client.get(
        "/api/v1/operational-notes/folders",
        headers=headers,
        params={"farm_id": farm_id},
    )
    assert folders.status_code == 200
    assert any(item["id"] == folder_id and item["name"] == "Sanidade" for item in folders.json())

    payload = {
        "farm_id": farm_id,
        "content": "Decisão vinculada à análise\nRevisar manejo sanitário",
        "source": "intelligence_decision",
        "reference_type": "ai_recommendation",
        "reference_id": "recommendation-unique-1",
    }
    first = client.post("/api/v1/operational-notes", headers=headers, json=payload)
    repeated = client.post("/api/v1/operational-notes", headers=headers, json=payload)

    assert first.status_code == 201
    assert repeated.status_code == 201
    assert repeated.json()["id"] == first.json()["id"]

    notes = client.get(
        "/api/v1/operational-notes",
        headers=headers,
        params={"farm_id": farm_id},
    )
    linked = [
        item
        for item in notes.json()
        if item["reference_type"] == "ai_recommendation"
        and item["reference_id"] == "recommendation-unique-1"
    ]
    assert len(linked) == 1
