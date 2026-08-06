# Sprints 51 a 60

## Entrega
- backend completo com dispositivos, push em lote, pull paginado, conflitos e diagnósticos;
- migration `20260806_0029`;
- núcleo Flutter de banco SQLite, fila e sincronização;
- testes e ferramenta de readiness.

## Aplicação
1. Substitua a pasta `backend` integralmente.
2. Copie `lib/core/offline` para o projeto Flutter.
3. Acrescente as dependências listadas em `ATLAS_PUBSPEC_DEPENDENCIES_SPRINTS_51_60.txt` ao `pubspec.yaml` existente.
4. Execute migrations, testes, `flutter pub get`, `flutter analyze` e `flutter test`.

O banco local não armazena tokens. Tokens e permissões offline devem usar `flutter_secure_storage` em uma etapa de integração com o serviço de autenticação já existente.
