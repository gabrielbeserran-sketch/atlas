# Atlas V20.4 — Integridade de Texto e Consistência de Formulários

Data: 21/08/2026
Base: V20.3

## Objetivos
1. Eliminar definitivamente mojibake visível (`VermifugaÃ§Ã£o`, `VacinaÃ§Ã£o`, `HomologaÃ§Ã£o` etc.).
2. Sanear o dado persistido, impedir nova gravação corrompida e manter fallback de leitura para cache legado.
3. Padronizar as ações dos formulários operacionais sem alterar regras de negócio.

## Proteção em camadas
- **Banco existente:** migration `20260821_0041` repara colunas textuais do PostgreSQL durante o deploy.
- **Novas gravações backend:** evento SQLAlchemy `before_flush` normaliza String/Text/JSON antes de persistir.
- **Resposta da API:** `AtlasHttpClient` continua decodificando bytes explicitamente como UTF-8 e normalizando JSON recebido.
- **Envio do Flutter:** payloads são normalizados antes de `jsonEncode`, impedindo que cache legado volte ao banco.
- **Caches operacionais:** Animal, Rebanho, Sanidade, Reprodução, Nutrição, Estoque, Financeiro e Agenda normalizam o JSON local antes de reconstruir os modelos.
- **Seed Windows:** preservado em UTF-8 com um único BOM e textos portugueses corretos.
- **UI Financeiro:** descrição e categorias passam por `AtlasUiText`, mantendo códigos internos como `health`/`nutrition` e exibindo `Sanidade`/`Nutrição`.

## Consistência de formulários
Novo componente `AtlasFormActions` aplicado a:
- Cadastro/Edição de animal;
- Lote;
- Sanidade;
- Reprodução;
- Agenda;
- Financeiro;
- Estoque.

Padrão:
- `Cancelar` como ação secundária;
- `Salvar ...` como ação principal;
- estado `Salvando...` durante operação;
- layout horizontal no desktop e empilhado em largura reduzida.

Nutrição já utilizava `Cancelar` + `Salvar` no diálogo e foi preservada para não criar regressão desnecessária.

## Backend
Nova migration: `backend/alembic/versions/20260821_0041_repair_mojibake_text.py`

Ela é PostgreSQL-only, idempotente quanto ao resultado e não tenta reverter o dado corrigido no downgrade.

## Gates
- V19.5: 37/37
- V20: 17/17
- V20.1: 18/18
- V20.2: 23/23
- V20.3: 16/16
- V20.4: 21/21
- Baseline static audit: OK
- Full project audit: OK
- 511 rotas backend; 0 duplicadas
- Alembic: 41 revisions; head único `20260821_0041`
- Python compileall: OK

## Testes de normalização
Casos comprovados diretamente no utilitário Python:
- `VermifugaÃ§Ã£o` → `Vermifugação`
- `VacinaÃ§Ã£o` → `Vacinação`
- `HomologaÃ§Ã£o` → `Homologação`
- `NutriÃ§Ã£o` → `Nutrição`
- `ManutenÃ§Ã£o` → `Manutenção`

O pytest isolado não pôde iniciar neste ambiente porque o `conftest.py` importa a aplicação completa e a dependência `python-jose` não está instalada aqui. O teste foi adicionado em `backend/tests/test_v20_4_text_normalization.py` e os módulos envolvidos compilam em Python.

## Validação Windows necessária
O ambiente de empacotamento não possui Flutter SDK. Antes de promoção:
1. `flutter analyze`
2. `flutter test`
3. `flutter build windows --debug`
4. deploy backend/Render para aplicar migration 0041
5. abrir Financeiro, Nutrição, Estoque, Sanidade, Relatórios e Central do Animal em produção.
