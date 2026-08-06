
def test_phase55_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]

    assert "/api/v1/integrations/providers" in paths
    assert "/api/v1/integrations/connections" in paths
    assert "/api/v1/integrations/sync-jobs" in paths
    assert "/api/v1/integrations/webhooks" in paths
    assert "/api/v1/integrations/webhooks/events" in paths
    assert "/api/v1/integrations/webhooks/deliveries" in paths
    assert "/api/v1/integrations/partners/applications" in paths
    assert "/api/v1/integrations/usage/summary" in paths
    assert "/api/v1/integrations/dashboard" in paths
