from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_render_startup_executes_scripts_as_modules() -> None:
    text = (BACKEND_ROOT / "scripts" / "render_start.sh").read_text(
        encoding="utf-8"
    )

    assert "cd /app" in text
    assert "python -m scripts.render_preflight" in text
    assert "python -m scripts.render_post_migration_check" in text
    assert "python /app/scripts/render_preflight.py" not in text
    assert "python /app/scripts/render_post_migration_check.py" not in text


def test_render_startup_uses_python_module_for_uvicorn() -> None:
    text = (BACKEND_ROOT / "scripts" / "render_start.sh").read_text(
        encoding="utf-8"
    )

    assert "exec python -m uvicorn app.main:app" in text
    assert '--port "$PORT"' in text


def test_scripts_package_is_explicit() -> None:
    assert (BACKEND_ROOT / "scripts" / "__init__.py").is_file()
