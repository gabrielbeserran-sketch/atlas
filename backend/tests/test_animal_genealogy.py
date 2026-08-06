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


def _animal(client, headers, farm_id, **data):
    payload = {
        "farm_id": farm_id,
        "group_name": "Genealogia",
        "tag": data.pop("tag"),
        "name": data.pop("name", ""),
        "sex": data.pop("sex", "Fêmea"),
        "breed": "Nelore",
        **data,
    }
    response = client.post(
        "/api/v1/animals",
        json=payload,
        headers=headers,
    )
    assert response.status_code == 200
    return response.json()


def test_genealogy_returns_family_and_descendants(client):
    auth = _login(client)
    headers = _headers(auth["access_token"])

    farm = client.post(
        "/api/v1/farms",
        json={
            "name": "Fazenda Genealogia",
            "city": "Brasília",
            "state": "DF",
        },
        headers=headers,
    )
    assert farm.status_code == 200
    farm_id = farm.json()["id"]

    paternal_grandfather = _animal(
        client,
        headers,
        farm_id,
        tag="PGF-001",
        name="Avô Paterno",
        sex="Macho",
    )
    paternal_grandmother = _animal(
        client,
        headers,
        farm_id,
        tag="PGM-001",
        name="Avó Paterna",
    )
    maternal_grandfather = _animal(
        client,
        headers,
        farm_id,
        tag="MGF-001",
        name="Avô Materno",
        sex="Macho",
    )
    maternal_grandmother = _animal(
        client,
        headers,
        farm_id,
        tag="MGM-001",
        name="Avó Materna",
    )

    father = _animal(
        client,
        headers,
        farm_id,
        tag="F-001",
        name="Pai",
        sex="Macho",
        father_tag=paternal_grandfather["tag"],
        mother_tag=paternal_grandmother["tag"],
    )
    mother = _animal(
        client,
        headers,
        farm_id,
        tag="M-001",
        name="Mãe",
        father_tag=maternal_grandfather["tag"],
        mother_tag=maternal_grandmother["tag"],
    )

    focal = _animal(
        client,
        headers,
        farm_id,
        tag="A-001",
        name="Animal Central",
        father_tag=father["tag"],
        mother_tag=mother["tag"],
    )
    _animal(
        client,
        headers,
        farm_id,
        tag="S-001",
        name="Irmã",
        father_tag=father["tag"],
        mother_tag=mother["tag"],
    )
    _animal(
        client,
        headers,
        farm_id,
        tag="HS-001",
        name="Meia-irmã",
        father_tag=father["tag"],
        mother_tag="OUTRA-MAE",
    )
    child = _animal(
        client,
        headers,
        farm_id,
        tag="C-001",
        name="Filho",
        mother_tag=focal["tag"],
    )
    _animal(
        client,
        headers,
        farm_id,
        tag="GC-001",
        name="Neto",
        mother_tag=child["tag"],
    )

    response = client.get(
        f"/api/v1/animals/{focal['id']}/genealogy",
        headers=headers,
    )

    assert response.status_code == 200
    genealogy = response.json()

    assert genealogy["animal"]["tag"] == "A-001"
    assert genealogy["father"]["tag"] == "F-001"
    assert genealogy["mother"]["tag"] == "M-001"
    assert genealogy["paternal_grandfather"]["tag"] == "PGF-001"
    assert genealogy["paternal_grandmother"]["tag"] == "PGM-001"
    assert genealogy["maternal_grandfather"]["tag"] == "MGF-001"
    assert genealogy["maternal_grandmother"]["tag"] == "MGM-001"
    assert [item["tag"] for item in genealogy["siblings"]] == [
        "S-001"
    ]
    assert [item["tag"] for item in genealogy["half_siblings"]] == [
        "HS-001"
    ]
    assert [item["tag"] for item in genealogy["children"]] == [
        "C-001"
    ]
    assert {
        item["tag"] for item in genealogy["descendants"]
    } == {"C-001", "GC-001"}
    assert genealogy["unresolved_tags"] == []
