# Atlas Pós-V21 — Pacote 1: Central do Animal

## Base
Baseline V21 técnica selada e homologada.

## Alterações funcionais
- Central do Animal reduzida para sete destinos: Resumo, Histórico, Desempenho, Sanidade, Reprodução, Genealogia e Arquivos.
- Removidos da navegação da Central: Manejo, Agenda, Pendências, Análises isoladas e Mais recursos.
- Pesagens + Zootecnia são consolidadas em Desempenho.
- Fotos + Documentos são consolidados em Arquivos.
- Sanidade deixa de abrir a tela intermediária com botão “Abrir sanidade”: a Central mostra diretamente situação, indicadores, ações e eventos recentes.
- Reprodução deixa de abrir a tela intermediária com botão “Abrir reprodução”: a Central mostra diretamente situação, indicadores, ações e eventos recentes.
- Desempenho deixa de depender da antiga tela intermediária de pesagens inteligentes.
- Os módulos avançados históricos continuam no código como camada de migração, mas não ficam expostos na Central do Animal.

## Persistência e integração
- Nenhum endpoint foi removido ou renomeado.
- Nenhuma migration foi criada.
- `farmId`, `animalId`, serviços canônicos de Pesagem, Sanidade, Reprodução, Timeline, Fotos e Documentos foram preservados.
- Sanidade passa a manter os `AnimalHealthData` carregados no estado da própria Central para renderização direta.

## Preparação de “Realizar manejo”
Foi criado o contrato de domínio `FarmHandlingDraft`, ainda não exposto no menu. Ele define:
- escopo obrigatório por Fazenda;
- seleção por lote inteiro;
- intervalo de brincos;
- seleção manual;
- RFID futuro;
- ações de venda/saída, movimentação de lote, pesagem, sanidade, reprodução e mudança de categoria.

A interface de manejo coletivo só será exposta quando a execução transacional e a seleção de animais estiverem implementadas; não foi criada uma tela-placeholder.

## Gates executados no ambiente de empacotamento
- Pós-V21 Pacote 1: 27/27
- V20.6: 16/16
- V20.7: 32/32
- V20.8: 29/29
- V20.9: 26/26
- V20.10: 17/17
- V21.2 Dart Hygiene: OK
- V21.3 Test Contract: OK
- V21.4 Smoke Resilience: 15/15
- V21.5 PowerShell Hygiene: OK
- V21.6 Critical Flows: 14/14
- Windows Build Lock: 6/6
- Baseline Static Audit: OK
- Full Project Audit: OK
- Python compileall: OK

## Gate obrigatório no Windows
Executar `scripts\quality\run_post_v21_package1_homologation.ps1` para rodar Flutter analyze/test/build, smoke Render/Supabase e todos os gates herdados.
