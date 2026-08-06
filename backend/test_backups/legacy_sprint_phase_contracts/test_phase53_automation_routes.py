
def test_phase53_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/automation/rules" in paths
    assert "/api/v1/automation/workflows" in paths
    assert "/api/v1/automation/calendar" in paths
    assert "/api/v1/automation/objectives" in paths
    assert "/api/v1/automation/dashboard" in paths
