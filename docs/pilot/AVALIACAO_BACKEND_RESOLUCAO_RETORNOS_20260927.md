# Backend de resolução de retornos — 27/09/2026

## Entrega local

PATCH reprodutivo valida identidade, datas de origem/previsão, responsável declarado, motivo de cancelamento e data UTC canônica compatível com Dart. Valores inválidos recebem HTTP 409 antes de modificar o evento. Retorno sem previsão não ganha baixa; registros antigos sem resolução não são encerrados automaticamente.

Primeira resolução recebe authenticated_user_id do principal autenticado, ignorando autor escolhido no novo payload. Repetição preserva auditoria/autor originais; resolução terminal não é removida ou sobrescrita por PATCH. Criação de evento com resolução importada é recusada. Mudança de data que rompa o vínculo é recusada: não há reabertura automática.

Evento é selecionado com bloqueio de linha no PATCH. Após sincronizar a tarefa correspondente por empresa/fazenda/tipo/source, aplica completed/cancelled, completed_at apenas para conclusão e evidência da auditoria, mantendo previsão e responsável previamente atribuído à tarefa. Repetição não duplica evidência. Alteração só de metadados não rederiva estado clínico do animal.

Metadados anteriores de outras chaves são preservados; chaves explicitamente fornecidas continuam editáveis. Exclusão do registro ainda segue o contrato anterior e remove tarefas: esta anotação não é log imutável/legal nem prova de integridade forense de metadados legados.

## Validação isolada

Executar backend/.venv/Scripts/python.exe scripts/test_reproduction_return_resolution.py, a partir de backend. Runner força ATLAS_DATABASE_URL=sqlite:///:memory: antes dos imports e não usa tests/conftest.py. Treze testes aprovados: autoria, vínculo, estados, UTC inválido/futuro, idempotência, metadata, criação bloqueada, rejeição antes de mutação, integração da rota por mocks, tarefa/reabertura em SQLite em memória e outra empresa/source intactos.

Compilação Python de serviço/rota/runner e Ruff F nos dois arquivos novos aprovados; diff aprovado. Banco backend/atlas_test.db mantém SHA-256 7763CD50F8650291CBDCB7388904E14A3C4EA4FAC3F5FB498FC18B6631C6061A nas duas medições deste pacote. Não executar pytest/conftest preexistente sobre esse banco.

## Pendências

Sem deploy, endpoint HTTP real ou ensaio PostgreSQL de concorrência; SQLite ignora bloqueio de linha e não comprova sua eficácia em PostgreSQL. Transições concorrentes/manuais pela rota de tarefas operacionais ainda exigem reconciliação; permissão reproduction.write existente foi preservada, não substitui homologação de RBAC/tenant.

Sem botão na interface, escrita offline, reabertura explícita ou assinatura/log imutável. Próximo: integrar confirmação/releitura na interface com este contrato e validar conflito com alterações manuais de tarefas, depois fila offline idempotente e homologação do servidor/aparelhos. Não publicar baixa no servidor atual sem o contrato atualizado. Nenhum dado real, PIN, login, OCR, Render ou aplicativo instalado alterado.
