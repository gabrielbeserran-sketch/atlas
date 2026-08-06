def login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "admin@test.local",
            "password": "Test@123456",
        },
    )
    assert response.status_code == 200
    return response.json()


def test_login_and_health(client):
    assert client.get("/api/v1/health").status_code == 200
    token = login(client)
    assert token["access_token"]
    assert token["company_id"]
    assert token["tenant_id"]


def test_sync_is_tenant_scoped_and_idempotent(client):
    auth = login(client)
    headers = {
        "Authorization": f"Bearer {auth['access_token']}"
    }

    body = {
        "operation_id": "op-1",
        "idempotency_key": "idem-1",
        "tenant_id": auth["tenant_id"],
        "company_id": auth["company_id"],
        "farm_id": None,
        "entity_type": "farm_note",
        "entity_id": "record-1",
        "operation_type": "create",
        "payload": {"value": 10},
        "base_version": 0,
        "device_id": "pytest",
    }

    first = client.post(
        "/api/v1/sync/push",
        json=body,
        headers=headers,
    )
    assert first.status_code == 200
    assert first.json()["accepted"] is True
    assert first.json()["remote_version"] == 1

    second = client.post(
        "/api/v1/sync/push",
        json=body,
        headers=headers,
    )
    assert second.status_code == 200
    assert second.json() == first.json()

    pull = client.get(
        "/api/v1/sync/pull?cursor=0",
        headers=headers,
    )
    assert pull.status_code == 200
    assert len(pull.json()) == 1


def test_stale_base_version_returns_conflict(client):
    auth = login(client)
    headers = {
        "Authorization": f"Bearer {auth['access_token']}"
    }

    common = {
        "tenant_id": auth["tenant_id"],
        "company_id": auth["company_id"],
        "farm_id": None,
        "entity_type": "animal",
        "entity_id": "a1",
        "operation_type": "update",
        "device_id": "pytest",
    }

    first = {
        **common,
        "operation_id": "op-a",
        "idempotency_key": "idem-a",
        "payload": {"weight": 400},
        "base_version": 0,
    }
    response = client.post(
        "/api/v1/sync/push",
        json=first,
        headers=headers,
    )
    assert response.json()["accepted"] is True

    stale = {
        **common,
        "operation_id": "op-b",
        "idempotency_key": "idem-b",
        "payload": {"weight": 410},
        "base_version": 0,
    }
    conflict = client.post(
        "/api/v1/sync/push",
        json=stale,
        headers=headers,
    )
    assert conflict.status_code == 200
    assert conflict.json()["conflict"] is True
    assert conflict.json()["remote_version"] == 1
