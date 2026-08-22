# Atlas V20.8 — Central do Animal final

Base: V20.7

## Objetivo
Fazer a Central do Animal responder primeiro às perguntas de campo:
1. Quem é este animal?
2. Como ele está agora?
3. O que aconteceu com ele?
4. O que preciso registrar ou acompanhar?

## Mudanças
- Resumo passou a abrir com uma faixa de situação atual: situação, lote, idade, peso, reprodução e quantidade de registros históricos.
- Ações do dia ficaram explícitas no Resumo:
  - Nova pesagem
  - Novo evento sanitário
  - Novo evento reprodutivo
  - Movimentações
  - Fotos
  - Documentos
- A navegação principal foi mantida em duas camadas funcionais:
  - trabalho: Resumo, Histórico, Manejo, Sanidade, Reprodução, Pesagens;
  - informações: Zootecnia, Genealogia, Fotos, Documentos, Nutrição e Análises.
- A antiga faixa `Rotina e acompanhamento` foi reduzida para `Hoje e pendências`, contendo apenas Agenda e Pendências.
- Validação, Integração, Fazenda e Empresa deixaram de competir com a rotina e foram movidas para `Mais recursos`.
- O catálogo avançado ganhou filtros por assunto:
  - Animal e manejo
  - Fazenda e ambiente
  - Gestão
  - Análises
  - Tecnologia de campo
  - Outros
- 30 ferramentas claramente técnicas/de plataforma (Backend, PostgreSQL, APIs, MFA, testes, publicação etc.) deixam de aparecer dentro da Central do Animal. Elas continuam pertencendo às áreas administrativas globais do Atlas.
- A navegação da Central passou a ser responsiva: 6 colunas em desktop amplo, 3 em largura intermediária, 2 em tablet e 1 em telas estreitas.
- Status do animal passa sempre pelo vocabulário `AtlasUiText`, inclusive para determinar visualmente se está Ativo.
- Nenhum endpoint, DTO, banco, migration, cálculo pecuário ou serviço de persistência foi alterado.

## Métricas da reorganização
- Enum técnico preservado: 285 seções.
- Navegação principal: 6 + 6 + 2 destinos.
- Recursos avançados catalogados: 271.
- Ferramentas técnicas removidas da Central do Animal: 30.
- Recursos especializados mantidos e pesquisáveis: 241.

## Gates
- V8: 17/17
- V9: 9/9
- V10: 15/15
- V11: 13/13
- V12/V13: 14/14
- V14/V15: 16/16
- V16/V17: 17/17
- V18 UX: 9/9
- V18 estabilização: 11/11
- V19.5: 37/37
- V20: 17/17
- V20.1: 18/18
- V20.2: 23/23
- V20.3: 16/16
- V20.4: 21/21
- V20.5: 253/253
- V20.6: 16/16
- V20.7: 32/32
- V20.8: 21/21
- Baseline static audit: OK
- Full project audit: OK
- Backend routes: 511
- Duplicate routes: 0
- Alembic heads: 1 (`20260821_0041`)
- Python compileall: OK

## Validação Windows
O ambiente de empacotamento não possui Flutter SDK. Executar:
- flutter pub get
- flutter analyze
- flutter test
- flutter build windows --debug
- flutter run contra Render/Supabase

A versão só deve ser promovida à baseline definitiva após esses gates e inspeção visual.
