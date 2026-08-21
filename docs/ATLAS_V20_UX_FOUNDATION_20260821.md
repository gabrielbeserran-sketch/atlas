# Atlas V20 — Fundação de Experiência e Arquitetura de Informação

Data: 21/08/2026
Base: V19.5 (216fa52)

## Objetivo
Reduzir a complexidade percebida sem remover capacidade técnica, preservando fazenda ativa, permissões, serviços, endpoints e integrações.

## Alterações consolidadas
- Centrais de Sanidade, Reprodução, Nutrição, Financeiro e Estoque passam a ser renderizadas dentro do workspace autenticado; no desktop a barra lateral permanece visível.
- Dashboard e atalhos internos selecionam o mesmo destino no shell, sem abrir uma segunda árvore de navegação.
- Menu lateral separa módulos produtivos, `Mais recursos` e `Administração`.
- Central do Animal ganha ações rápidas no Resumo: Nova pesagem, Sanidade, Reprodução, Manejo, Foto e Documento.
- `Timeline` passa a ser apresentada como `Histórico`; `Sanidade+`, `Reprodução+` e `Pesagens+` perdem o sufixo técnico.
- Rótulos `Pacote`, `Fase`, `Sprint` e `Marco` foram removidos dos arquivos de apresentação.
- Seletores que exibiam `packageLabel` passam a usar o título funcional do recurso.
- Sustentabilidade deixa de mostrar `Pacote 181–190` e `Fase 29` na interface.
- Avisos de maturidade deixam de citar versão V1 e passam a usar linguagem de produto.

## Não alterado
- Endpoints/backend.
- Banco e migrações.
- Regras pecuárias.
- Serviços de persistência.
- Permissões de backend.
- IDs de fazenda/animal.
- Integrações Estoque/Financeiro/Agenda/Timeline/Alertas.

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
- V20 UX foundation: 17/17
- `git diff --check`: aprovado
- Python compileall backend/scripts: aprovado

## Gate V20
`scripts/quality/audit_v20_ux_foundation_static.py`

O gate bloqueia:
- retorno de push operacional fora do shell;
- perda das cinco centrais canônicas no workspace;
- desaparecimento das ações rápidas principais do animal;
- retorno de Timeline/Sanidade+/Reprodução+/Pesagens+;
- textos `Pacote N`, `Fase N`, `Sprint N` ou `Marco N` em arquivos de apresentação.

## Validação final no Windows
O ambiente de empacotamento não possui Flutter SDK. Portanto `flutter analyze`, `flutter test`, build Windows e inspeção renderizada devem ser executados no Windows antes de promover esta versão a baseline definitiva.
