# Atlas V20.9 — Acessibilidade e simplicidade

Base: V20.8.

## Escopo executado
A V20.9 atua na fundação visual e nos fluxos operacionais de maior frequência sem alterar backend, DTOs, migrations, banco ou regras pecuárias.

### Fundação global
- Alvo mínimo de toque de 48 px para FilledButton, OutlinedButton, TextButton e IconButton.
- MaterialTapTargetSize.padded.
- AppBar com 64 px.
- Campos com preenchimento branco, borda de maior contraste e foco de 2 px.
- Mensagens de validação podem ocupar até três linhas.
- Botões recebem padding e tipografia consistentes.
- Chips e divisores receberam contraste previsível.

### Feedback
- Snackbar agora expõe Semantics/liveRegion.
- Sucesso, atenção e erro possuem rótulos semânticos.
- Estado de falha de carregamento possui rótulo acessível.
- Ação Tentar novamente ocupa toda a largura disponível.

### Fluxos de campo
- Pesagem passou a usar AtlasFormActions, com Salvar/Cancelar e estado Salvando padronizados.
- Movimentação passou a usar AtlasFormActions.
- Lote de destino ganhou explicação curta.
- Central do Animal ganhou descrição semântica na atualização.
- A V20.8 foi preservada: situação atual, ações simples, catálogo por assunto e navegação responsiva.

## Gates executados
- V20.7: 32/32
- V20.8: 21/21
- V20.9: 26/26
- V20 UX foundation: 17/17
- V18 UX: 9/9
- Baseline static audit: OK
- Full project audit: OK
- Backend routes: 511
- Duplicate routes: 0
- Alembic heads: 1 (`20260821_0041`)

## Observação do ambiente de auditoria
O runtime usado para empacotamento injeta um warmup externo de planilhas ao iniciar Python; ele emite um traceback após os scripts, mas os gates do Atlas retornaram código 0. Esse ruído não pertence ao projeto.

## Validação obrigatória no Windows
Executar na raiz do projeto:
1. `flutter pub get`
2. `dart format --set-exit-if-changed lib test`
3. `flutter analyze`
4. `flutter test`
5. `flutter build windows --debug`
6. `flutter run -d windows --dart-define=ATLAS_ENV=production --dart-define="ATLAS_API_BASE_URL=https://atlas-api-29y2.onrender.com/api/v1"`

Inspecionar especialmente: escala de texto do Windows, navegação por teclado, contraste, foco dos campos, Pesagem, Movimentação e Central do Animal.
