from pathlib import Path

def test_advanced_files_and_routes_exist():
    root=Path(__file__).parents[1]
    router=(root/'app/routers/advanced.py').read_text(encoding='utf-8')
    for route in ['/geo-assets','/pasture/dashboard','/agriculture/dashboard','/genetics/ranking','/ai/forecast','/advanced-dashboard']:
        assert route in router

def test_migration_chain():
    root=Path(__file__).parents[1]
    text=(root/'alembic/versions/20260806_0023_advanced_blocks_1_5.py').read_text(encoding='utf-8')
    assert 'down_revision="20260806_0022"' in text
    for table in ['atlas_geo_assets','atlas_pasture_records','atlas_agriculture_records','atlas_genetic_profiles','atlas_ai_forecasts']:
        assert table in text
