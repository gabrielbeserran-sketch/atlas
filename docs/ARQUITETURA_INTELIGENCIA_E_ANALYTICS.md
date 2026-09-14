# Arquitetura de Inteligência e Analytics — Atlas

Atualizado em 14/09/2026. Este documento define a única superfície de
inteligência disponível ao produtor e impede que nomes de motores, protótipos
ou famílias técnicas virem módulos concorrentes no menu.

## Decisão adotada

O produtor acessa **Análises** pelo menu. A tela abre a Central de
Inteligência Atlas, que organiza cinco capacidades sob o mesmo contexto de
fazenda:

| Capacidade | Onde aparece | Resultado para o produtor |
|---|---|---|
| Resumo | Aba `Resumo` | Situação consolidada e qualidade dos dados oficiais. |
| Diagnóstico | Aba `O que fazer` | Prioridades explicadas, evidências, confiança e limitações. |
| Análise por área | Aba `Por área` | Atalho para o módulo proprietário do dado. |
| Predição e cenários | Aba `Simular` | Comparação de alternativas antes de decidir. |
| Decisões | Aba `Decisões` | Registro e acompanhamento da decisão tomada. |

## Fronteiras obrigatórias

| Área | É responsável por | Não substitui |
|---|---|---|
| Campo | Registro e execução do trabalho da fazenda | Análise ou documento gerencial. |
| Análises | Interpretação, prioridade e cenário | Registro operacional ou exportação. |
| Relatórios | Consolidação, comparação e exportação | Registro e execução. |
| Consultoria | Apoio humano, contato e boletins | Decisão automática ou execução operacional. |

Copilot é uma ferramenta contextual da Central de Análises, não um item de
menu. Diagnóstico Inteligente, Inteligência Preditiva, BI e motores internos
seguem a mesma regra: são capacidades da Central ou recursos do módulo que
possui o dado, nunca um produto paralelo.

## Dono de cada dado

- Rebanho: acompanhamento, desempenho e manejo coletivo.
- Sanidade: protocolos, ocorrências e prioridades sanitárias.
- Reprodução: serviços, diagnóstico e planejamento reprodutivo.
- Nutrição: dieta, consumo, custo e integração com estoque.
- Estoque: entradas, validade, reposição e risco de falta.
- Financeiro: receitas, despesas, compromissos e resultado.
- Campo: piquetes, operações, equipe, clima e execução.

Análises apenas cruza esses dados e encaminha para a área adequada. Uma ação
crítica continua exigindo confirmação explícita.

## Próximas entregas autorizadas

1. Validar, em aparelho, o caminho `Análises → prioridade → módulo dono` e a
   volta para a Central, sem alterar o menu.
2. Consolidar os dados oficiais para que Resumo, prioridades e cenários usem
   o mesmo snapshot por fazenda.
3. Ligar decisões confirmadas à Agenda e às Anotações por referências, sem
   duplicar os serviços de cada módulo.
4. Manter telas e famílias técnicas fora da navegação de produção até haver
   contrato, utilidade operacional e teste de regressão.
