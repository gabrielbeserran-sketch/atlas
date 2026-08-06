
"""machine learning platform

Revision ID: 20260805_0010
Revises: 20260805_0009
"""
from alembic import op
import sqlalchemy as sa

revision = "20260805_0010"
down_revision = "20260805_0009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "ml_datasets",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("version", sa.String(50), nullable=False),
        sa.Column("task_type", sa.String(50), nullable=False),
        sa.Column("target_column", sa.String(120), nullable=False),
        sa.Column("source_tables", sa.JSON(), nullable=False),
        sa.Column("filters", sa.JSON(), nullable=False),
        sa.Column("schema_json", sa.JSON(), nullable=False),
        sa.Column("row_count", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("checksum", sa.String(128), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ml_datasets_company", "ml_datasets", ["company_id"])
    op.create_index("ix_ml_datasets_farm", "ml_datasets", ["farm_id"])
    op.create_index("ix_ml_datasets_status", "ml_datasets", ["status"])

    op.create_table(
        "ml_feature_definitions",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("key", sa.String(120), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("data_type", sa.String(40), nullable=False),
        sa.Column("source_expression", sa.Text(), nullable=False),
        sa.Column("default_value", sa.Float(), nullable=True),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "key", name="uq_ml_feature_company_key"),
    )

    op.create_table(
        "ml_training_runs",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("dataset_id", sa.String(80), sa.ForeignKey("ml_datasets.id", ondelete="CASCADE"), nullable=False),
        sa.Column("algorithm", sa.String(80), nullable=False),
        sa.Column("parameters", sa.JSON(), nullable=False),
        sa.Column("metrics", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=False),
        sa.Column("artifact_path", sa.String(500), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ml_training_company", "ml_training_runs", ["company_id"])
    op.create_index("ix_ml_training_dataset", "ml_training_runs", ["dataset_id"])
    op.create_index("ix_ml_training_status", "ml_training_runs", ["status"])

    op.create_table(
        "ml_model_versions",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("training_run_id", sa.String(80), sa.ForeignKey("ml_training_runs.id", ondelete="SET NULL"), nullable=True),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("version", sa.String(50), nullable=False),
        sa.Column("task_type", sa.String(50), nullable=False),
        sa.Column("algorithm", sa.String(80), nullable=False),
        sa.Column("metrics", sa.JSON(), nullable=False),
        sa.Column("feature_keys", sa.JSON(), nullable=False),
        sa.Column("target_name", sa.String(120), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("artifact_path", sa.String(500), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "name", "version", name="uq_ml_model_name_version"),
    )
    op.create_index("ix_ml_models_company", "ml_model_versions", ["company_id"])
    op.create_index("ix_ml_models_status", "ml_model_versions", ["status"])

    op.create_table(
        "ml_deployments",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("model_id", sa.String(80), sa.ForeignKey("ml_model_versions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("environment", sa.String(40), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("traffic_percent", sa.Float(), nullable=False),
        sa.Column("threshold", sa.Float(), nullable=True),
        sa.Column("deployed_by", sa.String(80), nullable=False),
        sa.Column("deployed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("retired_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_ml_deployments_company", "ml_deployments", ["company_id"])
    op.create_index("ix_ml_deployments_farm", "ml_deployments", ["farm_id"])
    op.create_index("ix_ml_deployments_status", "ml_deployments", ["status"])

    op.create_table(
        "ml_predictions",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("deployment_id", sa.String(80), sa.ForeignKey("ml_deployments.id", ondelete="CASCADE"), nullable=False),
        sa.Column("entity_type", sa.String(80), nullable=False),
        sa.Column("entity_id", sa.String(120), nullable=False),
        sa.Column("input_features", sa.JSON(), nullable=False),
        sa.Column("prediction", sa.JSON(), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("explanation", sa.JSON(), nullable=False),
        sa.Column("latency_ms", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ml_predictions_company", "ml_predictions", ["company_id"])
    op.create_index("ix_ml_predictions_deployment", "ml_predictions", ["deployment_id"])
    op.create_index("ix_ml_predictions_created", "ml_predictions", ["created_at"])

    op.create_table(
        "ml_prediction_feedback",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("prediction_id", sa.String(80), sa.ForeignKey("ml_predictions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("actual_value", sa.JSON(), nullable=False),
        sa.Column("accepted", sa.Boolean(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ml_feedback_prediction", "ml_prediction_feedback", ["prediction_id"])

    op.create_table(
        "ml_drift_snapshots",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("deployment_id", sa.String(80), sa.ForeignKey("ml_deployments.id", ondelete="CASCADE"), nullable=False),
        sa.Column("feature_drift", sa.JSON(), nullable=False),
        sa.Column("prediction_drift", sa.Float(), nullable=False),
        sa.Column("performance_drift", sa.Float(), nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("recommendations", sa.JSON(), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ml_drift_company", "ml_drift_snapshots", ["company_id"])
    op.create_index("ix_ml_drift_deployment", "ml_drift_snapshots", ["deployment_id"])
    op.create_index("ix_ml_drift_status", "ml_drift_snapshots", ["status"])


def downgrade() -> None:
    op.drop_table("ml_drift_snapshots")
    op.drop_table("ml_prediction_feedback")
    op.drop_table("ml_predictions")
    op.drop_table("ml_deployments")
    op.drop_table("ml_model_versions")
    op.drop_table("ml_training_runs")
    op.drop_table("ml_feature_definitions")
    op.drop_table("ml_datasets")
