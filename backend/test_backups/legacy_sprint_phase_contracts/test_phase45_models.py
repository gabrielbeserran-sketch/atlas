
from app.models import IndicatorSnapshot, OperationalAlert, OperationalTask


def test_phase45_tables():
    assert OperationalAlert.__tablename__ == "operational_alerts"
    assert OperationalTask.__tablename__ == "operational_tasks"
    assert IndicatorSnapshot.__tablename__ == "indicator_snapshots"
