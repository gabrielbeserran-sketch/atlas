# Atlas V20.1 — Linguagem, codificação e genealogia canônica

Data: 21/08/2026
Base: V20 UX (`a0f2763`)

## Problemas corrigidos

### 1. Textos com `Ã§`, `Ã£`, `Ã©` e símbolos semelhantes
Causa identificada em duas camadas:
- respostas e dados históricos precisavam de normalização UTF-8 defensiva;
- o seed PowerShell podia ser interpretado pelo Windows PowerShell com charset inadequado quando não havia BOM UTF-8.

Correção:
- `AtlasHttpClient` passa a decodificar `bodyBytes` explicitamente em UTF-8;
- `AtlasTextNormalizer` repara, de forma conservadora, mojibake já persistido;
- `AtlasUiText` centraliza rótulos de status e categorias;
- Nutrição e Estoque normalizam também conteúdo vindo de cache local;
- Relatórios agregam categorias já apresentadas em português;
- status exibidos em superfícies avançadas passam pelo mesmo vocabulário;
- `scripts/dev/seed_demo_production.ps1` possui exatamente um BOM UTF-8.

### 2. Genealogia dizendo que animal ativo não existe
Causa:
- Central do Animal usa IDs de `livestock_animals`;
- genealogia chamava o endpoint legado `/animals/{id}/genealogy`, cuja autoridade é `EntityState`;
- portanto um animal válido do Rebanho podia retornar 404 no domínio legado.

Correção:
- nova rota canônica `GET /api/v1/livestock/animals/{animal_id}/genealogy`;
- o Flutter passa a usar essa rota;
- genealogia aceita `mother_id`/`father_id` e também `mother_tag`/`father_tag` legados;
- isolamento por company/tenant/farm permanece preservado.

## Próximo passo de UX incorporado
- vocabulário central: `registered -> Registrado`, `active -> Ativo`, `pending -> Pendente` etc.;
- categorias: `health -> Sanidade`, `nutrition -> Nutrição`, `maintenance -> Manutenção` etc.;
- tela de Relatórios não mistura mais categorias inglesas e portuguesas quando os códigos representam o mesmo domínio.

## Gates
- V8 17/17
- V9 9/9
- V10 15/15
- V11 13/13
- V12/V13 14/14
- V14/V15 16/16
- V16/V17 17/17
- V18 UX 9/9
- V18 estabilização 11/11
- V19 30/30
- V19.2 30/30
- V19.3 38/38
- V19.4 14/14
- V19.5 37/37
- V20 UX Foundation 17/17
- V20.1 Text + Genealogy 18/18
- Atlas baseline static audit: OK
- Atlas full project audit: OK
- rotas backend: 511; duplicadas: 0
- Alembic: 1 head
- `git diff --check`: OK
- Python compileall/py_compile: OK

## Testes de runtime pendentes do ambiente Windows/Docker
O ambiente de empacotamento não possui Flutter SDK nem as dependências Python completas (`python-jose`/`passlib`), então devem ser executados antes da promoção definitiva:
- `flutter analyze`
- `flutter test`
- `flutter build windows --debug`
- `pytest backend/tests/test_v20_livestock_genealogy.py` dentro do ambiente backend completo/Docker
- deploy Render, pois a genealogia adiciona uma rota backend nova.
