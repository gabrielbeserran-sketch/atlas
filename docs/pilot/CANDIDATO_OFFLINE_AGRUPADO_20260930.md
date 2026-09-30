# Candidato agrupado de sincronização offline — 30/09/2026

## Conteúdo e estado

Este candidato reúne as correções locais de concorrência de escrita, conflito obsoleto, troca de conta/fazenda durante sincronização e reconciliação de conflito resolvido em outro dispositivo. Não substitui a validação em servidor implantado nem o ensaio com dois aparelhos. Nenhuma instalação, migração ou alteração de produção foi feita neste pacote.

| Plataforma | Artefato | SHA-256 |
|---|---|---|
| Windows | `dist/windows/atlas-candidate-20260930-offline/` (23 arquivos) | `projeto_atlas.exe`: `7A53984FAECD66E3BAFFBE59182A4786274BA5C566AA202A342D9E5B7BCE9135` |
| Android | `dist/android/atlas-candidate-20260930-offline-release.apk` | `1F846609AA9A73666AF7524720C002BC8B92013A8F4F358557F2B1610489FC37` |

Os arquivos Windows copiados foram comparados um a um por caminho relativo e SHA-256 com `build/windows/x64/runner/Release`; o APK copiado tem o mesmo SHA-256 de `build/app/outputs/flutter-apk/app-release.apk`. Os artefatos em `dist` são locais e ignorados pelo Git; este documento é o manifesto publicado.

## Verificações

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub -r compact --timeout 45s`: 685 testes aprovados.
- Um build release Windows e um build release Android com `ATLAS_ENV=production` e `ATLAS_API_BASE_URL=https://atlas-api-29y2.onrender.com/api/v1`: ambos concluídos.
- Android: pacote `br.com.projetoatlas.app`, versão `1.0.0+6`; `apksigner verify --verbose --print-certs` aprovado com um assinante e assinatura v2. Não foram inspecionados nem publicados segredos de assinatura.
- `backend/atlas_test.db`: SHA-256 preservado `7763CD50F8650291CBDCB7388904E14A3C4EA4FAC3F5FB498FC18B6631C6061A`; arquivo não entra no checkpoint.

## Limite para uso no piloto

O código servidor deste conjunto ainda depende de revisão da migração 0059, backup testado, janela/autorização de deploy e ensaio real de reconexão com dois dispositivos. Portanto o candidato não prova a sincronização em produção, embora testes locais e CI do backend tenham passado em pacotes anteriores. O aplicativo Windows já aberto e a instalação Android do usuário não foram substituídos. Para avaliar este candidato, primeiro evitar duas instâncias Windows acessando os mesmos dados; a instalação no Android deve ser feita somente quando o usuário solicitar a atualização.
