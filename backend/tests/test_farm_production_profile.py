def _login(client, email, password, company_id=None):
    payload = {"email": email, "password": password}
    if company_id is not None:
        payload["company_id"] = company_id
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 200
    return response.json()


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def test_farm_profile_defaults_to_mixed_for_legacy_compatible_creation(client):
    admin = _login(client, "admin@test.local", "Test@123456")
    headers = _auth(admin["access_token"])

    response = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Fazenda Compatível", "city": "Sobradinho", "state": "GO"},
    )

    assert response.status_code == 200
    assert response.json()["production_profile"] == "mixed"
    assert response.json()["production_system"] == ""


def test_farm_profile_and_system_can_be_created_and_updated(client):
    admin = _login(client, "admin@test.local", "Test@123456")
    headers = _auth(admin["access_token"])
    created = client.post(
        "/api/v1/farms",
        headers=headers,
        json={
            "name": "Leite Atlas",
            "city": "Sobradinho",
            "state": "GO",
            "production_profile": "dairy",
            "production_system": "Semi-intensivo",
        },
    )

    assert created.status_code == 200
    farm = created.json()
    assert farm["production_profile"] == "dairy"
    assert farm["production_system"] == "Semi-intensivo"

    updated = client.patch(
        f"/api/v1/farms/{farm['id']}",
        headers=headers,
        json={"production_profile": "beef", "production_system": "Ciclo completo"},
    )

    assert updated.status_code == 200
    assert updated.json()["production_profile"] == "beef"
    assert updated.json()["production_system"] == "Ciclo completo"


def test_farm_profile_rejects_values_outside_supported_profiles(client):
    admin = _login(client, "admin@test.local", "Test@123456")
    response = client.post(
        "/api/v1/farms",
        headers=_auth(admin["access_token"]),
        json={
            "name": "Perfil inválido",
            "city": "Sobradinho",
            "state": "GO",
            "production_profile": "equine",
        },
    )

    assert response.status_code == 422
