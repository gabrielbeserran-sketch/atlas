# Atlas V20.10 — Auditoria UX integrada

Base: V20.9.

## Superfícies auditadas antes da alteração
- Shell/menu global
- Fazenda e Fazenda ativa
- Rebanho
- Central do Animal
- Pesagem
- Sanidade
- Reprodução
- Agenda
- Estoque
- Financeiro
- retorno/refresh e identidade de fazenda

## Correções consolidadas
1. Rebanho agora usa o mesmo gate explícito de Fazenda ativa já adotado por Sanidade, Reprodução, Nutrição, Financeiro, Estoque e Agenda.
2. Tentativa de abrir um módulo dependente sem Fazenda ativa redireciona para Fazendas e explica o que fazer, em vez de entregar uma tela morta.
3. Navegação originada no Dashboard passa pelo mesmo contrato de Fazenda ativa do menu.
4. O estado sem Fazenda foi unificado e explica que animais, registros e indicadores pertencem à Fazenda ativa.
5. Agenda deixou de possuir uma mensagem paralela de ausência de Fazenda.
6. A chave de reconstrução `módulo:farmId` foi preservada para impedir dados visuais da Fazenda anterior após troca.
7. O detalhe canônico da Fazenda foi preservado. Durante a auditoria, uma tentativa de ir diretamente de Fazendas para Rebanho conflitou com o contrato existente; o gate completo detectou o conflito e a mudança foi revertida antes do pacote final.
8. Central do Animal, barras operacionais, persistência, IDs e integrações existentes não foram reconstruídos.

## Riscos prevenidos
- Null de Fazenda ativa no Rebanho.
- Módulo aberto sem contexto territorial.
- Dashboard contornando validação de Fazenda.
- Estado visual da Fazenda anterior após troca.
- Regressão do detalhe da Fazenda.
- Criação de segundo fluxo concorrente de navegação.

## Gates finais
- V20.7: 32/32
- V20.8: 21/21
- V20.9: 26/26
- V20.10: 17/17
- Baseline static audit: OK
- Full project audit: OK
- Backend routes: 511
- Duplicate routes: 0
- Alembic heads: 1 (`20260821_0041`)

## Próximo passo
V21 não deve adicionar uma nova arquitetura. É a homologação da baseline UX: executar Flutter Analyze/Test/Build no Windows, smoke test visual e funcional dos fluxos críticos e somente então congelar a versão como baseline.
