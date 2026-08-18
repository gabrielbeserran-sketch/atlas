from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
RECONCILER = (
    BACKEND_ROOT
    / "app"
    / "migrations"
    / "reconciliation.py"
)


def _text() -> str:
    return RECONCILER.read_text(encoding="utf-8")


def test_postgres_relation_namespace_is_checked_globally() -> None:
    text = _text()
    assert "def _relation_owner" in text
    assert "pg_catalog.pg_class" in text
    assert "pg_catalog.pg_namespace" in text


def test_index_owner_table_is_resolved_through_pg_index() -> None:
    text = _text()
    assert "def _index_table_for_name" in text
    assert "pg_catalog.pg_index" in text


def test_cross_table_index_collision_gets_deterministic_alternate_name() -> None:
    text = _text()
    assert "def _collision_safe_index_name" in text
    assert "colisao global de nome de indice detectada" in text
    assert "target_table=" in text
    assert "alternate=" in text


def test_top_level_and_batch_create_index_use_global_resolver() -> None:
    text = _text()
    assert text.count("_resolve_index_name(") >= 4
    assert "return original_create_index(" in text
    assert "return self._ops.create_index(" in text


def test_postgres_identifier_length_is_guarded() -> None:
    text = _text()
    assert "def _postgres_identifier" in text
    assert "len(encoded) <= 63" in text
