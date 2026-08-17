# ATLAS — Lições e prevenções permanentes

Cada falha recorrente passa a gerar um controle permanente.

- Docker saudável mas porta inacessível: socket TCP + autenticação real.
- Senha de volume divergente: reconciliação idempotente em dev/test.
- Script Python sem `app`: bootstrap de `sys.path` + regressão.
- `.venv` ausente: criação automática + fingerprint.
- Pacotes Dart não restaurados: bootstrap executa `flutter pub get`.
- Arquivos antigos mesclados: manifesto da baseline bloqueia fontes inesperadas.
- Banco em head com colunas ausentes: reparo aditivo + revalidação.
- Python multiline em PowerShell: proibido; arquivo Python próprio.
- Parser PowerShell: preflight usa parser nativo antes de executar scripts.
- UTF-8 Windows: `.ps1` distribuídos em UTF-8 BOM + CRLF.

Riscos previstos: portas 8000/5432 ocupadas, venv desatualizada, schema antigo, resíduos de versão, dependências Flutter não restauradas, import Python direto, divergência env/Compose, múltiplos heads Alembic e cache gerado incluído no pacote.

Um marco só avança após preflight, bootstrap limpo, backend, Quality Gate completo e validação na mesma árvore.


11. Teste de integração dependendo de registro pré-existente.
    Sintoma: `_first_animal()` retornou `None` em banco limpo.
    Prevenção: testes end-to-end criam explicitamente Fazenda → Lote → Animal
    pela API oficial e não dependem da ordem/conteúdo de outros testes.
