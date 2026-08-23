# Atlas Pós-V21 — Pacote 3: Centrais gerais consolidadas

## Escopo desta entrega
Primeira consolidação das centrais de Sanidade, Reprodução e Nutrição.

A regra de produto passa a ser:
1. Como está?
2. O que exige atenção?
3. O que posso fazer agora?

## Sanidade
A Central de Sanidade mantém o histórico e as ações existentes e passa a
apresentar uma leitura decisória baseada nos dados oficiais já carregados:
quarentena, carências, retornos, ocorrências, histórico e cobertura dos animais.

Quando a tela está vinculada à fazenda ativa, `Manejo coletivo` abre diretamente
o motor transacional criado no Pacote 2. Não existe nova persistência.

## Reprodução
Além do histórico, passam a ficar visíveis taxa de prenhez, taxa de concepção,
inseminações, fêmeas sem histórico e previsões/retornos que precisam de revisão.
`Manejo coletivo` usa o mesmo motor transacional oficial do Pacote 2.

## Nutrição
A central cruza:
- dietas e animais cobertos;
- GMD médio;
- dieta abaixo da meta de GMD;
- dietas sem desempenho observado;
- composição detalhada;
- integração de baixa com Estoque.

Não foi criado armazenamento paralelo: a leitura usa `NutritionPlanData` e os
serviços já existentes.

## Arquitetura
Foi criado apenas um widget compartilhado de apresentação:
`AtlasModuleDecisionPanel`.

Ele não possui regra de negócio nem persistência. As regras permanecem nos
módulos donos.

## Próxima consolidação
O próximo pacote deve aplicar a mesma arquitetura a:
- Campo e Pastagens;
- Estoque/Suprimentos;
- Financeiro;
- Inteligência/Relatórios;
- Operações e Equipe.
