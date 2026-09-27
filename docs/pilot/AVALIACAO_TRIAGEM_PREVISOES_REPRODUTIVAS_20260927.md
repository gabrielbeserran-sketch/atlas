# Triagem de previsões reprodutivas — 27/09/2026

## Entrega

O painel separa previsões de animais ativos em data passada, hoje, próximos sete dias (amanhã até hoje+7 inclusive) e posteriores. O cálculo usa dia civil. Não cria tarefas, não marca retorno como concluído/cancelado e não executa baixa clínica ou financeira.

Previsão passada recebe atenção para conferir histórico, não criticidade nem afirmação de pendência confirmada. O modelo atual só contém expectedDate; não possui estado persistido de conclusão/cancelamento nem vínculo ao evento que teria cumprido o retorno. Por isso, registro posterior não fecha automaticamente a previsão anterior.

Previsões com data ilegível, fonte futura/ilegível ou data anterior ao evento de origem não são classificadas. IDs de evento ausentes/repetidos no mesmo animal, ou animalId ausente, ficam fora da contagem com aviso. Datas previstas ausentes continuam ausentes. Mesmo ID de evento em animais diferentes não gera colisão. A triagem da interface exclui animais não ativos, preservando listagem e histórico.

## Validação

87 testes Reprodução/Leite/Corte/painel aprovados, seis novos (quatro de serviço/dois widgets). Cobertura: janela na virada do mês, cronologia impossível, duplicação de evento, histórico intacto, texto de previsão passada sem falsa tarefa crítica e exclusão de animal vendido. Análise de quatro arquivos sem apontamentos, diff e único build profile Windows oficial aprovados (165,9 s). Artefato release/windows/reproducao-previsoes-20260927; identidade com.example/projeto_atlas; SHA-256 app.so 3EF481130A2D2B94E6E058CE171FE25099A6A569CE6808BC59E2F77684914DEE. Checkpoint atlas-reproduction-forecast-triage-20260927. Versão preservada sem abertura/instalação.

## Limites e próximos passos

Não há conclusão/cancelamento persistido, envio dessa informação ao servidor ou nova permissão. Não há prazo clínico arbitrário ou inferência pelo texto livre. IDs diferentes para a mesma previsão não são reconciliados; escopo do serviço é por animal/evento, sem nova migração de identidade entre fazendas. Não é prova de atendimento pendente nem homologação clínica/global.

Próximos: fluxo explícito de conclusão/cancelamento com identidade da previsão, registro de responsável/data e persistência compatível com sincronização; depois teste de reabertura/offline e aceite humano. Não atribuir estado novo automaticamente a dados antigos. Avaliar a versão agrupada antes de atualização do celular. Banco preexistente, PIN, login e dados reais não foram modificados.
