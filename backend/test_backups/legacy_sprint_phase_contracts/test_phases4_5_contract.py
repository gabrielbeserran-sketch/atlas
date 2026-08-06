from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def test_platform_router_is_registered():
    main=(ROOT/'app/main.py').read_text(encoding='utf-8')
    assert 'platform.router' in main

def test_phase45_endpoints_exist():
    text=(ROOT/'app/routers/platform.py').read_text(encoding='utf-8')
    for route in ('/dashboard/farms/{farm_id}','/dashboard/company','/ai/context/farms/{farm_id}','/automations/farms/{farm_id}/evaluate','/security/readiness/farms/{farm_id}','/production/readiness'):
        assert route in text

def test_domain_permissions_exist():
    text=(ROOT/'app/authz.py').read_text(encoding='utf-8')
    for permission in ('herd.read','reproduction.write','health.write','nutrition.write','inventory.write','finance.write','platform.read'):
        assert f'"{permission}"' in text
