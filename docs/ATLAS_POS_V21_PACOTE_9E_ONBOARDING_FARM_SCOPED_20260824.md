# Atlas Pós-V21 — Pacote 9E: Implantação realmente isolada por fazenda

## Baseline

Pacote 9D publicado em produção no commit `d6e1b9f`.

## Lacuna encontrada

O 9D tornou quatro etapas verificáveis por fazenda, mas o passo manual `initial_training` ainda era armazenado no registro legado `onboarding_progress`, que possuía `company_id` único. Assim, marcar treinamento em uma fazenda podia aparecer como concluído nas demais fazendas da mesma empresa.

## Correção

A migration `20260824_0046` adiciona `farm_id` a `onboarding_progress`, remove a unicidade exclusivamente por empresa e cria unicidade composta `company_id + farm_id`.

O estado legado é expandido para as fazendas existentes, preservando a confirmação de treinamento. Empresas ainda sem fazenda mantêm temporariamente um registro legado sem `farm_id`; o backend o vincula à primeira fazenda utilizada.

A API passa a ler e gravar o onboarding por `company_id + farm_id`, mantendo o isolamento de fazenda já exigido pelos demais dados operacionais.

## Garantias

- treinamento da Fazenda A não altera a Fazenda B;
- quatro evidências automáticas continuam derivadas das fontes oficiais;
- apenas `initial_training` continua manual;
- registros legados são preservados durante a migração;
- endpoint de readiness prova a existência da coluna `farm_id` em produção.

## Migration

`0045 -> 0046`
