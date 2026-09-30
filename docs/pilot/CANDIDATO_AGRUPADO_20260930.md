# Candidato agrupado Windows/Android — 30/09/2026

Este pacote reúne as correções locais recentes de Leite, Corte, painel técnico, pastagens e sincronização. É um candidato para avaliação, não um deploy nem uma instalação automática. Os aplicativos usam `ATLAS_ENV=production` e `https://atlas-api-29y2.onrender.com/api/v1`; o servidor de produção não foi alterado por esta preparação.

## Artefatos locais

- Windows: `C:/Projetos/Projetos Atlas/dist/windows/atlas-candidate-20260930/projeto_atlas.exe`, acompanhado de toda a pasta. Os 23 arquivos foram comparados por SHA-256 com o build. `data/app.so`: `AC950BF0B8F78589C73ED2A040B6E17765E3A776C92D6F2D08599F9C822B57B7`; executável: `7A53984FAECD66E3BAFFBE59182A4786274BA5C566AA202A342D9E5B7BCE9135`.
- Android: `C:/Projetos/Projetos Atlas/dist/android/atlas-candidate-20260930-release.apk`; 155.136.623 bytes; SHA-256 `111593B83B9BB7B46A10EEC71CD1C2DF4E616C25C132B6C71A71CB3AA81E61FA`. Cópia comparada com a saída do Flutter e assinatura verificada com `apksigner` usando o Java local do Android Studio. Package `br.com.projetoatlas.app`, versão `1.0.0+6`.

## Validação e limites

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub -r expanded --timeout 45s`: 673 testes aprovados. Um contrato antigo da Agenda exigia comparação literal de `source_type`; o código já usava `is_consultancy_action_source`. O teste foi atualizado para esse contrato e a suíte completa passou.
- `backend/atlas_test.db` não foi modificado pelo pacote: SHA-256 `7763CD50F8650291CBDCB7388904E14A3C4EA4FAC3F5FB498FC18B6631C6061A` antes/depois.
- Não houve login real, ensaio em aparelho, migração da base de produção, deploy do backend nem ativação comercial. A migração 0059 ainda requer backup, relatório read-only na base real e janela aprovada. Assim, recursos que dependem da API nova não devem ser apresentados como homologados em produção.

## Uso seguro na avaliação

1. Salvar e fechar a janela Atlas anterior antes de abrir o candidato Windows; não executar duas versões sobre os mesmos dados locais. A janela anterior não foi encerrada automaticamente.
2. Entrar com conta autorizada; testar reabertura com PIN sem rede e reconexão, sem usar “Sair” para simular apenas a perda da internet.
3. Conferir Leite, Corte, painel técnico, suporte de pastagens e Agenda com registros autorizados. Registrar divergências de índices e dados ausentes sem inventar valores.
4. Instalar o APK somente quando houver decisão de atualizar o celular e cópia/backup dos dados locais; a versão no aparelho permanece inalterada por este pacote.
5. Prosseguir separadamente com migração/deploy controlados, sincronização em dois dispositivos, financeiro/documentos/PDF no aparelho, planos/equipe e piloto comercial.
