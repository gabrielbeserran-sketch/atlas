
from app.models import (
    MlDataset,
    MlDeployment,
    MlDriftSnapshot,
    MlFeatureDefinition,
    MlModelVersion,
    MlPrediction,
    MlPredictionFeedback,
    MlTrainingRun,
)


def test_phase51_tables():
    assert MlDataset.__tablename__ == "ml_datasets"
    assert MlFeatureDefinition.__tablename__ == "ml_feature_definitions"
    assert MlTrainingRun.__tablename__ == "ml_training_runs"
    assert MlModelVersion.__tablename__ == "ml_model_versions"
    assert MlDeployment.__tablename__ == "ml_deployments"
    assert MlPrediction.__tablename__ == "ml_predictions"
    assert MlPredictionFeedback.__tablename__ == "ml_prediction_feedback"
    assert MlDriftSnapshot.__tablename__ == "ml_drift_snapshots"
