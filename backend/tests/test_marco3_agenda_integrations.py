from datetime import datetime, timedelta, timezone


def _login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@test.local", "password": "Test@123456"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _setup(client, headers):
    farm = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Fazenda Marco 3", "city": "Formosa", "state": "GO"},
    )
    assert farm.status_code == 200
    farm_id = farm.json()["id"]

    lot = client.post(
        "/api/v1/livestock/lots",
        headers=headers,
        json={"farm_id": farm_id, "name": "Matrizes Marco 3", "category": "Matrizes"},
    )
    assert lot.status_code == 201
    lot_id = lot.json()["id"]

    animal = client.post(
        "/api/v1/livestock/animals",
        headers=headers,
        json={
            "farm_id": farm_id,
            "lot_id": lot_id,
            "tag": "M3-001",
            "name": "Matriz Marco 3",
            "sex": "Fêmea",
            "breed": "Nelore",
            "category": "Matriz",
        },
    )
    assert animal.status_code == 201
    return farm_id, lot_id, animal.json()["id"]


def _tasks(client, headers, farm_id):
    items = []
    for status in ("open", "in_progress", "completed", "cancelled"):
        response = client.get(
            f"/api/v1/operations/tasks?farm_id={farm_id}&status={status}",
            headers=headers,
        )
        assert response.status_code == 200
        items.extend(response.json())
    return items


def test_marco3_reproduction_agenda_bidirectional_crud(client):
    headers = _login(client)
    farm_id, _lot_id, animal_id = _setup(client, headers)
    due_1 = datetime.now(timezone.utc) + timedelta(days=30)
    due_2 = due_1 + timedelta(days=7)
    due_3 = due_2 + timedelta(days=5)

    created = client.post(
        f"/api/v1/livestock/animals/{animal_id}/reproduction",
        headers=headers,
        json={
            "event_type": "IATF",
            "event_code": "iatf",
            "responsible": "Equipe Marco 3",
            "occurred_at": datetime.now(timezone.utc).isoformat(),
            "expected_date": due_1.isoformat(),
        },
    )
    assert created.status_code == 201
    event_id = created.json()["id"]

    tasks = [
        item
        for item in _tasks(client, headers, farm_id)
        if item["source_type"] == "reproduction_event" and item["source_id"] == event_id
    ]
    assert len(tasks) == 1
    task_id = tasks[0]["id"]

    updated = client.patch(
        f"/api/v1/livestock/animals/{animal_id}/reproduction/{event_id}",
        headers=headers,
        json={"expected_date": due_2.isoformat(), "notes": "Retorno ajustado"},
    )
    assert updated.status_code == 200
    tasks = [
        item
        for item in _tasks(client, headers, farm_id)
        if item["source_type"] == "reproduction_event" and item["source_id"] == event_id
    ]
    assert len(tasks) == 1
    assert tasks[0]["id"] == task_id
    assert tasks[0]["due_at"].startswith(due_2.date().isoformat())

    agenda_edit = client.patch(
        f"/api/v1/operations/tasks/{task_id}",
        headers=headers,
        json={"due_at": due_3.isoformat(), "source_type": "Reprodução"},
    )
    assert agenda_edit.status_code == 200
    assert agenda_edit.json()["source_type"] == "reproduction_event"

    history = client.get(
        f"/api/v1/livestock/animals/{animal_id}/reproduction", headers=headers
    )
    assert history.status_code == 200
    saved = next(item for item in history.json() if item["id"] == event_id)
    assert saved["expected_date"].startswith(due_3.date().isoformat())

    deleted = client.delete(
        f"/api/v1/livestock/animals/{animal_id}/reproduction/{event_id}",
        headers=headers,
    )
    assert deleted.status_code == 204
    assert not [
        item
        for item in _tasks(client, headers, farm_id)
        if item["source_type"] == "reproduction_event" and item["source_id"] == event_id
    ]


def test_marco3_health_inventory_finance_agenda_atomic_flow(client):
    headers = _login(client)
    farm_id, lot_id, animal_id = _setup(client, headers)
    product = client.post(
        "/api/v1/livestock/inventory/products/v2",
        headers=headers,
        json={
            "farm_id": farm_id,
            "sku": "M3-VACINA",
            "name": "Vacina Marco 3",
            "category": "Sanidade",
            "unit": "dose",
            "quantity": 20,
            "average_cost": 12.5,
        },
    )
    assert product.status_code == 201
    product_id = product.json()["id"]
    next_1 = datetime.now(timezone.utc) + timedelta(days=21)
    next_2 = next_1 + timedelta(days=7)
    next_3 = next_2 + timedelta(days=4)

    health = client.post(
        "/api/v1/livestock/health",
        headers=headers,
        json={
            "farm_id": farm_id,
            "animal_id": animal_id,
            "lot_id": lot_id,
            "event_type": "Vacinação",
            "product_name": "Vacina Marco 3",
            "dosage": "1 dose",
            "inventory_product_id": product_id,
            "inventory_quantity": 2,
            "next_date": next_1.isoformat(),
            "occurred_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    assert health.status_code == 201
    health_id = health.json()["id"]
    assert health.json()["treatment_cost"] == 25

    products = client.get(
        f"/api/v1/livestock/inventory/products?farm_id={farm_id}", headers=headers
    )
    assert products.status_code == 200
    saved_product = next(item for item in products.json() if item["id"] == product_id)
    assert saved_product["quantity"] == 18

    movements = client.get(
        f"/api/v1/livestock/inventory/products/{product_id}/movements", headers=headers
    )
    assert movements.status_code == 200
    consumption = [
        item
        for item in movements.json()
        if item["reference_type"] == "health_event" and item["reference_id"] == health_id
    ]
    assert len(consumption) == 1

    finance = client.get(f"/api/v1/livestock/finance/v2?farm_id={farm_id}", headers=headers)
    assert finance.status_code == 200
    linked_finance = [
        item
        for item in finance.json()
        if item["reference_type"] == "health_event" and item["reference_id"] == health_id
    ]
    assert len(linked_finance) == 1
    assert linked_finance[0]["amount"] == 25

    tasks = [
        item
        for item in _tasks(client, headers, farm_id)
        if item["source_type"] == "health_event" and item["source_id"] == health_id
    ]
    assert len(tasks) == 1
    task_id = tasks[0]["id"]

    update = client.patch(
        f"/api/v1/livestock/health/{health_id}",
        headers=headers,
        json={"next_date": next_2.isoformat(), "notes": "Reforço ajustado"},
    )
    assert update.status_code == 200
    tasks = [
        item
        for item in _tasks(client, headers, farm_id)
        if item["source_type"] == "health_event" and item["source_id"] == health_id
    ]
    assert len(tasks) == 1
    assert tasks[0]["id"] == task_id
    assert tasks[0]["due_at"].startswith(next_2.date().isoformat())

    agenda_update = client.patch(
        f"/api/v1/operations/tasks/{task_id}",
        headers=headers,
        json={"due_at": next_3.isoformat(), "source_type": "Sanidade"},
    )
    assert agenda_update.status_code == 200
    assert agenda_update.json()["source_type"] == "health_event"
    events = client.get(
        f"/api/v1/livestock/health?farm_id={farm_id}&animal_id={animal_id}",
        headers=headers,
    )
    assert events.status_code == 200
    saved_health = next(item for item in events.json() if item["id"] == health_id)
    assert saved_health["next_date"].startswith(next_3.date().isoformat())

    deleted = client.delete(f"/api/v1/livestock/health/{health_id}", headers=headers)
    assert deleted.status_code == 204

    products = client.get(
        f"/api/v1/livestock/inventory/products?farm_id={farm_id}", headers=headers
    )
    saved_product = next(item for item in products.json() if item["id"] == product_id)
    assert saved_product["quantity"] == 20

    movements = client.get(
        f"/api/v1/livestock/inventory/products/{product_id}/movements", headers=headers
    )
    reversals = [
        item
        for item in movements.json()
        if item["reference_type"] == "health_event_reversal"
        and item["reference_id"] == health_id
    ]
    assert len(reversals) == 1

    finance = client.get(f"/api/v1/livestock/finance/v2?farm_id={farm_id}", headers=headers)
    assert not [
        item
        for item in finance.json()
        if item["reference_type"] == "health_event" and item["reference_id"] == health_id
    ]
    assert not [
        item
        for item in _tasks(client, headers, farm_id)
        if item["source_type"] == "health_event" and item["source_id"] == health_id
    ]
