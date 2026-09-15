# Cronograma de execução — Atlas

Atualizado em 15/09/2026. Este arquivo é a fonte visível de acompanhamento dos pacotes em execução.

| Etapa | Situação | Progresso | Critério de aceite |
|---|---:|---:|---|
| Financeiro: OCR, galeria e lançamento offline | Concluído | 100% | Checkpoints `f932fc1` até `614a35a`, análise estática e builds Windows concluídos. |
| Financeiro: fila persistente de fotos offline | Concluído | 100% | A foto é copiada ao armazenamento interno, vinculada ao lançamento local, recebe o id remoto após a confirmação e só é apagada após upload confirmado. Falhas preservam arquivo e vínculo para a próxima tentativa; contrato e build Windows validados. |
| Financeiro: anexos de lançamentos existentes sem conexão | Concluído | 100% | Ao anexar foto a um lançamento já existente sem rede, o Centro de documentos preserva cópia local, mantém o vínculo ao lançamento e sincroniza no próximo carregamento conectado. A interface informa o comprovante pendente sem bloquear a conferência humana. |
| Financeiro: visibilidade de sincronização de comprovantes | Concluído | 100% | O Financeiro informa separadamente os comprovantes preservados no dispositivo e pendentes de envio, sem ocultar o status dos lançamentos. Análise, teste de contrato e build Windows aprovados. |
| Financeiro: compatibilidade MIME para OCR no Windows | Concluído | 100% | O upload multipart identifica JPEG, PNG, WebP e GIF pelo arquivo local, evitando rejeição de fotos como `application/octet-stream`. Dependência declarada, análise, contrato e build Windows aprovados. |
| Financeiro: diagnóstico seguro do provedor OCR | Concluído | 100% | O servidor traduz erros de chave, limite e modelo sem registrar foto, resposta bruta ou segredo. A leitura real confirmou o diagnóstico de limite do provedor. |
| Financeiro: repetir leitura da mesma foto | Concluído | 100% | Se o OCR falhar temporariamente, o usuário pode repetir a leitura com a mesma imagem ou preencher manualmente, sem nova captura. Análise, contrato e build Windows aprovados. |
| Financeiro: prevenção de repetição sem resultado | Concluído | 100% | Quando a chave, modelo ou limite do OCR impedirem a leitura, o aplicativo explica a situação e não oferece uma nova chamada inútil. Análise, contrato e build Windows aprovados. |
| Financeiro: OCR local no celular | Em validação | 98% | Android/iOS leem texto e chave de acesso NF-e/QR no próprio aparelho antes de qualquer opção de nuvem; fornecedor, data, documento, valor e categoria são sugestões revisáveis. A foto e o texto não saem do dispositivo. A leitura agora normaliza data curta de DANFE e rejeita data impossível. Análise estática, cinco testes e APK Android atualizado aprovados; falta somente teste em aparelho com nota real, guiado por `docs/pilot/VALIDACAO_OCR_LOCAL_ANDROID_20260915.md`. |
| Cotações: importação tolerante de retornos XLSX | Concluído | 100% | O importador aceita aba com outro nome e cabeçalhos usuais, permite fornecedor ausente com identificação provisória e usa total declarado quando os itens estiverem incompletos. Nenhum dado é gravado sem revisão; nove cenários automatizados aprovados. |
| Anotações: pastas com confirmação de persistência | Concluído | 100% | A pasta é criada somente após releitura da fonte oficial; a interface distingue sessão expirada, permissão insuficiente, assunto duplicado e indisponibilidade. Testes e análise estática aprovados; homologação manual confirmou a pasta persistida em 15/09. |
| Regressão transversal: Financeiro e acesso offline | Concluído | 100% | 26 testes cobriram Financeiro, OCR local, cotações, login offline, sessão e fila de sincronização. Build Windows de produção e APK Android atual foram gerados sem erros. |
| Arquitetura de Inteligência e Analytics | Concluído | 100% | Central única de Análises definida e protegida por contrato: resumo, diagnóstico, análise por área, cenários e decisões. Copilot e motores especializados permanecem contextuais, sem virar menu concorrente. |
| Inteligência: decisão vinculada a Anotações e Agenda | Concluído | 100% | Uma decisão gera anotação com referência persistente à recomendação e a anotação aproveita a promoção idempotente já existente para a Agenda. Frontend, rota, modelo, migração e contratos passaram. Em 15/09, a recomendação real “Manter acompanhamento da operação” foi salva pela Central e confirmada na lista de Anotações da Fazenda Atlas Produção como “Decisão vinculada à análise”, sem criação duplicada. |
| Anotações: compromisso com data prevista na Agenda | Concluído | 100% | A promoção de uma anotação passou a exigir escolha explícita de data prevista, já enviada ao contrato `due_at` do servidor. Análise estática e dois contratos Flutter aprovados; build Windows de produção concluído com êxito em 15/09. |
| Inteligência: snapshot único por fazenda | Concluído | 100% | A Central guarda um contexto oficial por atualização e envia seu identificador às prioridades e aos cenários. O servidor valida empresa e fazenda antes de reutilizar o snapshot, evitando leituras cruzadas ou dados de momentos diferentes. Contratos Flutter e servidor aprovados; em 14/09 a Central carregou uma prioridade real em sessão autenticada no Windows, confirmando o fluxo completo. |
| Android: atualização da cadeia de build | Concluído | 100% | Gradle 8.14, Android Gradle Plugin 8.11.1 e Kotlin 2.2.20. APK debug recompilado com sucesso pela cadeia atualizada e checkpoint Git auditável. |
| Regressão integrada: Inteligência, Anotações e documentos financeiros | Concluído | 100% | Três contratos Flutter e três testes de servidor aprovados: decisão rastreável, snapshot por fazenda e comprovantes financeiros offline. |
| Produção: auditoria de publicação e disponibilidade | Concluído | 100% | Render está configurado para auto-deploy no branch `master` e publicou `2121e91`. O startup aprovou migrations e schema; a rota de saúde respondeu 200 em 1,02 s e a rota de Inteligência respondeu 403 sem credenciais, confirmando a proteção. O primeiro acesso pode exceder 50 s porque o plano Free hiberna a instância. |
| Publicação do OCR no Render | Bloqueado externamente | 90% | O servidor e a chave estão ativos, mas a API de leitura retornou limite atingido. A homologação final depende da renovação/ampliação da cota do provedor. |

## Regra de entrega

Uma etapa só muda para **Concluído** quando houver arquivos alterados, teste/validação executada, commit e tag. Mudanças visuais também exigem build Windows confirmado.

## Entrega em validação

- Testes concluídos: regressão transversal com 26 cenários; neste pacote, três contratos Flutter e três testes de servidor aprovados.
- APK Android: `build/app/outputs/flutter-apk/app-debug.apk` — pacote atualizado em 15/09 com a Agenda por data prevista e OCR local reforçado; SHA-256 `62D6AC6C1F1977C5B6D16DD9A408FD825C55C206C85532CA7750A026C740FEFA`.
- Gate finalizado: checkpoint Git, contratos integrados e APK Android recompilado com Gradle 8.14, AGP 8.11.1 e Kotlin 2.2.20.
