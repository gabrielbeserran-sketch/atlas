# Atlas V19.4 — área operacional explícita nos módulos

## Motivo
A V19.3 continha handlers e botões no código, porém o pacote foi empacotado com raiz `v192inspect/`, o que permitia que a pasta de trabalho antiga continuasse sendo executada. Além disso, as ações ficavam embutidas no cabeçalho e não havia um gate dedicado à presença de uma área operacional explícita na árvore principal.

## Correção
- Ações de criação/gerenciamento movidas para `_ModuleActionBar`, imediatamente abaixo do cabeçalho.
- Área sempre renderizada, independentemente de permissão; sem `*.write`, o botão criar fica desabilitado.
- Fluxos existentes preservados: Reprodução, Sanidade, Nutrição, Estoque e Financeiro.
- Após retorno do CRUD, snapshot oficial do backend é recarregado.
- Novo gate `audit_v19_4_explicit_module_action_area_static.py`.
- Empacotamento final obrigatório com raiz `Projetos Atlas/`.

## Rótulos visíveis
- Reprodução: Novo evento reprodutivo
- Sanidade: Novo evento sanitário
- Nutrição: Nova dieta
- Estoque: Novo produto
- Financeiro: Novo lançamento
