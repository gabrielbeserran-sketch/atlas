from app.security_compliance_models import SecurityRole, SecurityIncident, ImmutableAuditRecord, PrivacyRequest, BackupExecution, AvailabilityTarget, TranslationResource, RegionalPolicy, ComplianceCertification, ContinuityPlan
from app.routers.security_compliance import router

def test_tables():
    assert SecurityRole.__tablename__=='security_roles_v2'
    assert ImmutableAuditRecord.__tablename__=='immutable_audit_records'
    assert PrivacyRequest.__tablename__=='compliance_privacy_requests'
    assert ContinuityPlan.__tablename__=='continuity_plans_v2'

def test_router_contract():
    paths={r.path for r in router.routes}
    assert '/security-compliance/audit/verify' in paths
    assert '/security-compliance/privacy/requests' in paths
    assert '/security-compliance/dashboard' in paths
