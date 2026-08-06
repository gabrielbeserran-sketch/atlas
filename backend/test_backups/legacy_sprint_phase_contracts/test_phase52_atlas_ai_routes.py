
def test_phase52_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/atlas-ai/sessions" in paths
    assert "/api/v1/atlas-ai/chat" in paths
    assert "/api/v1/atlas-ai/memories" in paths
    assert "/api/v1/atlas-ai/plans" in paths
    assert "/api/v1/atlas-ai/recommendations" in paths
    assert "/api/v1/atlas-ai/knowledge/documents" in paths
    assert "/api/v1/atlas-ai/dashboard" in paths
