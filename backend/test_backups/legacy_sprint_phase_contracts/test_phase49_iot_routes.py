
def test_phase49_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/iot/gateways" in paths
    assert "/api/v1/iot/devices" in paths
    assert "/api/v1/iot/telemetry/ingest" in paths
    assert "/api/v1/iot/dashboard" in paths
