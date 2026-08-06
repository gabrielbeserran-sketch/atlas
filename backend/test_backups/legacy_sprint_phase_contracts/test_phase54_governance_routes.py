
def test_phase54_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]

    assert "/api/v1/governance/policies" in paths
    assert "/api/v1/governance/catalog/assets" in paths
    assert "/api/v1/governance/quality/rules" in paths
    assert "/api/v1/governance/quality/runs" in paths
    assert "/api/v1/governance/compliance/controls" in paths
    assert "/api/v1/governance/compliance/score" in paths
    assert "/api/v1/governance/health/summary" in paths
    assert "/api/v1/governance/incidents" in paths
    assert "/api/v1/governance/dashboard" in paths
