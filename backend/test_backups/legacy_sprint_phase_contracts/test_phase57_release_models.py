
from app.models import (
    ChangeApproval,
    DeploymentEnvironment,
    DeploymentRelease,
    FeatureFlag,
    ProductionReadinessCheck,
    ReleaseBuild,
    ReleaseMetricSnapshot,
    ReleasePipeline,
)


def test_phase57_tables():
    assert ReleasePipeline.__tablename__ == "release_pipelines"
    assert ReleaseBuild.__tablename__ == "release_builds"
    assert DeploymentEnvironment.__tablename__ == "deployment_environments"
    assert DeploymentRelease.__tablename__ == "deployment_releases"
    assert FeatureFlag.__tablename__ == "feature_flags"
    assert ChangeApproval.__tablename__ == "change_approvals"
    assert ProductionReadinessCheck.__tablename__ == "production_readiness_checks"
    assert ReleaseMetricSnapshot.__tablename__ == "release_metric_snapshots"
