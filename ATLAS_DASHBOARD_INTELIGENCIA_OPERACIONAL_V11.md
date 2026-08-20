# Atlas — V11 — Dashboard de Inteligência Operacional

A V11 conecta os endpoints de inteligência operacional da V10 diretamente ao Dashboard Flutter.

## Entregas

- score operacional 0–100 da fazenda ativa;
- nível operacional;
- contagem de alertas e alertas críticos/altos;
- três ações prioritárias;
- clique por área levando ao módulo correspondente;
- atualização junto com o pull-to-refresh do Dashboard;
- falha do motor de inteligência não impede o restante do Dashboard de abrir.

## Fonte dos dados

- `/livestock/intelligence/operational-summary`
- `/livestock/intelligence/operational-alerts`

O Dashboard seleciona a fazenda ativa persistida pela sessão e usa a primeira fazenda da carteira apenas como fallback.
