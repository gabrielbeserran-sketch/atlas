
from __future__ import annotations

import math
import time
from datetime import datetime, timezone
from statistics import mean, pstdev

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import (
    MlDeployment,
    MlDriftSnapshot,
    MlModelVersion,
    MlPrediction,
    MlPredictionFeedback,
    new_id,
)


def baseline_predict(
    *,
    model: MlModelVersion,
    features: dict[str, float],
) -> tuple[dict, float, dict]:
    values = [float(value) for value in features.values()]
    if not values:
        return (
            {"value": 0.0, "label": "insufficient_data"},
            0.0,
            {"reason": "Nenhuma variável foi fornecida."},
        )

    average = mean(values)
    spread = pstdev(values) if len(values) > 1 else 0.0
    normalized = 1 / (1 + math.exp(-average / 10))

    if model.task_type == "classification":
        threshold = float(model.metadata_json.get("classification_threshold", 0.5))
        label = "positive" if normalized >= threshold else "negative"
        prediction = {"label": label, "probability": round(normalized, 6)}
        confidence = abs(normalized - 0.5) * 2 * 100
    else:
        prediction = {"value": round(average, 6)}
        confidence = max(0.0, min(100.0, 100.0 - spread))

    explanation = {
        "engine": "atlas_baseline_explainable",
        "algorithm_declared": model.algorithm,
        "feature_count": len(values),
        "feature_average": round(average, 6),
        "feature_spread": round(spread, 6),
        "warning": (
            "Este resultado é produzido pelo baseline explicável da Fase 51. "
            "O artefato treinado real ainda precisa ser conectado ao runtime."
        ),
    }
    return prediction, round(confidence, 2), explanation


def run_prediction(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    deployment: MlDeployment,
    model: MlModelVersion,
    farm_id: str | None,
    entity_type: str,
    entity_id: str,
    features: dict[str, float],
) -> MlPrediction:
    started = time.perf_counter()
    prediction, confidence, explanation = baseline_predict(
        model=model,
        features=features,
    )
    latency_ms = int((time.perf_counter() - started) * 1000)

    item = MlPrediction(
        id=new_id("ml_prediction"),
        tenant_id=tenant_id,
        company_id=company_id,
        farm_id=farm_id,
        deployment_id=deployment.id,
        entity_type=entity_type,
        entity_id=entity_id,
        input_features=features,
        prediction=prediction,
        confidence=confidence,
        explanation=explanation,
        latency_ms=latency_ms,
    )
    db.add(item)
    db.flush()
    return item


def calculate_drift(
    db: Session,
    *,
    company_id: str,
    deployment: MlDeployment,
) -> MlDriftSnapshot:
    predictions = list(
        db.scalars(
            select(MlPrediction)
            .where(
                MlPrediction.company_id == company_id,
                MlPrediction.deployment_id == deployment.id,
            )
            .order_by(MlPrediction.created_at.desc())
            .limit(500)
        ).all()
    )

    feedback = list(
        db.scalars(
            select(MlPredictionFeedback)
            .join(MlPrediction, MlPrediction.id == MlPredictionFeedback.prediction_id)
            .where(
                MlPrediction.company_id == company_id,
                MlPrediction.deployment_id == deployment.id,
            )
        ).all()
    )

    confidence_values = [item.confidence for item in predictions]
    prediction_drift = (
        max(0.0, 100.0 - mean(confidence_values))
        if confidence_values
        else 100.0
    )

    accepted_values = [
        1.0 if item.accepted else 0.0
        for item in feedback
        if item.accepted is not None
    ]
    performance_drift = (
        max(0.0, 100.0 - mean(accepted_values) * 100)
        if accepted_values
        else None
    )

    feature_names = sorted(
        {
            key
            for prediction in predictions
            for key in prediction.input_features.keys()
        }
    )
    feature_drift = {}
    for key in feature_names:
        values = [
            float(item.input_features[key])
            for item in predictions
            if key in item.input_features
        ]
        feature_drift[key] = {
            "count": len(values),
            "mean": round(mean(values), 6) if values else 0.0,
            "spread": round(pstdev(values), 6) if len(values) > 1 else 0.0,
        }

    severity = max(
        prediction_drift,
        performance_drift if performance_drift is not None else 0.0,
    )
    status = "critical" if severity >= 60 else "attention" if severity >= 30 else "stable"
    recommendations = []
    if not predictions:
        recommendations.append("Gerar previsões antes de avaliar deriva.")
    if performance_drift is None:
        recommendations.append("Registrar feedback real para medir desempenho.")
    if severity >= 30:
        recommendations.append("Revisar dados, variáveis e necessidade de novo treinamento.")
    if not recommendations:
        recommendations.append("Manter monitoramento do modelo.")

    item = MlDriftSnapshot(
        id=new_id("ml_drift"),
        company_id=company_id,
        deployment_id=deployment.id,
        feature_drift=feature_drift,
        prediction_drift=round(prediction_drift, 2),
        performance_drift=(
            round(performance_drift, 2)
            if performance_drift is not None
            else None
        ),
        status=status,
        recommendations=recommendations,
    )
    db.add(item)
    db.flush()
    return item
