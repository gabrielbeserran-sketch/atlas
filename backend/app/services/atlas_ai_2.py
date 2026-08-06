
from __future__ import annotations

import time
from datetime import datetime, timezone
from statistics import mean

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models import (
    AnalyticsFactSnapshot,
    AnalyticsFarmScore,
    AtlasAiExecution,
    AtlasAiRecommendation,
    FinancialEntry,
    HealthEvent,
    InventoryProduct,
    LivestockAnimal,
    ReproductionEvent,
    WeightRecord,
    new_id,
)


ENGINE_VERSION = "2.0-rule-explainable"


def _fact_map(
    db: Session,
    *,
    company_id: str,
    farm_id: str | None,
) -> dict[str, float]:
    query = select(AnalyticsFactSnapshot).where(
        AnalyticsFactSnapshot.company_id == company_id
    )
    if farm_id:
        query = query.where(AnalyticsFactSnapshot.farm_id == farm_id)

    facts = list(
        db.scalars(
            query.order_by(AnalyticsFactSnapshot.period_end.desc())
        ).all()
    )
    result: dict[str, float] = {}
    for item in facts:
        result.setdefault(item.metric_key, item.value)
    return result


def _recommendation(
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    animal_id: str | None,
    area: str,
    recommendation_type: str,
    title: str,
    summary: str,
    rationale: str,
    actions: list[str],
    evidence: list[dict],
    assumptions: list[str],
    confidence: float,
    priority: str,
    financial_impact: float = 0,
) -> AtlasAiRecommendation:
    return AtlasAiRecommendation(
        id=new_id("ai_recommendation"),
        tenant_id=tenant_id,
        company_id=company_id,
        farm_id=farm_id,
        animal_id=animal_id,
        area=area,
        recommendation_type=recommendation_type,
        title=title,
        summary=summary,
        rationale=rationale,
        action_items=actions,
        evidence=evidence,
        assumptions=assumptions,
        confidence=max(0.0, min(100.0, confidence)),
        priority=priority,
        financial_impact=financial_impact,
        generated_by=ENGINE_VERSION,
    )


def health_recommendations(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    animal_id: str | None,
) -> list[AtlasAiRecommendation]:
    query = select(HealthEvent).where(
        HealthEvent.company_id == company_id
    )
    if farm_id:
        query = query.where(HealthEvent.farm_id == farm_id)
    if animal_id:
        query = query.where(HealthEvent.animal_id == animal_id)
    events = list(db.scalars(query).all())

    recommendations: list[AtlasAiRecommendation] = []
    withdrawal = [item for item in events if item.withdrawal_until and item.withdrawal_until > datetime.now(timezone.utc)]
    if withdrawal:
        recommendations.append(
            _recommendation(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=animal_id,
                area="health",
                recommendation_type="withdrawal_control",
                title="Reforçar controle de carência",
                summary=f"Foram encontrados {len(withdrawal)} eventos com carência ativa.",
                rationale="Animais ou lotes em carência exigem bloqueio operacional para evitar venda ou abate indevido.",
                actions=[
                    "Bloquear movimentações comerciais dos animais afetados.",
                    "Conferir produto, dose e data final de carência.",
                    "Registrar liberação somente após o término do período.",
                ],
                evidence=[
                    {"source": "health_events", "active_withdrawal_events": len(withdrawal)}
                ],
                assumptions=["As datas de carência registradas estão corretas."],
                confidence=94,
                priority="high",
            )
        )

    if len(events) == 0:
        recommendations.append(
            _recommendation(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=animal_id,
                area="health",
                recommendation_type="missing_health_history",
                title="Completar histórico sanitário",
                summary="Não há eventos sanitários suficientes para análise.",
                rationale="A ausência de registros reduz a segurança das recomendações e pode ocultar riscos.",
                actions=[
                    "Importar o calendário sanitário.",
                    "Cadastrar vacinas e tratamentos recentes.",
                    "Revisar responsáveis e datas.",
                ],
                evidence=[{"source": "health_events", "count": 0}],
                assumptions=["A ausência de dados não significa ausência de ocorrências."],
                confidence=88,
                priority="medium",
            )
        )

    return recommendations


def nutrition_recommendations(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
) -> list[AtlasAiRecommendation]:
    query = select(InventoryProduct).where(
        InventoryProduct.company_id == company_id,
        InventoryProduct.active.is_(True),
    )
    if farm_id:
        query = query.where(InventoryProduct.farm_id == farm_id)

    products = list(db.scalars(query).all())
    low_stock = [item for item in products if item.quantity <= item.minimum_quantity]
    recommendations: list[AtlasAiRecommendation] = []

    if low_stock:
        recommendations.append(
            _recommendation(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=None,
                area="nutrition",
                recommendation_type="feed_stock_risk",
                title="Risco de ruptura de insumos",
                summary=f"{len(low_stock)} produtos estão no estoque mínimo ou abaixo dele.",
                rationale="Ruptura de suplemento ou ingrediente pode interromper dietas e reduzir desempenho.",
                actions=[
                    "Revisar consumo diário por lote.",
                    "Priorizar compra dos itens críticos.",
                    "Atualizar prazo de entrega dos fornecedores.",
                ],
                evidence=[
                    {
                        "source": "inventory_products",
                        "products": [
                            {
                                "id": item.id,
                                "name": item.name,
                                "quantity": item.quantity,
                                "minimum": item.minimum_quantity,
                            }
                            for item in low_stock[:20]
                        ],
                    }
                ],
                assumptions=["Os saldos de estoque estão atualizados."],
                confidence=92,
                priority="high",
                financial_impact=sum(
                    max(0, item.minimum_quantity - item.quantity) * item.average_cost
                    for item in low_stock
                ),
            )
        )

    return recommendations


def reproduction_recommendations(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    animal_id: str | None,
) -> list[AtlasAiRecommendation]:
    query = select(ReproductionEvent).where(
        ReproductionEvent.company_id == company_id
    )
    if farm_id:
        query = query.where(ReproductionEvent.farm_id == farm_id)
    if animal_id:
        query = query.where(ReproductionEvent.animal_id == animal_id)

    events = list(db.scalars(query).all())
    negative = [
        item for item in events
        if item.result.strip().lower() in {"negative", "negativo", "vazia", "open"}
    ]
    recommendations: list[AtlasAiRecommendation] = []

    if negative:
        recommendations.append(
            _recommendation(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=animal_id,
                area="reproduction",
                recommendation_type="reproductive_review",
                title="Revisar fêmeas com resultado reprodutivo negativo",
                summary=f"{len(negative)} eventos indicam resultado negativo ou fêmea aberta.",
                rationale="Resultados negativos recorrentes elevam dias improdutivos e custo por prenhez.",
                actions=[
                    "Confirmar diagnóstico e condição corporal.",
                    "Revisar protocolo, manejo e touro/sêmen utilizado.",
                    "Definir nova tentativa ou descarte técnico.",
                ],
                evidence=[{"source": "reproduction_events", "negative_results": len(negative)}],
                assumptions=["Os resultados foram registrados com nomenclatura consistente."],
                confidence=86,
                priority="high",
            )
        )

    return recommendations


def finance_recommendations(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
) -> list[AtlasAiRecommendation]:
    facts = _fact_map(db, company_id=company_id, farm_id=farm_id)
    balance = facts.get("financial_balance", 0)
    recommendations: list[AtlasAiRecommendation] = []

    if balance < 0:
        recommendations.append(
            _recommendation(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=None,
                area="finance",
                recommendation_type="negative_balance",
                title="Corrigir saldo financeiro negativo",
                summary=f"O saldo consolidado está em R$ {balance:.2f}.",
                rationale="Saldo negativo reduz capacidade de investimento e aumenta risco de caixa.",
                actions=[
                    "Separar despesas fixas, variáveis e extraordinárias.",
                    "Revisar itens de maior impacto.",
                    "Criar plano de caixa para 30, 60 e 90 dias.",
                ],
                evidence=[{"source": "analytics_fact_snapshots", "financial_balance": balance}],
                assumptions=["Receitas e despesas foram lançadas integralmente."],
                confidence=91,
                priority="high",
                financial_impact=abs(balance),
            )
        )

    return recommendations


def climate_recommendations(
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    context: dict,
) -> list[AtlasAiRecommendation]:
    rain_forecast = float(context.get("rain_forecast_mm", 0) or 0)
    temperature = float(context.get("max_temperature_c", 0) or 0)
    recommendations: list[AtlasAiRecommendation] = []

    if temperature >= 35:
        recommendations.append(
            _recommendation(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=None,
                area="climate",
                recommendation_type="heat_stress",
                title="Risco de estresse térmico",
                summary=f"A temperatura máxima informada é {temperature:.1f} °C.",
                rationale="Temperaturas elevadas podem reduzir consumo, ganho e fertilidade.",
                actions=[
                    "Garantir sombra e água de qualidade.",
                    "Evitar manejo nas horas mais quentes.",
                    "Monitorar frequência respiratória e consumo.",
                ],
                evidence=[{"source": "request_context", "max_temperature_c": temperature}],
                assumptions=["A previsão fornecida representa a fazenda."],
                confidence=78,
                priority="high",
            )
        )

    if rain_forecast >= 50:
        recommendations.append(
            _recommendation(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=None,
                area="climate",
                recommendation_type="heavy_rain",
                title="Preparar operação para chuva intensa",
                summary=f"A previsão informada indica {rain_forecast:.1f} mm.",
                rationale="Chuva intensa pode afetar acesso, cochos, armazenamento e manejo sanitário.",
                actions=[
                    "Revisar drenagem e acesso aos lotes.",
                    "Proteger insumos e medicamentos.",
                    "Reprogramar operações sensíveis.",
                ],
                evidence=[{"source": "request_context", "rain_forecast_mm": rain_forecast}],
                assumptions=["A previsão ainda pode mudar."],
                confidence=72,
                priority="medium",
            )
        )

    return recommendations


def market_recommendations(
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    context: dict,
) -> list[AtlasAiRecommendation]:
    market_price = float(context.get("market_price_per_kg", 0) or 0)
    expected_price = float(context.get("expected_price_per_kg", 0) or 0)
    average_weight = float(context.get("average_sale_weight_kg", 0) or 0)

    if market_price <= 0 or average_weight <= 0:
        return []

    difference = expected_price - market_price
    action = "Aguardar e acompanhar o mercado" if difference > 0 else "Avaliar venda dos lotes prontos"
    return [
        _recommendation(
            tenant_id=tenant_id,
            company_id=company_id,
            farm_id=farm_id,
            animal_id=None,
            area="market",
            recommendation_type="sale_timing",
            title="Análise de momento de venda",
            summary=action,
            rationale=(
                f"Preço atual: R$ {market_price:.2f}/kg; "
                f"preço esperado: R$ {expected_price:.2f}/kg."
            ),
            actions=[
                "Validar animais realmente prontos para venda.",
                "Comparar custo diário de permanência com ganho esperado.",
                "Solicitar pelo menos duas propostas comerciais.",
            ],
            evidence=[
                {
                    "source": "request_context",
                    "market_price_per_kg": market_price,
                    "expected_price_per_kg": expected_price,
                    "average_sale_weight_kg": average_weight,
                }
            ],
            assumptions=[
                "Os preços e custos foram fornecidos pelo usuário.",
                "A recomendação não substitui análise comercial local.",
            ],
            confidence=68,
            priority="medium",
            financial_impact=difference * average_weight,
        )
    ]


def execute_area(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    animal_id: str | None,
    area: str,
    context: dict,
) -> list[AtlasAiRecommendation]:
    started = time.perf_counter()
    success = True
    error_message = ""
    recommendations: list[AtlasAiRecommendation] = []

    try:
        if area == "health":
            recommendations = health_recommendations(
                db,
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=animal_id,
            )
        elif area == "nutrition":
            recommendations = nutrition_recommendations(
                db,
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
            )
        elif area == "reproduction":
            recommendations = reproduction_recommendations(
                db,
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                animal_id=animal_id,
            )
        elif area == "finance":
            recommendations = finance_recommendations(
                db,
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
            )
        elif area == "climate":
            recommendations = climate_recommendations(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                context=context,
            )
        elif area == "market":
            recommendations = market_recommendations(
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                context=context,
            )
        elif area in {"strategy", "executive", "general"}:
            for specialist in ("health", "nutrition", "reproduction", "finance"):
                recommendations.extend(
                    execute_area(
                        db,
                        tenant_id=tenant_id,
                        company_id=company_id,
                        farm_id=farm_id,
                        animal_id=animal_id,
                        area=specialist,
                        context=context,
                    )
                )
            recommendations.extend(
                climate_recommendations(
                    tenant_id=tenant_id,
                    company_id=company_id,
                    farm_id=farm_id,
                    context=context,
                )
            )
            recommendations.extend(
                market_recommendations(
                    tenant_id=tenant_id,
                    company_id=company_id,
                    farm_id=farm_id,
                    context=context,
                )
            )
        else:
            raise ValueError(f"Área de IA não suportada: {area}")

        for item in recommendations:
            db.add(item)
    except Exception as exc:
        success = False
        error_message = str(exc)
        raise
    finally:
        duration_ms = int((time.perf_counter() - started) * 1000)
        confidence = mean([item.confidence for item in recommendations]) if recommendations else 0
        db.add(
            AtlasAiExecution(
                id=new_id("ai_execution"),
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                area=area,
                engine_version=ENGINE_VERSION,
                input_payload={
                    "farm_id": farm_id,
                    "animal_id": animal_id,
                    "context": context,
                },
                output_payload={
                    "recommendation_ids": [item.id for item in recommendations],
                    "count": len(recommendations),
                },
                confidence=confidence,
                duration_ms=duration_ms,
                success=success,
                error_message=error_message,
            )
        )

    db.flush()
    return recommendations


def executive_summary(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    context: dict,
) -> dict:
    recommendations = execute_area(
        db,
        tenant_id=tenant_id,
        company_id=company_id,
        farm_id=farm_id,
        animal_id=None,
        area="executive",
        context=context,
    )
    priorities = {"high": 3, "medium": 2, "low": 1}
    recommendations.sort(
        key=lambda item: (
            priorities.get(item.priority, 0),
            item.confidence,
        ),
        reverse=True,
    )

    score_item = None
    if farm_id:
        score_item = db.scalar(
            select(AnalyticsFarmScore)
            .where(
                AnalyticsFarmScore.company_id == company_id,
                AnalyticsFarmScore.farm_id == farm_id,
            )
            .order_by(AnalyticsFarmScore.period_end.desc())
        )

    executive_score = float(score_item.score if score_item else 50.0)
    high_count = sum(1 for item in recommendations if item.priority == "high")
    status = "critical" if high_count >= 3 else "attention" if high_count else "stable"
    official_decision = (
        "Priorizar correções críticas antes de novos investimentos."
        if high_count
        else "Manter execução do plano e acompanhar metas."
    )

    return {
        "generated_at": datetime.now(timezone.utc),
        "farm_id": farm_id,
        "executive_score": executive_score,
        "status": status,
        "official_decision": official_decision,
        "strategy": [
            item.title for item in recommendations[:5]
        ] or ["Completar dados para gerar estratégia."],
        "recommendations": recommendations,
        "risks": [
            item.summary for item in recommendations if item.priority == "high"
        ],
        "opportunities": [
            item.summary for item in recommendations if item.priority != "high"
        ],
        "limitations": [
            "O motor atual é determinístico e explicável; não é um modelo treinado.",
            "Resultados dependem da qualidade e atualização dos dados.",
            "Clima e mercado usam valores fornecidos no contexto da requisição.",
            "Decisões clínicas e financeiras exigem revisão profissional.",
        ],
    }


def conversational_answer(
    *,
    area: str,
    question: str,
    recommendations: list[AtlasAiRecommendation],
) -> tuple[str, dict, float, list[str]]:
    if recommendations:
        top = recommendations[0]
        answer = (
            f"Análise Atlas ({area}): {top.summary}\n\n"
            f"Justificativa: {top.rationale}\n\n"
            "Próximas ações:\n- "
            + "\n- ".join(top.action_items)
        )
        payload = {
            "top_recommendation_id": top.id,
            "area": area,
            "priority": top.priority,
        }
        confidence = top.confidence
        sources = sorted(
            {
                evidence.get("source", "dados internos")
                for item in recommendations
                for evidence in item.evidence
            }
        )
    else:
        answer = (
            f"Não encontrei evidências suficientes para responder com segurança "
            f"sobre '{question}'. Atualize os dados do módulo {area} e tente novamente."
        )
        payload = {"area": area, "insufficient_data": True}
        confidence = 35
        sources = []

    return answer, payload, confidence, sources
