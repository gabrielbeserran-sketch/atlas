from pathlib import Path

def test_domain_router_names_replace_generic_sprint_names():
    base=Path(__file__).resolve().parents[1]/"app"/"routers"
    expected=["precision_livestock.py","reproduction_advanced.py","health_intelligence.py","nutrition_intelligence.py","farm_operations.py","atlas_brain.py","atlas_vision.py","iot_platform.py","cloud_operations.py","web_platform.py","billing.py","public_api.py","enterprise_analytics.py","machine_learning_registry.py","enterprise_release.py"]
    for name in expected: assert (base/name).exists(), name

def test_main_does_not_import_generic_sprint_routers():
    text=(Path(__file__).resolve().parents[1]/"app"/"main.py").read_text()
    assert "sprints_11_15" not in text
    assert "sprints_16_20" not in text
    for router in ["precision_livestock","reproduction_advanced","health_intelligence","nutrition_intelligence","farm_operations"]: assert router in text

def test_migration_chain():
    text=(Path(__file__).resolve().parents[1]/"alembic"/"versions"/"20260806_0027_sprints_21_25.py").read_text()
    assert 'revision = "20260806_0027"' in text
    assert 'down_revision = "20260806_0026"' in text
