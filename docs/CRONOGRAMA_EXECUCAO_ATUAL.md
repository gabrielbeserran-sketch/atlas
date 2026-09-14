# Cronograma de execução — Atlas

Atualizado em 14/09/2026. Este arquivo é a fonte visível de acompanhamento dos pacotes em execução.

| Etapa | Situação | Progresso | Critério de aceite |
|---|---:|---:|---|
| Financeiro: OCR, galeria e lançamento offline | Concluído | 100% | Checkpoints `f932fc1` até `614a35a`, análise estática e builds Windows concluídos. |
| Financeiro: fila persistente de fotos offline | Em execução | 0% | Foto copiada ao armazenamento interno; vínculo com lançamento pendente; upload idempotente após sincronização; remoção apenas após confirmação; testes de falha e repetição. |
| Publicação do OCR no Render | Aguardando segredo | 0% | `OPENAI_API_KEY` e habilitação configurados exclusivamente no Render. |

## Regra de entrega

Uma etapa só muda para **Concluído** quando houver arquivos alterados, teste/validação executada, commit e tag. Mudanças visuais também exigem build Windows confirmado.
