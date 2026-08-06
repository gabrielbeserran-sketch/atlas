# Gate Flutter

O gate obrigatório executa, nesta ordem:

1. `flutter clean`
2. `flutter pub get`
3. `dart format --output=none --set-exit-if-changed lib test`
4. `flutter analyze`
5. `flutter test`

Contratos obrigatórios:

- usar `AtlasHttpClient.send()`;
- converter respostas com `asMap()` ou `asMapList()`;
- não aplicar `.toList()` dentro do widget criado pelo `map()`;
- não enviar `String?` para parâmetros `String` sem normalização;
- telas devem possuir estados de carregamento, erro, vazio e atualização.
