
def test_register_confirm_login_refresh_logout(client):
    registration = client.post(
        "/api/v1/auth/register",
        json={
            "name": "Gabriel Teste",
            "email": "gabriel.phase42@example.com",
            "password": "Atlas@Senha123",
            "company_name": "Fazenda Teste",
            "company_document": "",
            "accept_terms": True,
        },
    )
    assert registration.status_code == 201
    token = registration.json()["verification_token"]
    assert token

    confirmation = client.post(
        "/api/v1/auth/confirm-email",
        json={"token": token},
    )
    assert confirmation.status_code == 200

    login = client.post(
        "/api/v1/auth/login",
        json={
            "email": "gabriel.phase42@example.com",
            "password": "Atlas@Senha123",
        },
    )
    assert login.status_code == 200
    payload = login.json()
    assert payload["access_token"]
    assert payload["refresh_token"]

    refreshed = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": payload["refresh_token"]},
    )
    assert refreshed.status_code == 200
    refreshed_payload = refreshed.json()
    assert refreshed_payload["access_token"]
    assert refreshed_payload["refresh_token"] != payload["refresh_token"]

    logout = client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": refreshed_payload["refresh_token"]},
    )
    assert logout.status_code == 200


def test_password_rejects_weak_value(client):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "name": "Usuário Fraco",
            "email": "weak@example.com",
            "password": "1234567890",
            "company_name": "Empresa",
            "accept_terms": True,
        },
    )
    assert response.status_code == 422
