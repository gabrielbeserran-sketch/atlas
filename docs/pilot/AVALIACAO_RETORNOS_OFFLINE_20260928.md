# Baixas de retornos offline — 28/09/2026

## Entrega local

No histórico reprodutivo individual há comandos explícitos para concluir/cancelar offline, além do fluxo online. O produtor informa responsável e motivo no cancelamento. A baixa offline vira somente intenção persistida no dispositivo, com previsão/identidade/status/auditoria originais; não fecha evento, tarefa, cartão nem retira previsão da triagem. O histórico identifica pendente ou conflito; edição e exclusão do evento ficam bloqueadas até confirmar ou descartar a intenção local.

A fila é separada da fila fiscal e isolada por tenant, empresa, fazenda e usuário da sessão autorizada. Apenas evento já sincronizado entra nela; duplicar a mesma intenção preserva timestamp e evita sobrescrever. Mudança de conta/fazenda antes do PATCH interrompe o envio. Escritas locais no processo são serializadas para duas ações próximas não perderem itens. Corrupção do armazenamento produz erro sem apagar a fila.

Ao tocar Sincronizar baixas, o app consulta o servidor e exige contrato de retornos v1, identidade e previsão iguais. Se já houver auditoria confirmada idêntica, remove a intenção sem outro PATCH — inclusive após resposta perdida. Caso contrário envia somente metadata, relê o servidor e exige autoria confirmada antes de remover a intenção. Divergência de previsão, origem, ausência/duplicidade de evento ou outra resolução vira conflito preservado e visível. Usuário pode descartar explicitamente apenas a intenção local, após confirmação. Falta de rede, servidor antigo e resposta não confirmada preservam a fila.

## Evidências e limites

Um único build Windows profile oficial aprovado em 149,7 s: release/windows/reproducao-retornos-offline-20260928, identidade com.example/projeto_atlas, SHA-256 app.so 9DCF4631055179F00A106C624C66FD5A6D8584CDF5D8AF4576B6C89B7B8A5900. Checkpoint atlas-reproduction-returns-offline-20260928.

100 testes Flutter Reprodução/Leite/Corte aprovados, incluindo 10 novos para persistência/reabertura, conta/fazenda/usuário, inclusão concorrente, perda de resposta, conflito, servidor antigo, rede ausente, troca de conta, armazenamento ilegível e menu de conflito. Análise estática sem apontamentos. Um único build Windows profile oficial encerrará o pacote. Sem instalação Android ou abertura sobre app anterior.

Sincronização é acionada pelo usuário nesta tela, não no login nem como trabalhador permanente de segundo plano; a entrada rápida do aplicativo não depende da fila. O contrato HTTP real em produção, concorrência PostgreSQL e dois dispositivos permanecem não testados. Esta fila não resolve conflitos automaticamente. Não há assinatura criptográfica local ou garantia contra alteração física do armazenamento. O cache clínico legado ainda é indexado por nome de fazenda/grupo; o envio usa autorização do servidor para o animal e a fila tem escopo próprio. A fila fiscal offline não foi alterada.

## Roteiro de avaliação

1. Com evento reprodutivo já salvo, ficar sem rede, registrar conclusão/cancelamento offline e reabrir o app; conferir etiqueta pendente e retorno ainda na triagem.
2. Reconectar ao backend atualizado, tocar Sincronizar baixas e reler histórico/tarefa; confirmar uma única baixa.
3. Repetir após resposta interrompida, conferir que não nasce segundo evento nem segunda auditoria.
4. Alterar previsão no segundo dispositivo antes de sincronizar e conferir conflito visível, sem sobregravação.
5. Trocar de conta/fazenda e conferir que fila anterior não aparece nem é enviada. Descartar somente depois de verificar caso a caso.
