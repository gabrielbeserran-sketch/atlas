# Atlas — Auditoria consolidada de homologação

## Evidências conferidas

A auditoria foi feita sobre o projeto V5 e sobre a rodada visual de homologação em produção com a base DEMO.

### Confirmado operacional

- Dashboard: 1 fazenda e 4 pendências persistidas.
- Rebanho: 3 lotes, 4 animais, 3 fêmeas e 1 macho carregados da API.
- Central do animal DEMO-101: 480 kg, ECC 3,5, prenhez positiva e histórico consolidado.
- Timeline Enterprise: endpoint e carregamento funcionando.
- Sanidade: 2 eventos globais e histórico individual disponível.
- Reprodução: 2 eventos e diagnóstico positivo de prenhez.
- Nutrição: plano e consumo carregados.
- Financeiro: 4 lançamentos e integração automática de Nutrição/Sanidade.
- Estoque: 3 produtos e quantidades persistidas.
- Agenda: 4 compromissos persistidos, com Lista/Semana/Mês disponíveis.

## Inconsistências encontradas e corrigidas nesta versão

### 1. Status do Rebanho

O Rebanho só considerava `Ativo` e ignorava o valor canônico de backend `active`.
A contagem e o filtro agora aceitam ambos.

### 2. Nutrição isolada do desempenho real

O plano exibido mantinha `GMD observado = 0` mesmo com pesagens suficientes no Rebanho.
A Nutrição agora enriquece o plano com os animais atuais do lote, peso médio e GMD calculado pelas duas últimas pesagens de cada animal.

Isso também faz o total de animais do plano acompanhar a composição atual do lote após movimentações.

### 3. Ingredientes em 0,0 kg

A carga/backend existente guardava ingredientes em percentual (`percentage`) enquanto o Flutter esperava `inclusionKg`.
O parser agora converte percentuais em kg/animal/dia usando o fornecimento diário do plano.

Quando ingredientes não possuem custo unitário, o custo oficial do plano é preservado, evitando zerar o custo da dieta.

### 4. Timeline com duplicidade semântica

Pesagens, Reprodução, Sanidade e Movimentações eram mostradas duas vezes: uma pelo módulo especializado e outra pela Timeline Enterprise.
A Timeline agora mantém a representação especializada e inclui Enterprise somente quando o ID do evento ainda não estiver representado.

## Próximos riscos previstos

- Baixa automática de estoque por Sanidade/Nutrição deve ser validada com operações destrutivas controladas antes de produção real.
- Edição/exclusão de eventos de origem precisa garantir reversão/idempotência financeira.
- Agenda precisa de teste transacional de editar/concluir/excluir em Lista, Semana e Mês.
- Secure Storage do Windows apresentou corrupção em execução anterior; deve receber recuperação automática antes da etapa Android.
- O banco contém valores de status históricos em português e inglês; recomenda-se migração futura para enum canônico no backend.

## Critério de avanço

A partir desta versão, a homologação visual deve confirmar principalmente:

1. Rebanho e contagem de ativos;
2. Nutrição com GMD e ingredientes em kg;
3. Timeline sem eventos duplicados.

Depois disso o projeto pode avançar para testes transacionais e Android.
