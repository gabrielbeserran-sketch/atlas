
def test_phase50_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/commercial/customers" in paths
    assert "/api/v1/commercial/opportunities" in paths
    assert "/api/v1/commercial/proposals" in paths
    assert "/api/v1/commercial/contracts" in paths
    assert "/api/v1/commercial/plans" in paths
    assert "/api/v1/commercial/subscriptions" in paths
    assert "/api/v1/commercial/invoices" in paths
    assert "/api/v1/commercial/dashboard" in paths
