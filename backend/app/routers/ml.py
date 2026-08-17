
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    MlDataset,
    MlDeployment,
    MlDriftSnapshot,
    MlFeatureDefinition,
    MlModelVersion,
    MlPrediction,
    MlPredictionFeedback,
    MlTrainingRun,
    new_id,
)
from ..schemas import (
    MlDatasetCreateRequest,
    MlDatasetResponse,
    MlDeploymentCreateRequest,
    MlDeploymentResponse,
    MlDriftResponse,
    MlFeatureCreateRequest,
    MlFeatureResponse,
    MlFeedbackCreateRequest,
    MlModelCreateRequest,
    MlModelResponse,
    MlPredictionResponse,
    MlPredictRequest,
    MlTrainingCreateRequest,
    MlTrainingResponse,
)
from ..services.ml_platform import calculate_drift, run_prediction

router = APIRouter(prefix="/ml", tags=["machine-learning"])


def _farm_allowed(principal: Principal, farm_id: str | None) -> None:
    if farm_id is None or principal.membership.role in {
        "owner",
        "admin",
        "companyAdministrator",
    }:
        return
    if principal.membership.farm_ids and farm_id not in set(principal.membership.farm_ids):
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


@router.post("/datasets", response_model=MlDatasetResponse, status_code=201)
def create_dataset(
    payload: MlDatasetCreateRequest,
    principal: Principal = Depends(require_permission("ml.manage")),
    db: Session = Depends(get_db),
) -> MlDataset:
    _farm_allowed(principal, payload.farm_id)
    item = MlDataset(
        id=new_id("ml_dataset"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="draft",
        row_count=0,
        checksum="",
        created_by=principal.user.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/datasets", response_model=list[MlDatasetResponse])
def datasets(
    farm_id: str | None = None,
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("ml.read")),
    db: Session = Depends(get_db),
) -> list[MlDataset]:
    _farm_allowed(principal, farm_id)
    query = select(MlDataset).where(
        MlDataset.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(MlDataset.farm_id == farm_id)
    if status_filter:
        query = query.where(MlDataset.status == status_filter)
    return list(db.scalars(query.order_by(MlDataset.created_at.desc())).all())


@router.post("/features", response_model=MlFeatureResponse, status_code=201)
def create_feature(
    payload: MlFeatureCreateRequest,
    principal: Principal = Depends(require_permission("ml.manage")),
    db: Session = Depends(get_db),
) -> MlFeatureDefinition:
    item = MlFeatureDefinition(
        id=new_id("ml_feature"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Chave de variável duplicada.") from exc
    db.refresh(item)
    return item


@router.get("/features", response_model=list[MlFeatureResponse])
def features(
    principal: Principal = Depends(require_permission("ml.read")),
    db: Session = Depends(get_db),
) -> list[MlFeatureDefinition]:
    return list(
        db.scalars(
            select(MlFeatureDefinition)
            .where(
                MlFeatureDefinition.company_id == principal.company.id,
                MlFeatureDefinition.active.is_(True),
            )
            .order_by(MlFeatureDefinition.name)
        ).all()
    )


@router.post("/training-runs", response_model=MlTrainingResponse, status_code=201)
def create_training_run(
    payload: MlTrainingCreateRequest,
    principal: Principal = Depends(require_permission("ml.train")),
    db: Session = Depends(get_db),
) -> MlTrainingRun:
    dataset = db.get(MlDataset, payload.dataset_id)
    if dataset is None or dataset.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Dataset não encontrado.")

    item = MlTrainingRun(
        id=new_id("ml_training"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        dataset_id=payload.dataset_id,
        algorithm=payload.algorithm,
        parameters=payload.parameters,
        metrics={},
        status="queued",
        created_by=principal.user.id,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.patch("/training-runs/{run_id}/complete", response_model=MlTrainingResponse)
def complete_training_run(
    run_id: str,
    metrics: dict,
    artifact_path: str = "",
    principal: Principal = Depends(require_permission("ml.train")),
    db: Session = Depends(get_db),
) -> MlTrainingRun:
    item = db.get(MlTrainingRun, run_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Treinamento não encontrado.")
    item.status = "completed"
    item.metrics = metrics
    item.artifact_path = artifact_path
    item.completed_at = datetime.now(timezone.utc)
    if item.started_at is None:
        item.started_at = item.created_at
    db.commit()
    db.refresh(item)
    return item


@router.get("/training-runs", response_model=list[MlTrainingResponse])
def training_runs(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("ml.read")),
    db: Session = Depends(get_db),
) -> list[MlTrainingRun]:
    query = select(MlTrainingRun).where(
        MlTrainingRun.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(MlTrainingRun.status == status_filter)
    return list(db.scalars(query.order_by(MlTrainingRun.created_at.desc())).all())


@router.post("/models", response_model=MlModelResponse, status_code=201)
def register_model(
    payload: MlModelCreateRequest,
    principal: Principal = Depends(require_permission("ml.manage")),
    db: Session = Depends(get_db),
) -> MlModelVersion:
    item = MlModelVersion(
        id=new_id("ml_model"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="candidate",
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Versão de modelo duplicada.") from exc
    db.refresh(item)
    return item


@router.get("/models", response_model=list[MlModelResponse])
def models(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("ml.read")),
    db: Session = Depends(get_db),
) -> list[MlModelVersion]:
    query = select(MlModelVersion).where(
        MlModelVersion.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(MlModelVersion.status == status_filter)
    return list(db.scalars(query.order_by(MlModelVersion.created_at.desc())).all())


@router.post("/deployments", response_model=MlDeploymentResponse, status_code=201)
def deploy_model(
    payload: MlDeploymentCreateRequest,
    principal: Principal = Depends(require_permission("ml.deploy")),
    db: Session = Depends(get_db),
) -> MlDeployment:
    _farm_allowed(principal, payload.farm_id)
    model = db.get(MlModelVersion, payload.model_id)
    if model is None or model.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Modelo não encontrado.")

    item = MlDeployment(
        id=new_id("ml_deployment"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        model_id=model.id,
        farm_id=payload.farm_id,
        environment=payload.environment,
        traffic_percent=payload.traffic_percent,
        threshold=payload.threshold,
        status="active",
        deployed_by=principal.user.id,
    )
    model.status = "deployed"
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/deployments", response_model=list[MlDeploymentResponse])
def deployments(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("ml.read")),
    db: Session = Depends(get_db),
) -> list[MlDeployment]:
    _farm_allowed(principal, farm_id)
    query = select(MlDeployment).where(
        MlDeployment.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(MlDeployment.farm_id == farm_id)
    return list(db.scalars(query.order_by(MlDeployment.deployed_at.desc())).all())


@router.post(
    "/deployments/{deployment_id}/predict",
    response_model=MlPredictionResponse,
)
def predict(
    deployment_id: str,
    payload: MlPredictRequest,
    principal: Principal = Depends(require_permission("ml.predict")),
    db: Session = Depends(get_db),
) -> MlPrediction:
    _farm_allowed(principal, payload.farm_id)
    deployment = db.get(MlDeployment, deployment_id)
    if (
        deployment is None
        or deployment.company_id != principal.company.id
        or deployment.status != "active"
    ):
        raise HTTPException(status_code=404, detail="Deploy ativo não encontrado.")

    model = db.get(MlModelVersion, deployment.model_id)
    if model is None:
        raise HTTPException(status_code=404, detail="Modelo não encontrado.")

    item = run_prediction(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        deployment=deployment,
        model=model,
        farm_id=payload.farm_id,
        entity_type=payload.entity_type,
        entity_id=payload.entity_id,
        features=payload.features,
    )
    db.commit()
    db.refresh(item)
    return item


@router.get("/predictions", response_model=list[MlPredictionResponse])
def predictions(
    deployment_id: str | None = None,
    limit: int = Query(default=200, ge=1, le=2000),
    principal: Principal = Depends(require_permission("ml.read")),
    db: Session = Depends(get_db),
) -> list[MlPrediction]:
    query = select(MlPrediction).where(
        MlPrediction.company_id == principal.company.id
    )
    if deployment_id:
        query = query.where(MlPrediction.deployment_id == deployment_id)
    return list(
        db.scalars(
            query.order_by(MlPrediction.created_at.desc()).limit(limit)
        ).all()
    )


@router.post("/predictions/{prediction_id}/feedback", status_code=201)
def feedback(
    prediction_id: str,
    payload: MlFeedbackCreateRequest,
    principal: Principal = Depends(require_permission("ml.feedback")),
    db: Session = Depends(get_db),
) -> dict:
    prediction = db.get(MlPrediction, prediction_id)
    if prediction is None or prediction.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Predição não encontrada.")

    item = MlPredictionFeedback(
        id=new_id("ml_feedback"),
        prediction_id=prediction.id,
        company_id=principal.company.id,
        actual_value=payload.actual_value,
        accepted=payload.accepted,
        notes=payload.notes,
        created_by=principal.user.id,
    )
    db.add(item)
    db.commit()
    return {"id": item.id, "prediction_id": prediction.id}


@router.post("/deployments/{deployment_id}/drift", response_model=MlDriftResponse)
def generate_drift(
    deployment_id: str,
    principal: Principal = Depends(require_permission("ml.manage")),
    db: Session = Depends(get_db),
) -> MlDriftSnapshot:
    deployment = db.get(MlDeployment, deployment_id)
    if deployment is None or deployment.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Deploy não encontrado.")

    item = calculate_drift(
        db,
        company_id=principal.company.id,
        deployment=deployment,
    )
    db.commit()
    db.refresh(item)
    return item


@router.get("/deployments/{deployment_id}/drift", response_model=list[MlDriftResponse])
def drift_history(
    deployment_id: str,
    principal: Principal = Depends(require_permission("ml.read")),
    db: Session = Depends(get_db),
) -> list[MlDriftSnapshot]:
    deployment = db.get(MlDeployment, deployment_id)
    if deployment is None or deployment.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Deploy não encontrado.")
    return list(
        db.scalars(
            select(MlDriftSnapshot)
            .where(MlDriftSnapshot.deployment_id == deployment_id)
            .order_by(MlDriftSnapshot.generated_at.desc())
        ).all()
    )


@router.get("/dashboard")
def ml_dashboard(
    principal: Principal = Depends(require_permission("ml.read")),
    db: Session = Depends(get_db),
) -> dict:
    company_id = principal.company.id

    datasets_count = db.scalar(
        select(func.count()).select_from(MlDataset).where(
            MlDataset.company_id == company_id
        )
    ) or 0
    models_count = db.scalar(
        select(func.count()).select_from(MlModelVersion).where(
            MlModelVersion.company_id == company_id
        )
    ) or 0
    deployments_count = db.scalar(
        select(func.count()).select_from(MlDeployment).where(
            MlDeployment.company_id == company_id,
            MlDeployment.status == "active",
        )
    ) or 0
    predictions_count = db.scalar(
        select(func.count()).select_from(MlPrediction).where(
            MlPrediction.company_id == company_id
        )
    ) or 0

    recent_drift = list(
        db.scalars(
            select(MlDriftSnapshot)
            .where(MlDriftSnapshot.company_id == company_id)
            .order_by(MlDriftSnapshot.generated_at.desc())
            .limit(10)
        ).all()
    )

    return {
        "datasets": int(datasets_count),
        "models": int(models_count),
        "active_deployments": int(deployments_count),
        "predictions": int(predictions_count),
        "drift_alerts": sum(
            1 for item in recent_drift if item.status in {"attention", "critical"}
        ),
        "runtime": "atlas_baseline_explainable",
        "trained_artifact_runtime_connected": False,
    }
