from __future__ import annotations

import ast
from pathlib import Path


def test_database_connection_script_bootstraps_backend_before_app_import() -> None:
    backend_root = Path(__file__).resolve().parents[1]
    script = backend_root / "scripts" / "check_local_database_connection.py"
    tree = ast.parse(script.read_text(encoding="utf-8"))

    app_import_line = None
    sys_path_insert_line = None

    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom) and node.module == "app.config":
            app_import_line = node.lineno

        if isinstance(node, ast.Call):
            func = node.func
            if (
                isinstance(func, ast.Attribute)
                and func.attr == "insert"
                and isinstance(func.value, ast.Attribute)
                and func.value.attr == "path"
                and isinstance(func.value.value, ast.Name)
                and func.value.value.id == "sys"
            ):
                sys_path_insert_line = node.lineno

    assert app_import_line is not None
    assert sys_path_insert_line is not None
    assert sys_path_insert_line < app_import_line
