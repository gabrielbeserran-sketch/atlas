# Atlas V19.2 — CRUD operacional exposto nos módulos canônicos

Data: 21/08/2026

## Objetivo
Restaurar as ações de criação e gerenciamento nos módulos canônicos sem recriar CRUD, persistência ou endpoints paralelos.

## Módulos cobertos
- Sanidade — Novo evento sanitário / Gerenciar sanidade.
- Reprodução — Novo evento reprodutivo / Gerenciar reprodução.
- Nutrição — Nova dieta / Gerenciar dietas.
- Financeiro — Novo lançamento / Gerenciar financeiro.
- Estoque — Novo produto / Gerenciar estoque.

## Arquitetura preservada
A tela `AtlasLivestockModuleScreen` continua exibindo métricas e dados oficiais do backend. As ações operacionais reutilizam as telas e serviços já existentes de cada domínio. Ao retornar de qualquer criação/edição, o snapshot canônico é recarregado.

## Segurança
A criação só é exposta quando a sessão possui a permissão de escrita correspondente: `health.write`, `reproduction.write`, `nutrition.write`, `finance.write` ou `inventory.write`. Perfis apenas de leitura continuam podendo abrir a gestão em modo compatível com suas permissões.

## Prevenção de regressão
Criado `scripts/quality/audit_v19_2_module_crud_actions_static.py`, que exige as cinco ações de criação, as cinco permissões, o reaproveitamento dos fluxos existentes, abertura de gerenciamento e recarga do snapshot oficial.

## Gates executados
- V8: 17/17
- V9: 9/9
- V10: 15/15
- V11: 13/13
- V12/V13: 14/14
- V14/V15: 16/16
- V16/V17: 17/17
- V18 UX: 9/9
- V18 estabilização: 11/11
- V19 navegação canônica: 38/38
- V19.2 CRUD canônico: 30/30
- Atlas baseline static audit: OK
- Atlas full project audit: OK

A compilação Flutter final deve ser executada no Windows do projeto, onde o SDK Flutter está disponível.
