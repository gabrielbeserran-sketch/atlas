from __future__ import annotations

from app.services.animal_media_storage import _supabase_headers_for_key


def test_legacy_service_role_uses_bearer_and_apikey() -> None:
    headers = _supabase_headers_for_key("legacy.jwt.value")
    assert headers["apikey"] == "legacy.jwt.value"
    assert headers["Authorization"] == "Bearer legacy.jwt.value"


def test_new_secret_key_is_not_sent_as_bearer_jwt() -> None:
    headers = _supabase_headers_for_key("sb_secret_example_value")
    assert headers["apikey"] == "sb_secret_example_value"
    assert "Authorization" not in headers
