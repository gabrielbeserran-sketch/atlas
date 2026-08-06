from __future__ import annotations

import ast
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"


def python_files() -> list[Path]:
    return sorted(APP.rglob("*.py"))


def inspect_file(path: Path) -> dict:
    source = path.read_text(encoding="utf-8")
    tree = ast.parse(source)
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "lines": len(source.splitlines()),
        "classes": [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)],
        "functions": [node.name for node in ast.walk(tree) if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))],
        "imports": sorted({
            alias.name.split(".")[0]
            for node in ast.walk(tree)
            if isinstance(node, ast.Import)
            for alias in node.names
        } | {
            (node.module or "").split(".")[0]
            for node in ast.walk(tree)
            if isinstance(node, ast.ImportFrom) and node.module
        }),
    }


def main() -> None:
    files = [inspect_file(path) for path in python_files()]
    findings = []
    env = ROOT / ".env"
    if env.exists():
        findings.append({"severity": "critical", "message": ".env real presente no pacote; remover antes da distribuição."})
    main_source = (APP / "main.py").read_text(encoding="utf-8")
    if "Base.metadata.create_all" in main_source:
        findings.append({"severity": "high", "message": "create_all ainda é usado no startup; migrações Alembic devem ser a fonte de verdade."})
    settings_source = (APP / "config.py").read_text(encoding="utf-8")
    if "development-only-secret" in settings_source:
        findings.append({"severity": "high", "message": "Existe segredo padrão de desenvolvimento; produção deve rejeitar segredos fracos."})
    report = {
        "backend": "FastAPI + SQLAlchemy",
        "python_files": len(files),
        "routers": len(list((APP / "routers").glob("*.py"))) - 1,
        "tests": len(list((ROOT / "tests").glob("test_*.py"))),
        "files": files,
        "findings": findings,
    }
    output = ROOT / "docs" / "BACKEND_AUDIT.json"
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({k: report[k] for k in ("backend", "python_files", "routers", "tests", "findings")}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
