# Atlas V21 — status final de homologação

## Comprovado no Windows
- flutter analyze: sem issues.
- flutter test: 132 testes aprovados.
- smoke Render/Supabase anterior: 13 PASS, 0 WARN, 0 FAIL.
- build Windows anterior V21.5: aprovado.

## Falha mais recente
LNK1168: projeto_atlas.exe estava aberto e o linker não conseguiu sobrescrever o executável. Não é erro de Dart, Flutter, backend ou banco.

## Correção definitiva do gate
Antes do build o homologador agora detecta e encerra projeto_atlas.exe, confirma a liberação do processo e tenta novamente. Em segunda tentativa remove somente build/windows; não executa flutter clean global.

## Etapa atual
V21 — homologação final da baseline UX.

## Pendências para encerrar V21
1. Gate automático final no Windows.
2. Inspeção visual final do executável.
3. Checkpoint/tag Git da baseline homologada.
