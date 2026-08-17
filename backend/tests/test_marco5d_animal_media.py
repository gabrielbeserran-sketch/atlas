from __future__ import annotations

from itertools import count

from app.config import get_settings
from app.database import SessionLocal
from app.models import AnimalMedia

_SEQUENCE = count(1)


def _login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@test.local", "password": "Test@123456"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _create_animal(client, headers) -> str:
    """Cria toda a precondição do teste pela API oficial.

    O teste não depende de animal, fazenda ou lote pré-existente na fixture.
    Isso o torna independente da ordem dos testes e do conteúdo anterior do DB.
    """
    suffix = next(_SEQUENCE)

    farm = client.post(
        "/api/v1/farms",
        headers=headers,
        json={
            "name": f"Fazenda Marco 5D {suffix}",
            "city": "Brasília",
            "state": "DF",
        },
    )
    assert farm.status_code == 200, farm.text
    farm_id = farm.json()["id"]

    lot = client.post(
        "/api/v1/livestock/lots",
        headers=headers,
        json={
            "farm_id": farm_id,
            "name": f"Lote Marco 5D {suffix}",
            "category": "Teste",
        },
    )
    assert lot.status_code == 201, lot.text
    lot_id = lot.json()["id"]

    animal = client.post(
        "/api/v1/livestock/animals",
        headers=headers,
        json={
            "farm_id": farm_id,
            "lot_id": lot_id,
            "tag": f"M5D-{suffix:03d}",
            "name": f"Animal Marco 5D {suffix}",
            "sex": "Fêmea",
            "breed": "Nelore",
            "category": "Matriz",
        },
    )
    assert animal.status_code == 201, animal.text
    return animal.json()["id"]


def test_photo_upload_list_download_patch_and_delete(
    client,
    tmp_path,
    monkeypatch,
):
    settings = get_settings()
    monkeypatch.setattr(
        settings,
        "atlas_attachment_dir",
        str(tmp_path),
    )

    headers = _login(client)
    animal_id = _create_animal(client, headers)

    upload = client.post(
        f"/api/v1/animal-media/{animal_id}",
        headers=headers,
        data={
            "kind": "photo",
            "metadata_json": (
                '{"date":"15/08/2026","title":"Foto 5D",'
                '"notes":"","isPrimary":true}'
            ),
        },
        files={
            "file": (
                "animal.jpg",
                b"fake-jpeg-bytes",
                "image/jpeg",
            )
        },
    )
    assert upload.status_code == 201, upload.text
    media = upload.json()
    assert media["kind"] == "photo"
    assert media["has_file"] is True
    assert media["size_bytes"] == len(b"fake-jpeg-bytes")

    listed = client.get(
        f"/api/v1/animal-media/{animal_id}?kind=photo",
        headers=headers,
    )
    assert listed.status_code == 200, listed.text
    assert any(
        item["id"] == media["id"]
        for item in listed.json()
    )

    downloaded = client.get(
        f"/api/v1/animal-media/{animal_id}/{media['id']}/content",
        headers=headers,
    )
    assert downloaded.status_code == 200, downloaded.text
    assert downloaded.content == b"fake-jpeg-bytes"

    patched = client.patch(
        f"/api/v1/animal-media/{animal_id}/{media['id']}",
        headers=headers,
        json={
            "metadata": {
                "date": "15/08/2026",
                "title": "Foto atualizada",
                "notes": "ok",
                "isPrimary": True,
            }
        },
    )
    assert patched.status_code == 200, patched.text
    assert patched.json()["metadata"]["title"] == "Foto atualizada"

    deleted = client.delete(
        f"/api/v1/animal-media/{animal_id}/{media['id']}",
        headers=headers,
    )
    assert deleted.status_code == 204, deleted.text

    with SessionLocal() as db:
        assert db.get(AnimalMedia, media["id"]) is None


def test_document_external_reference_without_file(client):
    headers = _login(client)
    animal_id = _create_animal(client, headers)

    response = client.post(
        f"/api/v1/animal-media/{animal_id}/reference",
        headers=headers,
        json={
            "kind": "document",
            "metadata": {
                "title": "Documento externo",
                "externalReference": (
                    "https://example.com/documento.pdf"
                ),
            },
        },
    )
    assert response.status_code == 201, response.text
    assert response.json()["has_file"] is False


def test_media_cannot_escape_current_company(client):
    headers = _login(client)

    response = client.get(
        "/api/v1/animal-media/animal_inexistente",
        headers=headers,
    )
    assert response.status_code == 404


def test_upload_rejects_unsupported_extension(
    client,
    tmp_path,
    monkeypatch,
):
    settings = get_settings()
    monkeypatch.setattr(
        settings,
        "atlas_attachment_dir",
        str(tmp_path),
    )

    headers = _login(client)
    animal_id = _create_animal(client, headers)

    response = client.post(
        f"/api/v1/animal-media/{animal_id}",
        headers=headers,
        data={
            "kind": "document",
            "metadata_json": "{}",
        },
        files={
            "file": (
                "malware.exe",
                b"MZ",
                "application/octet-stream",
            )
        },
    )
    assert response.status_code == 415, response.text
