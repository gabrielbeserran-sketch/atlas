# Cronograma de execução — Atlas

Atualizado em 14/09/2026. Este arquivo é a fonte visível de acompanhamento dos pacotes em execução.

| Etapa | Situação | Progresso | Critério de aceite |
|---|---:|---:|---|
| Financeiro: OCR, galeria e lançamento offline | Concluído | 100% | Checkpoints `f932fc1` até `614a35a`, análise estática e builds Windows concluídos. |
| Financeiro: fila persistente de fotos offline | Concluído | 100% | A foto é copiada ao armazenamento interno, vinculada ao lançamento local, recebe o id remoto após a confirmação e só é apagada após upload confirmado. Falhas preservam arquivo e vínculo para a próxima tentativa; contrato e build Windows validados. |
| Financeiro: visibilidade de sincronização de comprovantes | Concluído | 100% | O Financeiro informa separadamente os comprovantes preservados no dispositivo e pendentes de envio, sem ocultar o status dos lançamentos. Análise, teste de contrato e build Windows aprovados. |
| Financeiro: compatibilidade MIME para OCR no Windows | Concluído | 100% | O upload multipart identifica JPEG, PNG, WebP e GIF pelo arquivo local, evitando rejeição de fotos como `application/octet-stream`. Dependência declarada, análise, contrato e build Windows aprovados. |
| Financeiro: diagnóstico seguro do provedor OCR | Concluído | 100% | O servidor traduz erros de chave, limite e modelo sem registrar foto, resposta bruta ou segredo. A leitura real confirmou o diagnóstico de limite do provedor. |
| Financeiro: repetir leitura da mesma foto | Concluído | 100% | Se o OCR falhar temporariamente, o usuário pode repetir a leitura com a mesma imagem ou preencher manualmente, sem nova captura. Análise, contrato e build Windows aprovados. |
| Financeiro: prevenção de repetição sem resultado | Concluído | 100% | Quando a chave, modelo ou limite do OCR impedirem a leitura, o aplicativo explica a situação e não oferece uma nova chamada inútil. Análise, contrato e build Windows aprovados. |
| Financeiro: OCR local no celular | Em validação | 90% | Android/iOS leem o texto no próprio aparelho antes de qualquer opção de nuvem; fornecedor, data, documento, valor e categoria são sugestões revisáveis. A foto e o texto não saem do dispositivo. Contrato, APK Android de validação e build Windows aprovados; falta teste em aparelho. |
| Publicação do OCR no Render | Bloqueado externamente | 90% | O servidor e a chave estão ativos, mas a API de leitura retornou limite atingido. A homologação final depende da renovação/ampliação da cota do provedor. |

## Regra de entrega

Uma etapa só muda para **Concluído** quando houver arquivos alterados, teste/validação executada, commit e tag. Mudanças visuais também exigem build Windows confirmado.

## Entrega em validação

- Testes concluídos: `flutter analyze` dos serviços/tela financeira e `financial_document_review_contract_test.dart`.
- Gate finalizado: checkpoint Git, análise estática, teste de contrato e build Windows de regressão concluídos.
