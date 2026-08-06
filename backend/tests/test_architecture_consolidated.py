from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_no_active_legacy_sprint_or_phase_tests():
    names = [p.name for p in (ROOT / "tests").glob("test_*.py")]
    forbidden = ("test_sprints_", "test_phase", "test_phases", "test_blocks_", "test_advanced_blocks_")
    assert not [name for name in names if name.startswith(forbidden)]


def test_definitive_architecture_packages_exist():
    for relative in (
        "app/core", "app/models", "app/repositories", "app/services",
        "app/routers", "app/schemas", "app/workers",
    ):
        assert (ROOT / relative).is_dir()


def test_main_has_no_legacy_sprint_router_imports():
    text = (ROOT / "app/main.py").read_text(encoding="utf-8")
    assert "sprints_11_15" not in text
    assert "sprints_16_20" not in text
    assert "sprints_21_25" not in text


def test_no_duplicate_sqlalchemy_table_names():
    import ast
    found = {}
    duplicates = {}
    for path in (ROOT / "app").rglob("*.py"):
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        for node in ast.walk(tree):
            if not isinstance(node, ast.ClassDef):
                continue
            for stmt in node.body:
                if not isinstance(stmt, (ast.Assign, ast.AnnAssign)):
                    continue
                target = stmt.targets[0] if isinstance(stmt, ast.Assign) else stmt.target
                value = stmt.value
                if isinstance(target, ast.Name) and target.id == "__tablename__" and isinstance(value, ast.Constant) and isinstance(value.value, str):
                    previous = found.get(value.value)
                    current = f"{path.relative_to(ROOT)}:{node.name}"
                    if previous:
                        duplicates.setdefault(value.value, [previous]).append(current)
                    else:
                        found[value.value] = current
    assert not duplicates, duplicates
