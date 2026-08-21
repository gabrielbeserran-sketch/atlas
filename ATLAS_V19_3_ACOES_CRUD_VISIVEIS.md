# Atlas V19.3 — Ações CRUD visíveis nos módulos canônicos

Data: 21/08/2026

## Causa da regressão
A consolidação V19/V19.2 trocou as telas operacionais por `AtlasLivestockModuleScreen` como porta canônica. A V19.2 adicionou uma barra separada de ações, mas o gate verificava apenas a presença de handlers/labels no código e não garantia que a ação estivesse renderizada na região sempre visível da tela. A validação visual real mostrou que o contrato operacional da tela anterior não estava preservado.

## Correção
- `Novo registro` passou para o próprio cabeçalho canônico, que sempre é renderizado.
- O botão permanece visível mesmo para perfis somente-leitura; nesse caso fica desabilitado e exibe explicação de permissão.
- `Gerenciar` também permanece visível no cabeçalho.
- Sanidade, Reprodução, Nutrição, Financeiro e Estoque continuam reutilizando seus fluxos/formulários existentes via `autoOpenCreate`.
- Ao retornar do CRUD, o snapshot oficial do backend é recarregado.

## Gate novo
`scripts/quality/audit_v19_3_visible_module_crud_actions_static.py`

O gate bloqueia regressões em que os handlers existam no código, mas o botão deixe de ser uma ação sempre renderizada no cabeçalho.
