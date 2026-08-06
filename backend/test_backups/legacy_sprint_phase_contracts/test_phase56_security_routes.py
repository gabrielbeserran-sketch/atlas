
def test_phase56_routes_are_documented(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]

    assert "/api/v1/security-enterprise/policies" in paths
    assert "/api/v1/security-enterprise/access-reviews" in paths
    assert "/api/v1/security-enterprise/privacy/consents" in paths
    assert "/api/v1/security-enterprise/privacy/requests" in paths
    assert "/api/v1/security-enterprise/risks" in paths
    assert "/api/v1/security-enterprise/continuity/plans" in paths
    assert "/api/v1/security-enterprise/continuity/exercises" in paths
    assert "/api/v1/security-enterprise/posture/snapshots" in paths
    assert "/api/v1/security-enterprise/dashboard" in paths
