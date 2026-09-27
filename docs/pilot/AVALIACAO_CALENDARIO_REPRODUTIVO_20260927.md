# Calendário reprodutivo — 27/09/2026

## Entrega

ReproductionCalendar compartilha leitura estrita de datas civis BR/ISO entre ReproductionMetricsService e a visão geral. Datas impossíveis/ilegíveis são indisponíveis, sem fallback 1900 nem normalização para outro mês.

O cartão de animal escolhe o último evento com data válida não futura; desempata datas iguais por ID para apresentação, sem inferir ordem clínica dentro do dia. Nenhuma lista armazenada é ordenada ou regravada. Se só houver datas inválidas/futuras, exibe “Sem evento realizado com data válida”, não ausência de registros.

Retorno com data informada mas ilegível gera aviso; não é classificado como vencido. Data prevista ausente continua ausente e não gera um prazo inventado. Agenda do serviço mantém ordenação cronológica BR/ISO e limite do dia, agora com a mesma interpretação da visão geral.

## Evidência e limites

81 testes Reprodução/Leite/Corte/painel aprovados, cinco novos (quatro calendário/um interface). O novo widget cobre aviso de retorno inválido, ausência de evento realizado válido e ausência de vencimento falso. Demais casos cobrem bissexto, ordem entre mês/ano, futuro, preservação da lista e desempate. Análise de cinco arquivos sem apontamentos, diff aprovado e único build Windows profile oficial aprovado em 387,2 s. Artefato release/windows/reproducao-calendario-20260927; identidade com.example/projeto_atlas; SHA-256 app.so 1A753774830BD7D1D1EA1FCEB6BDE279F518AD2360B41F052EB8AE1351358726. Checkpoint atlas-reproduction-calendar-20260927.

Calendário aceita somente datas civis sem horário. Eventos provenientes da API já passam pelo modelo que apresenta datas civis; timestamp bruto não é interpretado pelo helper. A escolha de último evento é apresentação, não prova clínica; IDs iguais ou eventos sem identidade não recebem reparo automático. O alerta de vencimento não conhece conclusão/cancelamento de retorno, e a agenda completa do serviço não recebeu nova rota de interface neste pacote.

Não foram alterados dados reais, PIN, login, credenciais ou backend/atlas_test.db. Nova versão não será aberta sobre aplicativo anterior nem instalada no celular sem solicitação apropriada. Aceite técnico/global, vínculo de concepção e ensaios reais seguem pendentes.

Próximo: rever ciclo de conclusão/cancelamento dos retornos antes de chamar previsões antigas de pendências operacionais; avaliar a versão agrupada e executar ensaios offline/dois dispositivos quando o ambiente estiver disponível.
