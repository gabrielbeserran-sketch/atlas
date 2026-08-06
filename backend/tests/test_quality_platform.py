from fastapi.testclient import TestClient

from app.main import app


def test_openapi_has_unique_operation_ids():
    schema = app.openapi()
    operation_ids = []
    for path_item in schema["paths"].values():
        for method, operation in path_item.items():
            if method in {"get", "post", "put", "patch", "delete"}:
                operation_ids.append(operation["operationId"])
    assert len(operation_ids) == len(set(operation_ids))


def test_request_id_and_security_headers(client: TestClient):
    response = client.get("/")
    assert response.status_code == 200
    assert response.headers["x-request-id"]
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"


def test_quality_version(client: TestClient):
    response = client.get("/api/v1/quality/version")
    assert response.status_code == 200
    payload = response.json()
    assert payload["service"]
    assert payload["version"]


def test_quality_diagnostics(client: TestClient):
    response = client.get("/api/v1/quality/diagnostics")
    assert response.status_code == 200
    payload = response.json()
    assert payload["database"]["status"] == "ok"
    assert payload["schema"]["missing_in_database"] == []
