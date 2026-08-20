# Atlas — Estabilização e homologação dos passos 1 a 14

Data da auditoria: 20/08/2026  
Baseline de entrada: estado do ZIP recebido, posterior ao commit V7 e contendo entregas V8–V18.  
Baseline promovida: `v18-stabilized`.

## Princípio usado

Nenhum arquivo foi alterado antes da inspeção da implementação existente e das dependências relacionadas. Correções foram aplicadas somente após falha objetiva de contrato, teste ou runtime. Alterações de regra pecuária não foram feitas para simplesmente satisfazer testes antigos.

## Resultado por passo

| Passo | Resultado | Evidência / observação |
|---|---|---|
| 1. Consolidar V18 | APROVADO | Manifesto promovido para `v18-stabilized`; 1.405 arquivos-fonte críticos inventariados; 23 arquivos protegidos no manifesto e 15 no lock Marco 5A. |
| 2. Gate funcional | APROVADO no que é executável neste ambiente | 28/28 auditores Python; 25/25 testes estáticos V7/V9/V10/V14/V17/escopo; 57/57 contratos Marco 6; `compileall` OK; 31 JSON raiz válidos. `flutter analyze` não pôde ser executado porque Flutter/Dart não estão instalados neste ambiente. |
| 3. Ambiente integrado | PARCIAL COMPROVADO | Backend FastAPI executado realmente em SQLite isolado. Docker/PostgreSQL/Redis/Flutter não existem no ambiente desta auditoria, então não foram marcados falsamente como executados. Contratos de infraestrutura local passaram. |
| 4. Homologação transacional | APROVADO no backend | Gate runtime integrado final: 38/38. Cobriu fazenda, lotes, animal, pesagem, movimento, reprodução, sanidade, nutrição, estoque, financeiro, agenda, reconciliação, inteligência e mídia. |
| 5. Vínculos cruzados | APROVADO | Sanidade → Estoque → Financeiro → Agenda comprovado; edição sanitária reconciliou estoque; exclusão reverteu estoque; Nutrição → Estoque e reversão comprovadas; Reprodução → Agenda comprovada. |
| 6. Persistência | APROVADO | Após reinício do TestClient sobre o mesmo banco, animal/peso, estoque e conteúdo de mídia permaneceram corretos. |
| 7. Segurança/autenticação | APROVADO com correção | Detectada e corrigida quebra de escopo por `farm_id`; empresa B agora recebe 404 ao tentar acessar fazenda da empresa A. Corrigido também `livestock.read` ausente do catálogo para perfis de leitura. Contratos V16/V17 passaram. |
| 8. Render + Supabase/PostgreSQL real | APROVADO ESTATICAMENTE / RUNTIME EXTERNO PENDENTE | Configurações e contratos de produção passaram. O ambiente de auditoria não conseguiu resolver o host Render e não possui acesso à infraestrutura privada, então cold start, migrations remotas e Storage Supabase real não são declarados como homologados. |
| 9. DEMO vs desenvolvimento/produção | APROVADO ESTATICAMENTE | Não foram encontrados hardcodes DEMO ativos no código principal durante a auditoria; configuração de produção permanece separada. |
| 10. Fazenda limpa | APROVADO | Criada do zero em banco isolado, seguida de lotes, animal e operações reais de homologação. |
| 11. Ciclo pecuário completo | APROVADO no backend | Animal percorreu cadastro → pesagem → mudança de lote → IATF → Agenda → Sanidade → Estoque/Financeiro → Nutrição → Reconciliação → Inteligência. |
| 12. Dashboard/inteligência | APROVADO backend + contrato UI | Alertas, resumo operacional, reconciliação e agenda inteligente responderam 200; V11/V14/V15 continuam cobertas pelos auditores. Execução visual Flutter depende do toolchain externo. |
| 13. Responsividade | APROVADO ESTATICAMENTE / DISPOSITIVO PENDENTE | Auditor V18 UX passou 9/9. Teste visual em telas físicas pequenas/grandes depende de Flutter e dispositivo. |
| 14. Anexos Android | APROVADO em contrato/backend / DISPOSITIVO PENDENTE | Contrato Android passou; antiga `MainActivity` foi removida; FileProvider/MethodChannel permaneceram na classe oficial; upload e download autenticado foram comprovados em runtime. Seleção/abertura nativa deve ser fumada em Android físico. |

## Falhas reais descobertas e corrigidas

1. `livestock.read` era exigida por Reconciliação/Inteligência, mas não existia no catálogo oficial de permissões. Perfis sem `*` podiam receber 403. A permissão foi catalogada e adicionada ao domínio de leitura pecuária.
2. `_farm_allowed` verificava apenas a carteira do membership e não confirmava empresa/tenant da fazenda. Um `farm_id` externo podia alcançar endpoints de inteligência. A função central agora consulta `Farm` por `id + company_id + tenant_id`, e todos os consumidores usam a versão com `db`.
3. `reproduction/summary` comparava datetime offset-naive com offset-aware, causando 500 em runtime SQLite. A comparação passou a normalizar para UTC. O mesmo risco foi eliminado nos alertas sanitários e de validade de estoque equivalentes.
4. Os handlers globais de exceção usavam `JSONResponse` com argumentos posicionais incompatíveis com a versão atual de Starlette. Todos foram convertidos para `status_code=` e `content=`. O fluxo de validação 422 foi comprovado no gate runtime.
5. Existia uma `MainActivity` Android antiga em `com.example.projeto_atlas`, paralela à oficial `br.com.projetoatlas.app`. O resíduo foi removido.
6. Existia `backend/alembic/reconcile.py`, arquivo legado que podia colidir com o namespace do pacote Alembic. Não havia consumo ativo; foi removido.
7. Auditores antigos ainda exigiam detalhes de implementações já substituídas (timeout local, `FileResponse` específico e textos/funções antigos da reconciliação). Foram atualizados somente depois de confirmar a proteção equivalente na arquitetura atual.

## Regressões permanentes adicionadas

Foi criado `scripts/quality/audit_v18_stabilization_static.py`, com 11 verificações para impedir retorno de: handlers posicionais quebrados, comparações de data sem normalização, permissão `livestock.read` ausente, escopo de fazenda sem empresa/tenant, chamada antiga de `_farm_allowed`, MainActivity legada e `backend/alembic/reconcile.py` legado.

## Evidência final de qualidade

- 28/28 scripts em `scripts/quality` aprovados.
- 25/25 testes estáticos de V7/V9/V10/V14/V17 + regressão de escopo aprovados.
- 57/57 testes de contratos Marco 6 aprovados.
- 38/38 verificações runtime integradas aprovadas em banco SQLite isolado.
- Compilação Python (`compileall`) aprovada.
- 31/31 JSON de raiz válidos.
- 11/11 verificações do novo auditor de estabilização aprovadas.
- Nenhum trailing whitespace foi introduzido nos arquivos diretamente alterados durante esta estabilização.

## Gates externos que não devem ser falsamente considerados aprovados

Para fechar 100% dos passos 2, 3, 8, 13 e 14 em infraestrutura final ainda é necessário executar, no computador/infra que possui essas ferramentas: Flutter/Dart (`flutter analyze`, testes e build), Docker/PostgreSQL/Redis, Render/Supabase reais e smoke em Android físico. O código e os contratos necessários foram preparados e auditados, mas ausência dessas ferramentas nesta sessão não foi convertida em aprovação artificial.

## Ordem de execução externa preservada

1. Docker/PostgreSQL + Redis.
2. Backend FastAPI e migrations.
3. Worker de backup, quando necessário.
4. Admin Portal, quando necessário.
5. App Flutter.
6. Android físico para o gate de anexos e responsividade.

A baseline `v18-stabilized` deve ser preservada até que esses gates externos sejam executados. Qualquer defeito encontrado neles deve ser corrigido em pacote e revalidado antes de iniciar nova funcionalidade.
