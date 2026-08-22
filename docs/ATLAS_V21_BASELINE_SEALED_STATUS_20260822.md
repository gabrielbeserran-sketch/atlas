# Atlas V21 — baseline selada

## Estado
Os gates automáticos V21 foram aprovados no Windows:
- 13 PASS
- 0 WARN
- 0 FAIL
- build Windows aprovado
- executável gerado

A baseline foi congelada tecnicamente para impedir que novas funcionalidades sejam misturadas à homologação V21.

## Selagem
Foi gerado um manifesto SHA-256 de todos os arquivos distribuíveis:
`docs/ATLAS_V21_BASELINE_MANIFEST_SHA256.json`

Foi criado:
`scripts/quality/seal_v21_baseline.ps1`

Esse script:
- exige repositório Git válido;
- exige working tree limpa;
- não altera código;
- cria uma tag anotada `v21-baseline-ux-homologada`.

## Próxima fase
A próxima frente técnica é Android Release Candidate.

O preflight inicial está em:
`scripts/quality/atlas_android_rc_preflight.ps1`

Ele é somente leitura e verifica Flutter, dispositivos, AndroidManifest e Gradle antes de qualquer modificação Android.

## Limite de honestidade
A automação não consegue comprovar percepção visual humana, como sobreposição, legibilidade ou sensação de fluidez. A V21 está tecnicamente selada; a inspeção visual final continua sendo o único item não automatizável.
