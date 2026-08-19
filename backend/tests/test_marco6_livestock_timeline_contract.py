from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
ROUTER = BACKEND_ROOT / "app" / "routers" / "livestock.py"


def test_livestock_timeline_endpoint_exists() -> None:
    text = ROUTER.read_text(encoding="utf-8")
    assert '"/animals/{animal_id}/timeline"' in text
    assert "def livestock_animal_timeline" in text


def test_livestock_timeline_uses_real_livestock_models() -> None:
    text = ROUTER.read_text(encoding="utf-8")
    assert "AnimalMovement" in text
    assert "WeightRecord" in text
    assert "ReproductionEvent" in text
    assert "HealthEvent" in text


def test_timeline_is_company_and_tenant_scoped() -> None:
    text = ROUTER.read_text(encoding="utf-8")
    assert "principal.company.id" in text
    assert "principal.company.tenant_id" in text
