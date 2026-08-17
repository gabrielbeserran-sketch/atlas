def _login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@test.local", "password": "Test@123456"},
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _farm_and_lot(client, headers):
    farm = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Fazenda Marco 2", "city": "Formosa", "state": "GO"},
    )
    assert farm.status_code == 200
    farm_id = farm.json()["id"]
    lot = client.post(
        "/api/v1/livestock/lots",
        headers=headers,
        json={"farm_id": farm_id, "name": "Lote Marco 2", "category": "Vacas"},
    )
    assert lot.status_code == 201
    return farm_id, lot.json()["id"]


def test_marco2_paddock_inventory_nutrition_finance_crud(client):
    headers = _login(client)
    farm_id, lot_id = _farm_and_lot(client, headers)

    # Piquetes: create -> patch -> read -> delete.
    paddock = client.post(
        "/api/v1/livestock/paddocks",
        headers=headers,
        json={"farm_id": farm_id, "name": "Piquete 01", "area": 18.5, "status": "Em pastejo", "animals": 12},
    )
    assert paddock.status_code == 201
    paddock_id = paddock.json()["id"]
    updated = client.patch(
        f"/api/v1/livestock/paddocks/{paddock_id}",
        headers=headers,
        json={"area": 20.0, "status": "Descanso", "animals": 0},
    )
    assert updated.status_code == 200
    assert updated.json()["area"] == 20.0
    listed = client.get(f"/api/v1/livestock/paddocks?farm_id={farm_id}", headers=headers)
    assert listed.status_code == 200
    assert any(item["id"] == paddock_id for item in listed.json())

    # Estoque: create -> patch -> movement -> read.
    product = client.post(
        "/api/v1/livestock/inventory/products/v2",
        headers=headers,
        json={"farm_id": farm_id, "sku": "MARCO2-RACAO", "name": "Ração Marco 2", "category": "Nutrição", "unit": "kg", "quantity": 100, "minimum_quantity": 10, "average_cost": 2.5},
    )
    assert product.status_code == 201
    product_id = product.json()["id"]
    product_update = client.patch(
        f"/api/v1/livestock/inventory/products/{product_id}/v2",
        headers=headers,
        json={"farm_id": farm_id, "sku": "MARCO2-RACAO", "name": "Ração Marco 2", "category": "Nutrição", "unit": "kg", "quantity": 100, "minimum_quantity": 15, "average_cost": 2.5},
    )
    assert product_update.status_code == 200
    movement = client.post(
        f"/api/v1/livestock/inventory/products/{product_id}/movements/v2",
        headers=headers,
        json={"movement_type": "nutrition_consumption", "quantity": 20, "unit_cost": 2.5, "reference_type": "nutrition_plan", "reference_id": "qa-plan"},
    )
    assert movement.status_code == 201
    assert movement.json()["balance_after"] == 80

    # Nutrição: fields that link inventory state must survive reload/update.
    plan = client.post(
        "/api/v1/livestock/nutrition/plans",
        headers=headers,
        json={
            "farm_id": farm_id,
            "lot_id": lot_id,
            "name": "Dieta Marco 2",
            "category": "Engorda",
            "daily_amount_per_animal_kg": 5,
            "animal_count": 12,
            "cost_per_kg": 2.5,
            "ingredients_json": [{"name": "Ração Marco 2", "type": "Concentrado", "inclusionKg": 5, "costPerKg": 2.5}],
            "stock_integration_enabled": True,
            "inventory_deducted": True,
            "inventory_deduction_cost": 50,
        },
    )
    assert plan.status_code == 201
    plan_id = plan.json()["id"]
    assert plan.json()["stock_integration_enabled"] is True
    assert plan.json()["inventory_deducted"] is True
    plans = client.get(f"/api/v1/livestock/nutrition/plans?farm_id={farm_id}", headers=headers)
    assert plans.status_code == 200
    reloaded_plan = next(item for item in plans.json() if item["id"] == plan_id)
    assert reloaded_plan["ingredients_json"][0]["name"] == "Ração Marco 2"
    assert reloaded_plan["inventory_deduction_cost"] == 50

    # Financeiro: lot_id is a first-class relationship and survives patch/reload.
    finance = client.post(
        "/api/v1/livestock/finance/v2",
        headers=headers,
        json={"farm_id": farm_id, "lot_id": lot_id, "entry_type": "expense", "category": "Nutrição", "cost_center": "Nutrição", "description": "Compra Marco 2", "amount": 250, "status": "paid", "reference_type": "inventory_movement", "reference_id": movement.json()["id"]},
    )
    assert finance.status_code == 201
    entry_id = finance.json()["id"]
    assert finance.json()["lot_id"] == lot_id
    finance_update = client.patch(
        f"/api/v1/livestock/finance/v2/{entry_id}",
        headers=headers,
        json={"farm_id": farm_id, "lot_id": lot_id, "entry_type": "expense", "category": "Nutrição", "cost_center": "Nutrição", "description": "Compra Marco 2 ajustada", "amount": 275, "status": "paid", "reference_type": "inventory_movement", "reference_id": movement.json()["id"]},
    )
    assert finance_update.status_code == 200
    entries = client.get(f"/api/v1/livestock/finance/v2?farm_id={farm_id}", headers=headers)
    assert entries.status_code == 200
    reloaded_entry = next(item for item in entries.json() if item["id"] == entry_id)
    assert reloaded_entry["amount"] == 275
    assert reloaded_entry["lot_id"] == lot_id

    assert client.delete(f"/api/v1/livestock/finance/v2/{entry_id}", headers=headers).status_code == 204
    assert client.delete(f"/api/v1/livestock/nutrition/plans/{plan_id}", headers=headers).status_code == 204
    assert client.delete(f"/api/v1/livestock/inventory/products/{product_id}/v2", headers=headers).status_code == 204
    assert client.delete(f"/api/v1/livestock/paddocks/{paddock_id}", headers=headers).status_code == 204
