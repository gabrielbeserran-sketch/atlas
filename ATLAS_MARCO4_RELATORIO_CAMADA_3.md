# Projeto Atlas — Marco 4C: classificação das features avançadas

Data da consolidação: 2026-08-14.

## Objetivo

Separar explicitamente os módulos oficiais da V1 das funcionalidades avançadas ainda locais, evitando que persistência local experimental seja confundida com fonte oficial dos dados pecuários.

## Resultado

- 98 componentes locais avançados classificados.
- 69 raízes funcionais distintas.
- 85 componentes classificados como **avançado em validação**.
- 13 componentes classificados como **ferramenta interna**.
- 0 componentes locais avançados dentro das raízes oficiais dos CRUDs V1.
- Digital Twin permanece permitido somente porque o estado **Modo demonstrativo** é explícito na interface.
- Navegação principal passou a carregar maturidade explícita para módulos avançados e ferramentas internas.

## Regra arquitetural

Os módulos oficiais de Fazenda, Rebanho, Sanidade, Reprodução, Nutrição, Financeiro, Estoque e Agenda continuam sendo a autoridade operacional V1. Features avançadas podem consumir ou derivar dados, mas não podem substituir silenciosamente a persistência oficial enquanto estiverem classificadas como locais/em validação.

## Navegação

As rotas principais foram separadas em:

- `AtlasRouteMaturity.v1Core`: módulos operacionais da V1.
- `AtlasRouteMaturity.advancedValidation`: Inteligência, Precision Hub, Enterprise, SaaS e Dados.
- `AtlasRouteMaturity.internalTool`: Segurança, Qualidade, Prontidão, Releases, Comercial, Piloto, Publicação e Escala.

Rotas não-V1 exibem aviso persistente de maturidade para impedir que dados locais ou experimentais sejam interpretados como produção.

## Quality Gate

Foi adicionada a 12ª etapa:

`atlas_marco4_advanced_feature_classification.py`

Ela falha se:

1. a quantidade classificada deixar de corresponder ao inventário avançado atual;
2. um componente avançado local entrar em uma raiz oficial V1;
3. uma rota avançada/interna perder sua identificação de maturidade;
4. o Digital Twin voltar a apresentar demonstração sem identificação explícita.

## Próxima camada

Marco 4D: fechamento funcional da auditoria, verificando ações/botões, permissões, escopo de Fazenda/tenant, persistência e cobertura dos módulos V1 antes de encerrar o Marco 4.
