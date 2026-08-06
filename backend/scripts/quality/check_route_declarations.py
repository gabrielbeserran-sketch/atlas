from __future__ import annotations

import ast
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROUTERS = ROOT / "app" / "routers"
HTTP_METHODS = {"get", "post", "put", "patch", "delete", "options", "head"}


def decorator_route(node: ast.FunctionDef | ast.AsyncFunctionDef):
    for decorator in node.decorator_list:
        if not isinstance(decorator, ast.Call) or not isinstance(decorator.func, ast.Attribute):
            continue
        method = decorator.func.attr.lower()
        if method not in HTTP_METHODS or not decorator.args:
            continue
        path_arg = decorator.args[0]
        if isinstance(path_arg, ast.Constant) and isinstance(path_arg.value, str):
            yield method.upper(), path_arg.value


def main() -> int:
    declarations: dict[tuple[str, str, str], list[str]] = defaultdict(list)
    errors: list[str] = []

    for file in sorted(ROUTERS.glob("*.py")):
        try:
            tree = ast.parse(file.read_text(encoding="utf-8"), filename=str(file))
        except SyntaxError as exc:
            errors.append(f"{file.name}: erro de sintaxe: {exc}")
            continue
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                for method, path in decorator_route(node):
                    declarations[(file.name, method, path)].append(f"{node.name}:L{node.lineno}")

    duplicates = {
        key: locations
        for key, locations in declarations.items()
        if len(locations) > 1
    }
    if duplicates:
        print("Falha: rotas declaradas mais de uma vez no mesmo router:")
        for (file_name, method, path), locations in sorted(duplicates.items()):
            print(f"- {file_name} {method} {path}: {', '.join(locations)}")
        return 1
    if errors:
        print("Falha na leitura dos routers:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"OK: {len(declarations)} declarações de rota verificadas; nenhuma duplicidade local.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
