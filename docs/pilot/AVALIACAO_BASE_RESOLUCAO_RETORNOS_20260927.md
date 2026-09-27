# Base de resolução dos retornos — 27/09/2026

## Entrega local

AnimalReproductionData preserva metadata local/API e no formulário de edição. Antes, toApi enviava metadata_json vazio. Metadados de outras funcionalidades não são descartados pelo modelo, e withAnimalId preserva o conteúdo.

Serviço de resolução explícita produz completed/cancelled com ID do evento, datas de origem/previsão, responsável declarado, data UTC e motivo. Cancelamento exige motivo; identidade/datas válidas e responsável são obrigatórios, data futura é recusada, resolução válida existente não é sobrescrita. Alterar identidade/origem/previsão invalida a baixa anterior, preservando a anotação para revisão.

Triagem desconsidera apenas resolução válida. Auditoria incompleta, impossível ou futura não vale como baixa. Não atribui completed aos dados antigos nem apaga a previsão original.

updateRecord relê o servidor e verifica os campos da auditoria, não somente existência do ID. Se servidor descartar metadata, lança erro em vez de confirmar sucesso. Teste mockado confirma leitura local ao reabrir offline após resolução confirmada remotamente. Não é gravação offline de baixa.

## Validações e limites

95 testes Reprodução/Leite/Corte/painel aprovados; nove testes de resolução aprovados após guarda final de calendário, incluindo um caso adicional. Análise final de seis arquivos e diff. Contrato existente backend/app/schemas/legacy.py aceita/devolve metadata_json, sem mudança de schema, deploy ou requisição ao servidor.

Sem botão de concluir/cancelar ainda: PATCH reprodutivo também atualiza tarefas operacionais no backend, e essa integração precisa respeitar a resolução antes da exposição na interface. Não se afirma função ponta a ponta concluída. Responsável é declarado pelo chamador, não assinatura/autoria autenticada nem log imutável; controle de transição/concorrência no servidor continua pendente. Agenda/listagem individual ainda precisa consumir estados resolvidos. Não há fila nova de baixas offline nem sincronização em dois dispositivos neste pacote.

Build/instalação agrupados posteriores: somente Dart/metadata, sem layout/dependência nativa. Aplicativo instalado não contém este pacote. Dados reais, PIN e backend/atlas_test.db preservados.

Próximo: integração com tarefas operacionais e contrato de transição/autoria, interface de confirmação com releitura; depois escrita offline com idempotência/contexto autorizado e ensaios reais. Não executar baixa clínica/financeira automática a partir desta anotação.
