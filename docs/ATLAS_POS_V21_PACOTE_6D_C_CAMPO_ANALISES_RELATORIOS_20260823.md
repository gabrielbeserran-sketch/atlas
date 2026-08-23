# Atlas Pós-V21 — Pacote 6D-C

## Fronteira funcional consolidada

### Campo
Responsável por executar e acompanhar o trabalho da fazenda:
- piquetes e ocupação;
- operações;
- responsáveis/equipe;
- ferramentas de campo;
- prioridades operacionais.

Campo não substitui Análises nem Relatórios.

### Análises
Responsável por interpretar dados oficiais:
- situação consolidada;
- recomendações;
- leitura por área;
- simulação de cenários;
- decisões;
- abertura direta do módulo dono;
- ligação com Relatórios.

Análises não cria fatos operacionais nem substitui a exportação formal.

### Relatórios
Responsável por consolidar, comparar, acompanhar e exportar:
- filtros por fazenda;
- filtros por período;
- resumo consolidado;
- comparações;
- ações gerenciais;
- PDF;
- Excel.

Relatórios não vira um segundo módulo de simulação e não substitui a execução
diária dos módulos.

## Arquitetura

Foi adicionada uma política central:
- `moduleResponsibility`;
- `moduleDoesNotReplace`.

Foi criado:
- `AtlasModuleRoleCard`.

As três áreas também usam `AtlasModuleWorkspaceGuide`, mantendo a experiência
padronizada com os módulos já consolidados no 6D-A e 6D-B.

## Backend e banco

Nenhuma alteração de backend, banco ou migration foi necessária no Pacote 6D-C.
