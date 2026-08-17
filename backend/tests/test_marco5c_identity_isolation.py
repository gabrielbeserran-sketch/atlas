from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.database import SessionLocal
from app.models import MfaCredential, RefreshSession, User
from app.security import (
    decrypt_mfa_secret,
    encrypt_mfa_secret,
    token_digest,
    totp_code,
)


def login(client, email="admin@test.local", password="Test@123456"):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert response.status_code == 200
    return response.json()


def headers(access_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {access_token}"}


def test_logout_revokes_access_token_immediately(client):
    session = login(client)
    assert client.get("/api/v1/auth/me", headers=headers(session["access_token"])).status_code == 200

    logged_out = client.post(
        "/api/v1/auth/logout",
        json={"refresh_token": session["refresh_token"]},
    )
    assert logged_out.status_code == 200

    assert client.get(
        "/api/v1/auth/me",
        headers=headers(session["access_token"]),
    ).status_code == 401


def test_refresh_rotation_revokes_previous_access_token(client):
    first = login(client)
    refreshed = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": first["refresh_token"], "device_name": "rotated"},
    )
    assert refreshed.status_code == 200
    second = refreshed.json()

    assert client.get(
        "/api/v1/auth/me",
        headers=headers(first["access_token"]),
    ).status_code == 401
    assert client.get(
        "/api/v1/auth/me",
        headers=headers(second["access_token"]),
    ).status_code == 200

    reused = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": first["refresh_token"]},
    )
    assert reused.status_code == 401


def test_password_reset_revokes_existing_access_sessions(client):
    session = login(client)

    requested = client.post(
        "/api/v1/auth/password/request",
        json={"email": "admin@test.local"},
    )
    assert requested.status_code == 200

    # Test mailer exposes sent messages in test/dev through its in-memory outbox.
    from app.services.mailer import mailer

    message = mailer.latest_for("admin@test.local")
    assert message is not None
    token = message.body.split("Token temporário: ", 1)[1].strip()
    confirmed = client.post(
        "/api/v1/auth/password/confirm",
        json={"token": token, "new_password": "NovaSenha@123"},
    )
    assert confirmed.status_code == 200

    assert client.get(
        "/api/v1/auth/me",
        headers=headers(session["access_token"]),
    ).status_code == 401


def test_only_latest_password_reset_token_remains_valid(client):
    from app.services.mailer import mailer

    for _ in range(2):
        response = client.post(
            "/api/v1/auth/password/request",
            json={"email": "admin@test.local"},
        )
        assert response.status_code == 200

    messages = [
        item for item in mailer._messages
        if item.to == "admin@test.local" and "Token temporário: " in item.body
    ]
    first_token = messages[-2].body.split("Token temporário: ", 1)[1].strip()
    second_token = messages[-1].body.split("Token temporário: ", 1)[1].strip()

    old = client.post(
        "/api/v1/auth/password/confirm",
        json={"token": first_token, "new_password": "NuncaUsada@123"},
    )
    assert old.status_code == 400

    current = client.post(
        "/api/v1/auth/password/confirm",
        json={"token": second_token, "new_password": "NovaSenha@123"},
    )
    assert current.status_code == 200


def test_admin_password_reset_revokes_member_access_token(client):
    admin = login(client)
    admin_headers = headers(admin["access_token"])

    member = client.post(
        "/api/v1/members",
        headers=admin_headers,
        json={
            "name": "Membro 5C",
            "email": "membro5c@test.local",
            "password": "Membro@12345",
            "role": "viewer",
            "farm_ids": [],
            "permission_overrides": {},
        },
    )
    assert member.status_code == 200

    member_session = login(
        client,
        email="membro5c@test.local",
        password="Membro@12345",
    )

    reset = client.post(
        f"/api/v1/members/{member.json()['membership_id']}/reset-password",
        headers=admin_headers,
        json={"password": "MembroNovo@123"},
    )
    assert reset.status_code == 200

    assert client.get(
        "/api/v1/auth/me",
        headers=headers(member_session["access_token"]),
    ).status_code == 401


def test_mfa_secret_is_encrypted_at_rest_and_challenge_works(client):
    session = login(client)
    auth_headers = headers(session["access_token"])

    setup = client.post("/api/v1/auth/mfa/setup", headers=auth_headers)
    assert setup.status_code == 200
    secret = setup.json()["secret"]

    with SessionLocal() as db:
        credential = db.query(MfaCredential).filter(MfaCredential.user_id == session["user_id"]).one()
        assert credential.secret_encrypted != secret
        assert decrypt_mfa_secret(credential.secret_encrypted) == secret

    verify = client.post(
        "/api/v1/auth/mfa/verify",
        headers=auth_headers,
        json={"code": totp_code(secret)},
    )
    assert verify.status_code == 200

    relogin = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@test.local", "password": "Test@123456"},
    )
    assert relogin.status_code == 200
    body = relogin.json()
    assert body["mfa_required"] is True
    assert body["access_token"] == ""

    completed = client.post(
        "/api/v1/auth/mfa/challenge",
        json={
            "challenge_token": body["challenge_token"],
            "code": totp_code(secret),
        },
    )
    assert completed.status_code == 200
    assert completed.json()["access_token"]


def test_expired_or_revoked_persisted_session_blocks_access(client):
    session = login(client)
    with SessionLocal() as db:
        persisted = db.query(RefreshSession).filter(
            RefreshSession.token_hash == token_digest(session["refresh_token"])
        ).one()
        persisted.expires_at = datetime.now(timezone.utc) - timedelta(seconds=1)
        db.commit()

    assert client.get(
        "/api/v1/auth/me",
        headers=headers(session["access_token"]),
    ).status_code == 401
