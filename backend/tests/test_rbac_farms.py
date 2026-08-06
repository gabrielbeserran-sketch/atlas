def _login(client, email, password, company_id=None):
    payload = {"email": email, "password": password}
    if company_id is not None:
        payload["company_id"] = company_id
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 200
    return response.json()


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def test_farms_create_deny_is_enforced_by_api(client):
    admin = _login(client, "admin@test.local", "Test@123456")
    headers = _auth(admin["access_token"])

    member = client.post(
        "/api/v1/members",
        headers=headers,
        json={
            "name": "Leitor Atlas",
            "email": "viewer@test.local",
            "password": "Viewer@123",
            "role": "viewer",
            "permission_overrides": {"farms.create": "deny"},
        },
    )
    assert member.status_code == 200

    viewer = _login(
        client,
        "viewer@test.local",
        "Viewer@123",
        admin["company_id"],
    )
    assert "farms.create" not in viewer["effective_permissions"]

    denied = client.post(
        "/api/v1/farms",
        headers=_auth(viewer["access_token"]),
        json={"name": "Não pode", "city": "Brasília", "state": "DF"},
    )
    assert denied.status_code == 403
    assert "farms.create" in denied.json()["detail"]

    farms = client.get(
        "/api/v1/farms",
        headers=_auth(viewer["access_token"]),
    )
    assert farms.status_code == 200
    assert farms.json() == []
