# Atlas V20.3 — Descoberta Operacional e Redução de Cliques

Base: V20.2.

## Objetivo
Tornar estados vazios, buscas e ações cotidianas previsíveis para usuários de campo, sem alterar regras de negócio, persistência, endpoints ou integrações.

## Mudanças
- Rebanho: vazio de lote oferece `Novo lote`; vazio de animais oferece `Novo animal`; filtros sem resultado oferecem `Limpar filtros`.
- Sanidade e Reprodução: busca sem resultado oferece `Limpar busca`; ausência de animais explica claramente que o cadastro deve ser feito no Rebanho.
- Nutrição: vazio real oferece `Nova dieta`; filtros sem resultado oferecem `Limpar filtros`.
- Estoque: vazio real oferece `Novo produto`; filtros sem resultado oferecem `Limpar filtros`.
- Financeiro: vazio real oferece `Novo lançamento`; filtro sem resultado oferece `Limpar filtro`.
- Agenda: vazio real oferece `Novo compromisso`; pesquisa/filtro sem resultado oferece `Limpar filtros`.
- Central do Animal: navegação principal reorganizada em `Acesso rápido` e `Mais informações`.
- Central do Animal: `Nova pesagem` agora abre diretamente o formulário de nova pesagem, em vez de uma tela de inteligência intermediária.

## Não alterado
- Backend e rotas.
- Banco/migrações.
- Regras pecuárias.
- Autoridade de dados e caches.
- Integrações Sanidade→Estoque→Financeiro, Nutrição→Estoque, Agenda, Histórico e Inteligência.

## Gate
`scripts/quality/audit_v20_3_operational_discovery_static.py`

Resultado local estático: 16/16.

## Regressão executada
- ATLAS BASELINE STATIC AUDIT: OK.
- ATLAS FULL PROJECT AUDIT: OK.
- V19.5: 37/37.
- V20: 17/17.
- V20.1: 18/18.
- V20.2: 23/23.
- V20.3: 16/16.
- Backend: 511 rotas, 0 duplicadas, Alembic com 1 head.

## Validação obrigatória no Windows
O ambiente de empacotamento não possui Flutter SDK. Antes de promover a V20.3 a baseline, executar `flutter pub get`, `flutter analyze`, `flutter test` e `flutter build windows --debug` no Windows.
