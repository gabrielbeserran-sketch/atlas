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


def test_animal_history_and_timeline(client):
    session = _login(client)
    headers = _headers(session["access_token"])

    farm = client.post(
        "/api/v1/farms",
        json={
            "name": "Fazenda Timeline",
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
            "tag": "TL-001",
            "name": "Matriz Timeline",
            "weight": 410,
            "body_condition_score": 3.2,
        },
        headers=headers,
    )
    assert created.status_code == 200
    animal_id = created.json()["id"]

    updated = client.patch(
        f"/api/v1/animals/{animal_id}",
        json={
            "weight": 425,
            "body_condition_score": 3.5,
            "notes": "Pesagem de acompanhamento.",
        },
        headers=headers,
    )
    assert updated.status_code == 200
    assert updated.json()["version"] == 2

    history = client.get(
        f"/api/v1/animals/{animal_id}/history",
        headers=headers,
    )
    assert history.status_code == 200
    history_payload = history.json()
    assert len(history_payload) == 2
    assert history_payload[0]["version"] == 2
    assert history_payload[0]["payload"]["weight"] == 425
    assert history_payload[1]["version"] == 1
    assert history_payload[1]["payload"]["weight"] == 410

    timeline = client.get(
        f"/api/v1/animals/{animal_id}/timeline",
        headers=headers,
    )
    assert timeline.status_code == 200
    timeline_payload = timeline.json()
    assert len(timeline_payload) == 2
    assert timeline_payload[0]["action"] == "update"
    assert timeline_payload[1]["action"] == "create"
    assert timeline_payload[0]["before"]["weight"] == 410
    assert timeline_payload[0]["after"]["weight"] == 425
