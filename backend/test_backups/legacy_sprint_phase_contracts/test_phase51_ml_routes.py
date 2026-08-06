
def test_phase51_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/ml/datasets" in paths
    assert "/api/v1/ml/features" in paths
    assert "/api/v1/ml/training-runs" in paths
    assert "/api/v1/ml/models" in paths
    assert "/api/v1/ml/deployments" in paths
    assert "/api/v1/ml/predictions" in paths
    assert "/api/v1/ml/dashboard" in paths
