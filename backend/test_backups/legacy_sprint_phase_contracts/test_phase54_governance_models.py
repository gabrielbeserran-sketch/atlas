
from app.models import (
    ComplianceAssessment,
    ComplianceControl,
    DataCatalogAsset,
    DataGovernancePolicy,
    DataQualityRule,
    DataQualityRun,
    ResilienceIncident,
    ServiceHealthSnapshot,
)


def test_phase54_tables():
    assert DataGovernancePolicy.__tablename__ == "data_governance_policies"
    assert DataCatalogAsset.__tablename__ == "data_catalog_assets"
    assert DataQualityRule.__tablename__ == "data_quality_rules"
    assert DataQualityRun.__tablename__ == "data_quality_runs"
    assert ComplianceControl.__tablename__ == "compliance_controls"
    assert ComplianceAssessment.__tablename__ == "compliance_assessments"
    assert ServiceHealthSnapshot.__tablename__ == "service_health_snapshots"
    assert ResilienceIncident.__tablename__ == "resilience_incidents"
