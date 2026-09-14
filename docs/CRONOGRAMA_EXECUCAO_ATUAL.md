# Cronograma de execução — Atlas

Atualizado em 14/09/2026. Este arquivo é a fonte visível de acompanhamento dos pacotes em execução.

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
| Financeiro: OCR local no celular | Em validação | 97% | Android/iOS leem texto e chave de acesso NF-e/QR no próprio aparelho antes de qualquer opção de nuvem; fornecedor, data, documento, valor e categoria são sugestões revisáveis. A foto e o texto não saem do dispositivo. Contrato, APK Android de validação, build Windows e testes determinísticos de parsing aprovados; falta teste em aparelho. |
| Cotações: importação tolerante de retornos XLSX | Concluído | 100% | O importador aceita aba com outro nome e cabeçalhos usuais, permite fornecedor ausente com identificação provisória e usa total declarado quando os itens estiverem incompletos. Nenhum dado é gravado sem revisão; nove cenários automatizados aprovados. |
| Regressão transversal: Financeiro e acesso offline | Concluído | 100% | 26 testes cobriram Financeiro, OCR local, cotações, login offline, sessão e fila de sincronização. Build Windows de produção e APK Android atual foram gerados sem erros. |
| Arquitetura de Inteligência e Analytics | Concluído | 100% | Central única de Análises definida e protegida por contrato: resumo, diagnóstico, análise por área, cenários e decisões. Copilot e motores especializados permanecem contextuais, sem virar menu concorrente. |
| Inteligência: decisão vinculada a Anotações e Agenda | Pronto para publicação | 95% | Uma decisão pode gerar anotação com referência persistente à recomendação e a anotação aproveita a promoção idempotente já existente para a Agenda. Frontend, rota, modelo, migração e contratos locais aprovados; falta publicar a migração/servidor antes de expor o comando aos usuários. |
| Publicação do OCR no Render | Bloqueado externamente | 90% | O servidor e a chave estão ativos, mas a API de leitura retornou limite atingido. A homologação final depende da renovação/ampliação da cota do provedor. |

## Regra de entrega

Uma etapa só muda para **Concluído** quando houver arquivos alterados, teste/validação executada, commit e tag. Mudanças visuais também exigem build Windows confirmado.

## Entrega em validação

- Testes concluídos: regressão transversal com 26 cenários e análise estática dos serviços/telas modificados.
- APK Android: `build/app/outputs/flutter-apk/app-debug.apk` — SHA-256 `39FF3C1282BF4ED9145B4DA239D8AFE974E4262CE41E8D9C703619FFFAC47B9A`.
- Gate finalizado: checkpoint Git, análise estática, contratos, build Windows de produção e APK Android de validação concluídos.
