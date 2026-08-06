
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class AgentDefinition:
    code: str
    name: str
    specialty: str
    keywords: tuple[str, ...]
    description: str


DEFAULT_AGENTS = (
    AgentDefinition(
        code="general",
        name="Atlas Gestor",
        specialty="management",
        keywords=("fazenda", "gestão", "prioridade", "hoje", "plano"),
        description="Consolida informações de gestão e prioridades.",
    ),
    AgentDefinition(
        code="health",
        name="Atlas Sanidade",
        specialty="health",
        keywords=("vacina", "doença", "sanidade", "medicamento", "carência"),
        description="Analisa riscos e pendências sanitárias.",
    ),
    AgentDefinition(
        code="reproduction",
        name="Atlas Reprodução",
        specialty="reproduction",
        keywords=("iatf", "insemin", "prenhez", "reprodução", "cio"),
        description="Analisa indicadores e ações reprodutivas.",
    ),
    AgentDefinition(
        code="nutrition",
        name="Atlas Nutrição",
        specialty="nutrition",
        keywords=("dieta", "nutrição", "ração", "pastagem", "suplemento"),
        description="Analisa disponibilidade e riscos nutricionais.",
    ),
    AgentDefinition(
        code="finance",
        name="Atlas Financeiro",
        specialty="finance",
        keywords=("financeiro", "custo", "receita", "lucro", "caixa"),
        description="Analisa caixa, custos e impacto financeiro.",
    ),
    AgentDefinition(
        code="inventory",
        name="Atlas Estoque",
        specialty="inventory",
        keywords=("estoque", "produto", "insumo", "reposição", "mínimo"),
        description="Analisa níveis de estoque e risco de ruptura.",
    ),
    AgentDefinition(
        code="sustainability",
        name="Atlas Sustentabilidade",
        specialty="sustainability",
        keywords=("sustentabilidade", "água", "emissão", "solo", "ambiental"),
        description="Analisa riscos e ações ambientais.",
    ),
)


def select_agent(message: str, requested_specialty: str | None = None) -> AgentDefinition:
    normalized = message.lower()

    if requested_specialty:
        for agent in DEFAULT_AGENTS:
            if requested_specialty in {agent.code, agent.specialty}:
                return agent

    scored = []
    for agent in DEFAULT_AGENTS:
        score = sum(1 for keyword in agent.keywords if keyword in normalized)
        scored.append((score, agent))

    scored.sort(key=lambda item: item[0], reverse=True)
    return scored[0][1] if scored and scored[0][0] > 0 else DEFAULT_AGENTS[0]
