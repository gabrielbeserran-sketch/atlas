
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from .context_builder import build_farm_context
from .knowledge import retrieve_documents
from .registry import select_agent


@dataclass
class OrchestratorResult:
    answer: str
    agent_code: str
    confidence_percent: float
    evidence: list[str]
    limitations: list[str]
    recommendation: dict | None


class AtlasAiOrchestrator:
    def execute(
        self,
        db: Session,
        *,
        company_id: str,
        farm_id: str | None,
        message: str,
        requested_specialty: str | None = None,
    ) -> OrchestratorResult:
        agent = select_agent(message, requested_specialty)
        context = build_farm_context(
            db,
            company_id=company_id,
            farm_id=farm_id,
        )
        documents = retrieve_documents(
            db,
            company_id=company_id,
            farm_id=farm_id,
            query=message,
        )

        evidence = [
            f"Animais cadastrados: {context.get('animals', 0)}",
            f"Alertas ativos: {context.get('active_alerts', 0)}",
            f"Dispositivos IoT: {context.get('iot_devices', 0)}",
            f"Predições ML registradas: {context.get('ml_predictions', 0)}",
            f"Faturas em aberto: {context.get('open_invoices', 0)}",
        ]

        if documents:
            evidence.extend(
                f"Documento: {document.title}"
                for document in documents[:3]
            )

        confidence = 55.0
        confidence += min(20.0, context.get("animals", 0) / 10)
        confidence += min(10.0, len(documents) * 2)
        confidence = min(92.0, round(confidence, 2))

        answer = (
            f"O agente {agent.name} analisou o contexto disponível. "
            f"A fazenda possui {context.get('animals', 0)} animais cadastrados, "
            f"{context.get('active_alerts', 0)} alertas ativos e "
            f"{context.get('iot_devices', 0)} dispositivos IoT. "
            "A recomendação deve ser validada com os registros operacionais "
            "e com o profissional responsável antes da execução."
        )

        recommendation = None
        if context.get("active_alerts", 0) > 0:
            recommendation = {
                "title": "Revisar alertas ativos",
                "description": (
                    "Existem alertas pendentes que podem exigir ação operacional."
                ),
                "priority": "high",
                "confidence_percent": confidence,
                "reasoning": evidence,
                "actions": [
                    "Abrir a Central em Tempo Real.",
                    "Classificar os alertas por severidade.",
                    "Atribuir responsável e prazo.",
                ],
            }
        elif agent.code == "general":
            recommendation = {
                "title": "Executar revisão gerencial diária",
                "description": (
                    "Consolidar indicadores e definir as três prioridades do dia."
                ),
                "priority": "medium",
                "confidence_percent": confidence,
                "reasoning": evidence,
                "actions": [
                    "Revisar sanidade.",
                    "Revisar reprodução.",
                    "Revisar estoque e financeiro.",
                ],
            }

        limitations = [
            "O motor desta fase é determinístico e explicável.",
            "Não há chamada automática a um LLM externo.",
            "A qualidade depende dos registros disponíveis no Atlas.",
        ]

        return OrchestratorResult(
            answer=answer,
            agent_code=agent.code,
            confidence_percent=confidence,
            evidence=evidence,
            limitations=limitations,
            recommendation=recommendation,
        )


def build_plan_items(horizon: str, context: dict) -> list[dict]:
    base = [
        {
            "position": 1,
            "title": "Revisar alertas críticos",
            "priority": "high" if context.get("active_alerts", 0) else "medium",
            "source": "realtime",
        },
        {
            "position": 2,
            "title": "Revisar indicadores do rebanho",
            "priority": "medium",
            "source": "animal",
        },
        {
            "position": 3,
            "title": "Conferir estoque e compromissos financeiros",
            "priority": "medium",
            "source": "commercial",
        },
    ]

    if horizon == "weekly":
        base.append(
            {
                "position": 4,
                "title": "Reunião semanal de gestão",
                "priority": "medium",
                "source": "management",
            }
        )
    elif horizon == "monthly":
        base.extend(
            [
                {
                    "position": 4,
                    "title": "Fechamento técnico e financeiro",
                    "priority": "high",
                    "source": "management",
                },
                {
                    "position": 5,
                    "title": "Atualizar metas e estratégia",
                    "priority": "medium",
                    "source": "executive",
                },
            ]
        )

    return base
