
from app.models import (
    AccessReview,
    BusinessContinuityPlan,
    ContinuityExercise,
    PrivacyConsent,
    PrivacyRequest,
    SecurityPolicy,
    SecurityPostureSnapshot,
    SecurityRisk,
)


def test_phase56_tables():
    assert SecurityPolicy.__tablename__ == "security_policies"
    assert AccessReview.__tablename__ == "access_reviews"
    assert PrivacyConsent.__tablename__ == "privacy_consents"
    assert PrivacyRequest.__tablename__ == "privacy_requests"
    assert SecurityRisk.__tablename__ == "security_risks"
    assert BusinessContinuityPlan.__tablename__ == "business_continuity_plans"
    assert ContinuityExercise.__tablename__ == "continuity_exercises"
    assert SecurityPostureSnapshot.__tablename__ == "security_posture_snapshots"
