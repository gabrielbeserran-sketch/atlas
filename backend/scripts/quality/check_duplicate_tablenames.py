from __future__ import annotations

import ast
from collections import defaultdict
from pathlib import Path

APP_DIR = Path(__file__).resolve().parents[2] / "app"


def main() -> int:
    found: dict[str, list[str]] = defaultdict(list)
    for path in sorted(APP_DIR.rglob("*.py")):
        try:
            tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except (SyntaxError, UnicodeDecodeError) as exc:
            print(f"ERRO ao analisar {path}: {exc}")
            return 2
        for node in ast.walk(tree):
            if not isinstance(node, ast.ClassDef):
                continue
            for stmt in node.body:
                if not isinstance(stmt, (ast.Assign, ast.AnnAssign)):
                    continue
                target_names: list[str] = []
                value = None
                if isinstance(stmt, ast.Assign):
                    target_names = [t.id for t in stmt.targets if isinstance(t, ast.Name)]
                    value = stmt.value
                else:
                    if isinstance(stmt.target, ast.Name):
                        target_names = [stmt.target.id]
                    value = stmt.value
                if "__tablename__" not in target_names or value is None:
                    continue
                if isinstance(value, ast.Constant) and isinstance(value.value, str):
                    rel = path.relative_to(APP_DIR.parent)
                    found[value.value].append(f"{rel}:{node.lineno}:{node.name}")

    duplicates = {name: refs for name, refs in found.items() if len(refs) > 1}
    if duplicates:
        print("TABELAS DUPLICADAS ENCONTRADAS:")
        for name, refs in sorted(duplicates.items()):
            print(f"- {name}")
            for ref in refs:
                print(f"  {ref}")
        return 1

    print(f"OK: {len(found)} nomes de tabela verificados; nenhuma duplicidade encontrada.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
