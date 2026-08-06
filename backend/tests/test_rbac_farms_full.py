def _login(client, email, password, company_id=None):
    payload = {"email": email, "password": password}
    if company_id is not None:
        payload["company_id"] = company_id
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 200
    return response.json()


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _create_member(client, headers, **overrides):
    payload = {
        "name": "Usuário RBAC",
        "email": "rbac@test.local",
        "password": "Rbac@123456",
        "role": "viewer",
        "farm_ids": [],
        "permission_overrides": {},
    }
    payload.update(overrides)
    response = client.post("/api/v1/members", headers=headers, json=payload)
    assert response.status_code == 200
    return response.json()


def test_farms_read_create_update_are_enforced(client):
    admin = _login(client, "admin@test.local", "Test@123456")
    admin_headers = _auth(admin["access_token"])

    farm = client.post(
        "/api/v1/farms",
        headers=admin_headers,
        json={"name": "Fazenda Protegida", "city": "Brasília", "state": "DF"},
    )
    assert farm.status_code == 200
    farm_id = farm.json()["id"]

    _create_member(
        client,
        admin_headers,
        permission_overrides={
            "farms.read": "deny",
            "farms.create": "deny",
            "farms.update": "deny",
        },
    )

    viewer = _login(
        client,
        "rbac@test.local",
        "Rbac@123456",
        admin["company_id"],
    )
    viewer_headers = _auth(viewer["access_token"])

    read_list = client.get("/api/v1/farms", headers=viewer_headers)
    assert read_list.status_code == 403
    assert "farms.read" in read_list.json()["detail"]

    read_one = client.get(f"/api/v1/farms/{farm_id}", headers=viewer_headers)
    assert read_one.status_code == 403
    assert "farms.read" in read_one.json()["detail"]

    create = client.post(
        "/api/v1/farms",
        headers=viewer_headers,
        json={"name": "Não autorizada", "city": "Brasília", "state": "DF"},
    )
    assert create.status_code == 403
    assert "farms.create" in create.json()["detail"]

    update = client.patch(
        f"/api/v1/farms/{farm_id}",
        headers=viewer_headers,
        json={"name": "Alteração indevida"},
    )
    assert update.status_code == 403
    assert "farms.update" in update.json()["detail"]

    delete = client.delete(f"/api/v1/farms/{farm_id}", headers=viewer_headers)
    assert delete.status_code == 403
    assert "farms.update" in delete.json()["detail"]


def test_farm_scope_blocks_direct_access_to_other_farm(client):
    admin = _login(client, "admin@test.local", "Test@123456")
    admin_headers = _auth(admin["access_token"])

    farm_a = client.post(
        "/api/v1/farms",
        headers=admin_headers,
        json={"name": "Fazenda A", "city": "Brasília", "state": "DF"},
    ).json()
    farm_b = client.post(
        "/api/v1/farms",
        headers=admin_headers,
        json={"name": "Fazenda B", "city": "Formosa", "state": "GO"},
    ).json()

    _create_member(
        client,
        admin_headers,
        email="scope@test.local",
        password="Scope@123456",
        role="manager",
        farm_ids=[farm_a["id"]],
    )

    scoped = _login(
        client,
        "scope@test.local",
        "Scope@123456",
        admin["company_id"],
    )
    scoped_headers = _auth(scoped["access_token"])

    listed = client.get("/api/v1/farms", headers=scoped_headers)
    assert listed.status_code == 200
    assert [item["id"] for item in listed.json()] == [farm_a["id"]]

    own = client.get(f"/api/v1/farms/{farm_a['id']}", headers=scoped_headers)
    assert own.status_code == 200

    foreign = client.get(f"/api/v1/farms/{farm_b['id']}", headers=scoped_headers)
    assert foreign.status_code == 403
    assert "carteira autorizada" in foreign.json()["detail"]

    foreign_update = client.patch(
        f"/api/v1/farms/{farm_b['id']}",
        headers=scoped_headers,
        json={"name": "Tentativa fora do escopo"},
    )
    assert foreign_update.status_code == 403
    assert "carteira autorizada" in foreign_update.json()["detail"]
