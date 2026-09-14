# Cronograma de execução — Atlas

Atualizado em 14/09/2026. Este arquivo é a fonte visível de acompanhamento dos pacotes em execução.

| Etapa | Situação | Progresso | Critério de aceite |
|---|---:|---:|---|
| Financeiro: OCR, galeria e lançamento offline | Concluído | 100% | Checkpoints `f932fc1` até `614a35a`, análise estática e builds Windows concluídos. |
| Financeiro: fila persistente de fotos offline | Concluído | 100% | A foto é copiada ao armazenamento interno, vinculada ao lançamento local, recebe o id remoto após a confirmação e só é apagada após upload confirmado. Falhas preservam arquivo e vínculo para a próxima tentativa; contrato e build Windows validados. |
| Publicação do OCR no Render | Aguardando segredo | 0% | `OPENAI_API_KEY` e habilitação configurados exclusivamente no Render. |

## Regra de entrega

Uma etapa só muda para **Concluído** quando houver arquivos alterados, teste/validação executada, commit e tag. Mudanças visuais também exigem build Windows confirmado.

## Entrega em validação

- Testes concluídos: `flutter analyze` dos serviços/tela financeira e `financial_document_review_contract_test.dart`.
- Gate finalizado: checkpoint Git, análise estática, teste de contrato e build Windows de regressão concluídos.
