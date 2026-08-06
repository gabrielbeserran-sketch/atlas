
# Fase 46 — Analytics e BI Avançado

## Pacotes
- 351: Data Warehouse Atlas;
- 352: Cubos analíticos;
- 353: Dashboards executivos;
- 354: KPIs configuráveis;
- 355: Benchmark entre fazendas;
- 356: Indicadores históricos;
- 357: Comparativos ano a ano;
- 358: Motor de metas;
- 359: Score global da fazenda;
- 360: BI Enterprise integrado.

## Entrega
- tabelas analíticas separadas das tabelas operacionais;
- snapshots mensais;
- dimensões e fontes rastreáveis;
- KPIs configuráveis;
- metas e recalculadora;
- ranking e percentis;
- séries históricas;
- score global por componentes;
- API de dashboard;
- tela Flutter de BI;
- migração Alembic;
- testes estruturais e documentação.

## Limite verdadeiro
A fase cria o Data Warehouse dentro do PostgreSQL operacional. Para grandes
volumes, recomenda-se posteriormente separar o banco analítico, automatizar
o ETL com agendador e incluir materialized views ou ClickHouse/BigQuery.
