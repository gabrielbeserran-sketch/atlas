
def test_phase57_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]

    assert "/api/v1/release-engineering/pipelines" in paths
    assert "/api/v1/release-engineering/builds" in paths
    assert "/api/v1/release-engineering/environments" in paths
    assert "/api/v1/release-engineering/deployments" in paths
    assert "/api/v1/release-engineering/feature-flags" in paths
    assert "/api/v1/release-engineering/change-approvals" in paths
    assert "/api/v1/release-engineering/readiness-checks" in paths
    assert "/api/v1/release-engineering/readiness" in paths
    assert "/api/v1/release-engineering/metrics" in paths
    assert "/api/v1/release-engineering/dashboard" in paths
