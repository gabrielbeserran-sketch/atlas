
def test_phase47_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/ai/conversations" in paths
    assert "/api/v1/ai/analyze/{area}" in paths
    assert "/api/v1/ai/recommendations" in paths
    assert "/api/v1/ai/executive" in paths
