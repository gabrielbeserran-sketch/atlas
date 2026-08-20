# Atlas — V12 + V13 — Central de Alertas e Ações Recomendadas

## Objetivo

Transformar o motor de inteligência operacional da V10/V11 em um fluxo de trabalho utilizável pelo produtor.

## V12 — Central de Alertas

O Dashboard agora oferece **Ver todos os alertas**. A nova Central permite:

- visualizar todos os alertas da fazenda ativa;
- pesquisar por título, área, recomendação, código ou entidade;
- filtrar por criticidade;
- filtrar por área;
- ordenar por prioridade, prazo ou área;
- visualizar score e totais por criticidade;
- atualizar os dados diretamente da API.

## V13 — Ação recomendada

Cada alerta possui **Resolver**. O Atlas abre um guia com causa, recomendação e o módulo responsável. O botão de ação leva ao módulo de origem.

O alerta não é marcado como resolvido manualmente. Ele desaparece quando a condição real que o gerou deixa de existir. Isso evita esconder problemas sem corrigir o dado de origem.

## Integração

Ao retornar da Central, o Dashboard atualiza a inteligência para refletir alertas resolvidos no módulo de origem.

## Próximo marco

V14/V15: Agenda inteligente + indicadores executivos consolidados, seguida do gate funcional antes do Android.
