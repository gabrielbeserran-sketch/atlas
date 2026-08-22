# Atlas V21.6 — contratos automáticos dos 14 fluxos críticos

A V21.5 passou o smoke Render/Supabase com 13 PASS, 0 WARN e 0 FAIL.

A V21.6 não altera regras de negócio, banco, endpoints ou persistência. Ela adiciona dois níveis de prevenção:
- gate Python antes da homologação;
- 14 testes Dart executados dentro do `flutter test`.

Os contratos cobrem Login, Dashboard, Fazendas, troca de Fazenda, Rebanho, Central do Animal, Genealogia, Pesagem, Sanidade, Reprodução, Agenda, Estoque/Nutrição e Financeiro.

A inspeção humana fica restrita ao que testes de código não conseguem provar: sobreposição visual, legibilidade, clareza e fluidez.
