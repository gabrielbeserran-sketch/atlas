
def test_livestock_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/livestock/lots" in paths
    assert "/api/v1/livestock/animals" in paths
    assert "/api/v1/livestock/health" in paths
    assert "/api/v1/livestock/inventory/products" in paths
    assert "/api/v1/livestock/finance" in paths
    assert "/api/v1/livestock/nutrition" in paths
