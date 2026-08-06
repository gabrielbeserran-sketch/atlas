
def test_phase46_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/analytics/warehouse/refresh" in paths
    assert "/api/v1/analytics/facts" in paths
    assert "/api/v1/analytics/kpis" in paths
    assert "/api/v1/analytics/goals" in paths
    assert "/api/v1/analytics/dashboard" in paths
