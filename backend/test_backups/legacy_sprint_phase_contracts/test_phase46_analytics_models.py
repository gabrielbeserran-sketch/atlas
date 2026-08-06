
from app.models import (
    AnalyticsBenchmarkSnapshot,
    AnalyticsFactSnapshot,
    AnalyticsFarmScore,
    AnalyticsGoal,
    AnalyticsKpiDefinition,
)


def test_phase46_tables():
    assert AnalyticsFactSnapshot.__tablename__ == "analytics_fact_snapshots"
    assert AnalyticsKpiDefinition.__tablename__ == "analytics_kpi_definitions"
    assert AnalyticsGoal.__tablename__ == "analytics_goals"
    assert AnalyticsBenchmarkSnapshot.__tablename__ == "analytics_benchmark_snapshots"
    assert AnalyticsFarmScore.__tablename__ == "analytics_farm_scores"
