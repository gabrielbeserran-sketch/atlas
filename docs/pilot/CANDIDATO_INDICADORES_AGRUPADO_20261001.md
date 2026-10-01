# Candidato agrupado de indicadores — 01/10/2026

## Conteúdo e estado

O candidato parte de `63f5ecd` e reúne as correções locais posteriores ao candidato de 30/09: consistência da carteira de pastejo, integridade de data/peso das pesagens, proteção dos indicadores Corte/Leite, dias civis da reprodução leiteira e leitura estrita de ordenhas no painel técnico. Os artefatos são candidatos locais, não uma instalação aprovada ou validação zootécnica.

| Plataforma | Artefato local | SHA-256 |
|---|---|---|
| Windows | `dist/windows/atlas-candidate-20261001-indicators/` (23 arquivos) | `data/app.so`: `96574F3A5021BA7CFEE0984FBB49A95C1F3A0221EC2EDF5C379D55F27BBAB0BF`; `projeto_atlas.exe`: `7A53984FAECD66E3BAFFBE59182A4786274BA5C566AA202A342D9E5B7BCE9135` |
| Android | `dist/android/atlas-candidate-20261001-indicators-release.apk` | `4BF9F38A9F7EFD2675464AE734704ECBE3C9BA1ACC8225989164DBA6FA1F6939` |

Os arquivos Windows copiados foram comparados um a um por caminho relativo e SHA-256 com `build/windows/x64/runner/Release`; o APK copiado tem o mesmo hash de `build/app/outputs/flutter-apk/app-release.apk`. `dist` é local e ignorado pelo Git; este documento é o manifesto publicado.

## Verificações

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub -r compact --timeout 45s`: 703 testes aprovados.
- Um build Windows release e um APK release, com `ATLAS_ENV=production` e `ATLAS_API_BASE_URL=https://atlas-api-29y2.onrender.com/api/v1`: ambos concluídos.
- APK: pacote `br.com.projetoatlas.app`, versão `1.0.0+6`, `minSdk` 24, `targetSdk` 36. `apksigner verify --verbose --print-certs` aprovou assinatura v2 com um signatário. Nenhum segredo de assinatura foi inspecionado ou publicado.
- `backend/atlas_test.db`: SHA-256 preservado `7763CD50F8650291CBDCB7388904E14A3C4EA4FAC3F5FB498FC18B6631C6061A`; não entra no checkpoint.

## Limites para avaliação

A janela Windows em uso permanece na cópia anterior; não houve instalação no Android, migração nem alteração do backend de produção. Não abrir duas instâncias Windows contra os mesmos dados locais. O pacote 4 ainda precisa de revisão de indicadores com registros autorizados e responsável técnico. O ensaio entre dispositivos e a sincronização real dependem dos gates de backup, migração/deploy autorizados e servidor implantado. O OCR precisa de documento de teste no aparelho. Este candidato não substitui esses aceites.
