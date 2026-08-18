from __future__ import annotations

import ast
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RECONCILER = ROOT / "app" / "migrations" / "reconciliation.py"


def main() -> int:
    source = RECONCILER.read_text(encoding="utf-8")
    tree = ast.parse(source)

    forbidden_calls: list[str] = []

    for node in ast.walk(tree):
        if not isinstance(node, ast.FunctionDef):
            continue

        if node.name not in {
            "_apply_missing_column",
            "_sync_existing_table_columns",
        }:
            continue

        for child in ast.walk(node):
            if not isinstance(child, ast.Call):
                continue

            func = child.func
            if (
                isinstance(func, ast.Attribute)
                and isinstance(func.value, ast.Name)
                and func.value.id == "op"
            ):
                forbidden_calls.append(
                    f"{node.name}: op.{func.attr}(...)"
                )

    if forbidden_calls:
        print("ATLAS ALEMBIC RECONCILER AUDIT: FAIL")
        for item in forbidden_calls:
            print(f" - {item}")
        return 1

    required = (
        "_apply_missing_column(plan, original_add_column)",
        "class _SafeBatchOperations",
        "original_batch_alter_table",
        "def safe_alter_column",
    )
    missing = [item for item in required if item not in source]

    if missing:
        print("ATLAS ALEMBIC RECONCILER AUDIT: FAIL")
        for item in missing:
            print(f" - marcador ausente: {item}")
        return 1

    print("ATLAS ALEMBIC RECONCILER AUDIT: APROVADO")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
