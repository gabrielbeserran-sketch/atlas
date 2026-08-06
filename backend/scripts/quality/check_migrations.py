from __future__ import annotations

import ast
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VERSIONS = ROOT / "alembic" / "versions"


def literal_assignment(path: Path, name: str):
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for node in tree.body:
        if isinstance(node, (ast.Assign, ast.AnnAssign)):
            targets = node.targets if isinstance(node, ast.Assign) else [node.target]
            if any(isinstance(target, ast.Name) and target.id == name for target in targets):
                try:
                    return ast.literal_eval(node.value)
                except Exception:
                    return None
    return None


def main() -> int:
    revisions: dict[str, tuple[Path, object]] = {}
    errors: list[str] = []
    for path in sorted(VERSIONS.glob("*.py")):
        revision = literal_assignment(path, "revision")
        down_revision = literal_assignment(path, "down_revision")
        if not revision:
            errors.append(f"migration sem revision: {path.name}")
            continue
        if revision in revisions:
            errors.append(f"revision duplicada {revision}: {path.name} e {revisions[revision][0].name}")
        revisions[revision] = (path, down_revision)
    referenced: list[str] = []
    for path, down in revisions.values():
        values = down if isinstance(down, tuple) else (down,)
        for parent in values:
            if parent is None:
                continue
            referenced.append(parent)
            if parent not in revisions:
                errors.append(f"down_revision inexistente {parent} em {path.name}")
    heads = sorted(set(revisions) - set(referenced))
    roots = [revision for revision, (_, down) in revisions.items() if down is None]
    if len(heads) != 1:
        errors.append(f"esperado 1 head; encontrados {len(heads)}: {heads}")
    if len(roots) != 1:
        errors.append(f"esperada 1 raiz; encontradas {len(roots)}: {roots}")
    duplicate_parents = [key for key, count in Counter(referenced).items() if count > 1]
    if duplicate_parents:
        print(f"AVISO: migrations com ramificações: {duplicate_parents}")
    if errors:
        print("\n".join(f"ERRO: {item}" for item in errors))
        return 1
    print(f"Migrations aprovadas: {len(revisions)} revisões; head={heads[0]}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
