def test_phase48_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/realtime/publish" in paths
    assert "/api/v1/realtime/events" in paths
    assert "/api/v1/realtime/notifications" in paths
    assert "/api/v1/realtime/metrics" in paths
