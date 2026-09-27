# Conciliação Agenda/Reprodução — 27/09/2026

## Entrega local

A tarefa principal de retorno reprodutivo pode concluir/cancelar o retorno pela Agenda. A rota valida a fonte e prepara auditoria no evento antes de alterar ORM; evento e tarefa são gravados no mesmo commit. O usuário autenticado é responsável pela baixa originada da Agenda, sem inferir diagnóstico/parto ou alterar o resultado clínico. Cancelamento exige motivo na evidência da tarefa. Não houve alteração da interface Flutter neste pacote.

Alterar estado, previsão ou evidência de tarefa reprodutiva exige reproduction.write além da permissão herd.write da rota. Título/descrição/atribuição continuam editáveis conforme autorização existente. Evento ausente/alheio, vínculo alterado ou tarefa duplicada histórica são recusados antes de salvar. Tarefa principal é a mais antiga, com desempate por ID.

Retorno resolvido não pode ser reaberto, trocar sua baixa, alterar previsão ou substituir evidência pela Agenda. Retry com evidência original conserva autor, timestamp e marcador auditável. Mudança de previsão de retorno aberto permanece possível, mas não pode anteceder a origem nem acompanhar a baixa na mesma requisição. Data equivalente UTC funciona também após leitura SQLite sem timezone.

Uma tarefa antiga encerrada sem auditoria não vira resolução por simples edição de título. Confirmação explícita no mesmo estado pode registrar a baixa, mas encerramento oposto é recusado. Edição do evento não reabre automaticamente tarefa reprodutiva cancelada. Na resolução pelo histórico, encerramento conflitante da tarefa principal impede a gravação antes de mutar o evento. Duplicidades históricas continuam descartadas pelo mecanismo de sincronização existente, sem fingir novas execuções.

## Evidências e limites

27 testes isolados aprovados, 13 novos; runner direto com ATLAS_DATABASE_URL=sqlite:///:memory:, sem conftest de banco em arquivo. Casos incluem commit/releitura em nova Session, conclusão, motivo, retry, previsão, autoria, permissão, fonte alheia, duplicada, legado, tarefa manual e conflito recusado antes de mutação. Ruff F serviço/Agenda/runner, compilação Python dos quatro arquivos e git diff --check aprovados.

Locks previstos na ordem evento→tarefa; sincronização do evento bloqueia tarefas vinculadas. SQLite em memória não valida locks PostgreSQL nem concorrência entre processos. Testes chamam rotas diretamente, não comprovam transporte HTTP/autenticação real. Permissões são conferidas com principal construído nos testes.

Checkpoint atlas-reproduction-agenda-reconciliation-20260927. Sem nova compilação Flutter, abertura do aplicativo ou instalação Android; backend publicado ainda precisa de verificação em ambiente autorizado. Preservados dados reais, PIN, login, OCR e hash preexistente de backend/atlas_test.db. A fila fiscal offline não foi refeita.

## Próximos

Escrita offline idempotente do retorno, seguida de contrato HTTP real/implantação autorizada, concorrência PostgreSQL e ensaio em dois dispositivos. Na avaliação, conferir baixa pela Agenda no histórico; tentar repetir, reabrir e alterar previsão; verificar que falhas não produzem encerramento falso. Não há reabertura administrativa de resolução terminal neste pacote.
