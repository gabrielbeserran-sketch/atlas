# Atlas V20.2 — Consistência Operacional e Hierarquia Visual

Data: 21/08/2026
Base funcional: V20.1

## Objetivo
Padronizar a experiência dos módulos de uso diário sem alterar regras pecuárias, persistência ou contratos de backend.

## Alterações

### Painel executivo do animal
- Score mantém o mesmo cálculo.
- Valor numérico fica sozinho dentro do indicador circular.
- Classificação (`Excelente`, `Bom`, `Atenção`, `Crítico`) fica em selo abaixo do círculo.
- Indicador usa 96x96 e espaçamento fixo para não sobrepor texto em desktop/mobile.

### Workspace operacional
Sanidade, Reprodução, Nutrição, Financeiro, Estoque e Agenda receberam `embedded`.
- Dentro do `AtlasHomeShell`: não desenham uma segunda AppBar.
- Fora do shell: continuam com AppBar própria.
- O menu e a fazenda ativa permanecem visualmente estáveis no desktop.

### Recuperação de falha
Criado `AtlasLoadErrorState` em `lib/core/widgets/atlas_operational_feedback.dart`.
- mensagem simples;
- sem expor stack/exception ao trabalhador;
- botão `Tentar novamente`;
- aplicado a Sanidade, Reprodução, Nutrição, Estoque, Financeiro e Agenda.

## Não alterado
- cálculo do score;
- backend/endpoints;
- migrations e banco;
- regras de negócio;
- integrações Sanidade/Estoque/Financeiro/Agenda;
- IDs de fazenda/animal;
- autorização do backend.

## Gates
- V19.5 navegação direta: 37/37
- V20 UX foundation: 17/17
- V20.1 linguagem + genealogia: 18/18
- V20.2 consistência operacional: 23/23
- ATLAS BASELINE STATIC AUDIT: OK
- ATLAS FULL PROJECT AUDIT: OK
- Backend routes: 511, duplicadas: 0
- Alembic: 1 head
- Python compileall: OK
- git diff --check: OK

## Gate novo
`scripts/quality/audit_v20_2_operational_consistency_static.py`

## Política de empacotamento corrigida
O ZIP V20.2 não inclui `.git`, `.venv`, `.dart_tool` ou `build`.
A ausência de `.git` é intencional: ao substituir os fontes, o histórico Git da pasta local do usuário permanece intacto. Isso evita que um pacote de código rebaixe ou bifurque `origin/master`.
