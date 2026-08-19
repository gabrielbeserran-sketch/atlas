from __future__ import annotations

import importlib
import sys


REQUIRED_MODULES = (
    "app.config",
    "app.database",
    "app.models",
    "app.migrations.reconciliation",
    "scripts.render_preflight",
    "scripts.render_post_migration_check",
    "scripts.render_schema_contract_check",
    "scripts.render_provision_admin_once",
)


def main() -> int:
    failures: list[str] = []

    for module_name in REQUIRED_MODULES:
        try:
            importlib.import_module(module_name)
            print(f"ATLAS IMPORT CONTRACT: OK {module_name}")
        except Exception as exc:  # pragma: no cover - executed in runtime
            failures.append(
                f"{module_name}: {type(exc).__name__}: {exc}"
            )

    if failures:
        print("ATLAS IMPORT CONTRACT: FAIL", file=sys.stderr)
        for failure in failures:
            print(f" - {failure}", file=sys.stderr)
        return 1

    print("ATLAS IMPORT CONTRACT: APROVADO")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
