from __future__ import annotations

import ast
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "app"
FORBIDDEN_FILENAMES = {"sprints_11_15.py", "sprints_16_20.py", "sprint_models.py", "sprints_21_25_models.py"}


def main() -> int:
    errors: list[str] = []
    for path in APP.rglob("*.py"):
        if path.name in FORBIDDEN_FILENAMES:
            errors.append(f"arquivo genérico proibido: {path.relative_to(ROOT)}")
        try:
            tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except SyntaxError as exc:
            errors.append(f"erro de sintaxe em {path.relative_to(ROOT)}: {exc}")
            continue
        for node in ast.walk(tree):
            if isinstance(node, ast.ImportFrom) and node.module == "app.models":
                for alias in node.names:
                    if alias.name == "Animal":
                        errors.append(f"import legado Animal em {path.relative_to(ROOT)}:{node.lineno}")
    if errors:
        print("\n".join(f"ERRO: {item}" for item in errors))
        return 1
    print("Arquitetura aprovada.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
