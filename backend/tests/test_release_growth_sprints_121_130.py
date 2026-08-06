from app.release_growth_models import ReleaseEnvironment, PilotProgram, MobileReleaseProfile, WebRelease, LearningPath, DocumentationPage, GrowthExperiment, ProductCapabilityReview, AtlasRoadmap, ReleaseReadinessAssessment
from app.routers import release_growth

def test_tables():
    assert ReleaseEnvironment.__tablename__=='release_environments_v2'
    assert PilotProgram.__tablename__=='pilot_programs_v2'
    assert MobileReleaseProfile.__tablename__=='mobile_release_profiles'
    assert ReleaseReadinessAssessment.__tablename__=='release_readiness_assessments'

def test_router_contract():
    paths={r.path for r in release_growth.router.routes}
    assert '/release-growth/environments' in paths
    assert '/release-growth/pilots' in paths
    assert '/release-growth/readiness' in paths
    assert '/release-growth/dashboard' in paths
