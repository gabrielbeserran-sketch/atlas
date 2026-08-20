from __future__ import annotations

from datetime import datetime, timedelta, timezone


def _login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@test.local", "password": "Test@123456"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _farm(client, headers, name="Fazenda V8"):
    response = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": name, "city": "Brasília", "state": "DF"},
    )
    assert response.status_code == 200
    return response.json()["id"]


def _lot(client, headers, farm_id, name):
    response = client.post(
        "/api/v1/livestock/lots",
        headers=headers,
        json={"farm_id": farm_id, "name": name, "category": "Vacas"},
    )
    assert response.status_code == 201
    return response.json()["id"]


def _animal(client, headers, farm_id, lot_id, tag="V8-001"):
    response = client.post(
        "/api/v1/livestock/animals",
        headers=headers,
        json={
            "farm_id": farm_id,
            "lot_id": lot_id,
            "tag": tag,
            "name": "Matriz V8",
            "sex": "Fêmea",
            "breed": "Nelore",
            "category": "Matriz",
            "status": "active",
            "current_weight": 400,
            "body_condition_score": 3,
        },
    )
    assert response.status_code == 201
    return response.json()["id"]


def _product(client, headers, farm_id, quantity=100):
    response = client.post(
        "/api/v1/livestock/inventory/products/v2",
        headers=headers,
        json={
            "farm_id": farm_id,
            "sku": "V8-PROD-001",
            "name": "Produto V8",
            "category": "Sanidade",
            "unit": "mL",
            "quantity": quantity,
            "minimum_quantity": 10,
            "average_cost": 2,
        },
    )
    assert response.status_code == 201
    return response.json()


def _inventory(client, headers, farm_id):
    response = client.get(
        f"/api/v1/livestock/inventory/products?farm_id={farm_id}",
        headers=headers,
    )
    assert response.status_code == 200
    return response.json()


def _finance(client, headers, farm_id):
    response = client.get(
        f"/api/v1/livestock/finance/v2?farm_id={farm_id}", headers=headers
    )
    assert response.status_code == 200
    return response.json()


def test_v8_weight_patch_delete_refreshes_animal_state(client):
    headers = _login(client)
    farm_id = _farm(client, headers)
    lot_id = _lot(client, headers, farm_id, "Lote V8 A")
    animal_id = _animal(client, headers, farm_id, lot_id)
    now = datetime.now(timezone.utc)

    first = client.post(
        f"/api/v1/livestock/animals/{animal_id}/weights",
        headers=headers,
        json={"weight": 420, "body_condition_score": 3, "measured_at": (now-timedelta(days=30)).isoformat()},
    )
    assert first.status_code == 201
    second = client.post(
        f"/api/v1/livestock/animals/{animal_id}/weights",
        headers=headers,
        json={"weight": 450, "body_condition_score": 3.5, "measured_at": now.isoformat()},
    )
    assert second.status_code == 201

    animal = client.get(f"/api/v1/livestock/animals/{animal_id}", headers=headers)
    assert animal.status_code == 200
    assert animal.json()["current_weight"] == 450

    patched = client.patch(
        f"/api/v1/livestock/animals/{animal_id}/weights/{second.json()['id']}",
        headers=headers,
        json={"weight": 460},
    )
    assert patched.status_code == 200
    assert client.get(f"/api/v1/livestock/animals/{animal_id}", headers=headers).json()["current_weight"] == 460

    deleted = client.delete(
        f"/api/v1/livestock/animals/{animal_id}/weights/{second.json()['id']}",
        headers=headers,
    )
    assert deleted.status_code == 204
    refreshed = client.get(f"/api/v1/livestock/animals/{animal_id}", headers=headers).json()
    assert refreshed["current_weight"] == 420
    assert refreshed["body_condition_score"] == 3


def test_v8_animal_lot_patch_generates_audited_movement(client):
    headers = _login(client)
    farm_id = _farm(client, headers)
    lot_a = _lot(client, headers, farm_id, "Lote V8 A")
    lot_b = _lot(client, headers, farm_id, "Lote V8 B")
    animal_id = _animal(client, headers, farm_id, lot_a)

    patched = client.patch(
        f"/api/v1/livestock/animals/{animal_id}",
        headers=headers,
        json={"lot_id": lot_b},
    )
    assert patched.status_code == 200
    assert patched.json()["lot_id"] == lot_b

    history = client.get(
        f"/api/v1/livestock/animals/{animal_id}/movements", headers=headers
    )
    assert history.status_code == 200
    movement = history.json()[0]
    assert movement["movement_type"] == "lot_change"
    assert movement["from_lot_id"] == lot_a
    assert movement["to_lot_id"] == lot_b
    assert movement["reason"] == "Alteração cadastral de lote"


def test_v8_health_patch_and_delete_reconcile_stock_finance_and_task(client):
    headers = _login(client)
    farm_id = _farm(client, headers)
    lot_id = _lot(client, headers, farm_id, "Lote V8 Sanidade")
    animal_id = _animal(client, headers, farm_id, lot_id)
    product = _product(client, headers, farm_id, 100)
    next_date = datetime.now(timezone.utc) + timedelta(days=30)

    created = client.post(
        "/api/v1/livestock/health",
        headers=headers,
        json={
            "farm_id": farm_id,
            "animal_id": animal_id,
            "event_type": "Vacinação V8",
            "inventory_product_id": product["id"],
            "inventory_quantity": 10,
            "treatment_cost": 0,
            "next_date": next_date.isoformat(),
        },
    )
    assert created.status_code == 201
    event_id = created.json()["id"]
    assert next(x for x in _inventory(client, headers, farm_id) if x["id"] == product["id"])["quantity"] == 90
    linked = [x for x in _finance(client, headers, farm_id) if x["reference_type"] == "health_event" and x["reference_id"] == event_id]
    assert len(linked) == 1 and linked[0]["amount"] == 20

    patched = client.patch(
        f"/api/v1/livestock/health/{event_id}",
        headers=headers,
        json={"inventory_quantity": 5},
    )
    assert patched.status_code == 200
    assert next(x for x in _inventory(client, headers, farm_id) if x["id"] == product["id"])["quantity"] == 95
    linked = [x for x in _finance(client, headers, farm_id) if x["reference_type"] == "health_event" and x["reference_id"] == event_id]
    assert len(linked) == 1 and linked[0]["amount"] == 10

    tasks = client.get(
        f"/api/v1/operations/tasks?farm_id={farm_id}&status=open", headers=headers
    )
    assert tasks.status_code == 200
    assert any(x["source_type"] == "health_event" and x["source_id"] == event_id for x in tasks.json())

    deleted = client.delete(f"/api/v1/livestock/health/{event_id}", headers=headers)
    assert deleted.status_code == 204
    assert next(x for x in _inventory(client, headers, farm_id) if x["id"] == product["id"])["quantity"] == 100
    assert not [x for x in _finance(client, headers, farm_id) if x["reference_type"] == "health_event" and x["reference_id"] == event_id]


def test_v8_nutrition_delete_reverses_stock_and_finance(client):
    headers = _login(client)
    farm_id = _farm(client, headers)
    lot_id = _lot(client, headers, farm_id, "Lote V8 Nutrição")
    _animal(client, headers, farm_id, lot_id)
    product = _product(client, headers, farm_id, 100)

    event = client.post(
        f"/api/v1/livestock/nutrition/lots/{lot_id}/consumption",
        headers=headers,
        json={
            "product_id": product["id"],
            "diet_name": "Dieta V8",
            "amount_per_animal": 10,
            "animal_count": 1,
            "total_quantity": 10,
            "planned_quantity": 10,
            "observed_daily_gain_kg": 0.5,
        },
    )
    assert event.status_code == 201
    event_id = event.json()["id"]
    assert next(x for x in _inventory(client, headers, farm_id) if x["id"] == product["id"])["quantity"] == 90
    linked = [x for x in _finance(client, headers, farm_id) if x["reference_type"] == "nutrition_event" and x["reference_id"] == event_id]
    assert len(linked) == 1 and linked[0]["amount"] == 20

    assert client.delete(f"/api/v1/livestock/nutrition/events/{event_id}", headers=headers).status_code == 204
    assert next(x for x in _inventory(client, headers, farm_id) if x["id"] == product["id"])["quantity"] == 100
    assert not [x for x in _finance(client, headers, farm_id) if x["reference_type"] == "nutrition_event" and x["reference_id"] == event_id]


def test_v8_integrated_finance_and_inventory_invariants(client):
    headers = _login(client)
    farm_id = _farm(client, headers)
    lot_id = _lot(client, headers, farm_id, "Lote V8 Proteções")
    animal_id = _animal(client, headers, farm_id, lot_id)
    product = _product(client, headers, farm_id, 25)

    # Saldo não pode ser adulterado por PATCH direto.
    bad_stock = client.patch(
        f"/api/v1/livestock/inventory/products/{product['id']}/v2",
        headers=headers,
        json={**product, "quantity": 999},
    )
    assert bad_stock.status_code == 409

    health = client.post(
        "/api/v1/livestock/health",
        headers=headers,
        json={
            "farm_id": farm_id,
            "animal_id": animal_id,
            "event_type": "Tratamento V8",
            "treatment_cost": 50,
        },
    )
    assert health.status_code == 201
    entry = next(
        x for x in _finance(client, headers, farm_id)
        if x["reference_type"] == "health_event" and x["reference_id"] == health.json()["id"]
    )

    blocked_patch = client.patch(
        f"/api/v1/livestock/finance/v2/{entry['id']}",
        headers=headers,
        json={**{k: entry[k] for k in (
            "farm_id","animal_id","lot_id","entry_type","category","cost_center","description","amount","status",
            "competence_date","due_date","paid_at","payment_method","counterparty","document_number","recurring",
            "recurrence_rule","reference_type","reference_id","notes"
        )}},
    )
    assert blocked_patch.status_code == 409
    assert client.delete(f"/api/v1/livestock/finance/v2/{entry['id']}", headers=headers).status_code == 409


def test_v8_agenda_task_roundtrip_persists_status(client):
    headers = _login(client)
    farm_id = _farm(client, headers)
    due = datetime.now(timezone.utc) + timedelta(days=2)
    created = client.post(
        "/api/v1/operations/tasks",
        headers=headers,
        json={
            "farm_id": farm_id,
            "source_type": "v8_test",
            "source_id": "v8-agenda",
            "title": "Compromisso V8",
            "description": "Teste transacional",
            "priority": "medium",
            "due_at": due.isoformat(),
        },
    )
    assert created.status_code == 201
    task_id = created.json()["id"]

    changed_due = due + timedelta(days=1)
    patched = client.patch(
        f"/api/v1/operations/tasks/{task_id}",
        headers=headers,
        json={"title": "Compromisso V8 editado", "due_at": changed_due.isoformat()},
    )
    assert patched.status_code == 200
    assert patched.json()["title"] == "Compromisso V8 editado"

    cancelled = client.patch(
        f"/api/v1/operations/tasks/{task_id}",
        headers=headers,
        json={"status": "cancelled"},
    )
    assert cancelled.status_code == 200
    assert cancelled.json()["status"] == "cancelled"

    listed = client.get(
        f"/api/v1/operations/tasks?farm_id={farm_id}&status=cancelled",
        headers=headers,
    )
    assert listed.status_code == 200
    assert any(x["id"] == task_id for x in listed.json())
