
def test_phase45_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/operations/timeline" in paths
    assert "/api/v1/operations/alerts" in paths
    assert "/api/v1/operations/tasks" in paths
    assert "/api/v1/operations/indicators" in paths
    assert "/api/v1/operations/reports/executive" in paths
