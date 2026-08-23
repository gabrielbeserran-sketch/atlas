# Atlas Pós-V21 — Pacote 7E: Rotina Diária Inteligente

## Baseline

Pacote 7D homologado no Windows com toda a cadeia anterior aprovada.

## Fonte única da rotina

A rotina diária é derivada exclusivamente da Agenda oficial da fazenda.
Não existe tabela paralela, cache próprio do Dr. Beserra ou agenda duplicada.

Foi criado `DrBeserraDailyRoutineService`, responsável apenas por interpretar
`FarmAgendaData`.

## Perguntas novas

O Dr. Beserra entende, entre outras:

- `o que falta fazer hoje?`
- `o que ficou atrasado?`
- `qual a prioridade hoje?`
- `o que tenho amanhã?`
- `por onde começo hoje?`

## Prioridade

A prioridade é determinística:

1. atividade atrasada;
2. prioridade Urgente cadastrada;
3. prioridade Alta cadastrada;
4. Normal;
5. Baixa;
6. dentro do mesmo nível, horário e título.

O Dr. Beserra não usa modelo generativo para inventar urgência.

## Módulo dono da tarefa

O serviço identifica se uma atividade exige registro técnico em:

- Sanidade;
- Reprodução;
- Realizar manejo;
- Nutrição;
- Estoque.

Atividades administrativas comuns continuam pertencendo apenas à Agenda.

## Regra contra duas verdades

Uma tarefa técnica não pode ser marcada como concluída apenas na Agenda pelo
Dr. Beserra.

Exemplo:

`terminei vacinação`

Se a atividade encontrada for sanitária, o Atlas informa que é necessário
registrar o fato técnico. Se a frase já possuir todos os campos necessários,
por exemplo:

`terminei vacinação brinco 101 com aftosa dose 5 ml responsável João`

o fluxo passa a ser:

1. localizar a tarefa pendente;
2. montar o rascunho sanitário;
3. pedir confirmação;
4. gravar no serviço oficial de Sanidade;
5. confirmar o retorno do servidor;
6. somente então marcar a Agenda como concluída;
7. confirmar também a baixa da Agenda.

O mesmo princípio é aplicado às operações de Reprodução e à movimentação
coletiva de Manejo que já são suportadas pelo 7D.

Nutrição e Estoque ainda não possuem escrita conversacional neste pacote.
Quando uma tarefa dessas precisa de registro técnico, o Dr. Beserra abre o
módulo dono em vez de concluir somente a Agenda.

## Falha parcial protegida

Existe uma situação importante: o registro técnico pode ser confirmado pelo
servidor e a atualização posterior da Agenda falhar.

Nesse caso o Dr. Beserra NÃO diz que nada aconteceu e NÃO manda repetir o
manejo. Ele informa explicitamente:

- o registro técnico foi confirmado;
- a Agenda não confirmou a baixa;
- não repetir a operação;
- abrir a Agenda para reconciliar.

Isso evita duplicação de vacinação, IATF ou movimentação por uma tentativa
repetida após falha parcial.

## Correspondência de linguagem

A localização da tarefa não depende mais somente do título completo.

O gateway utiliza:
- título;
- categoria;
- palavras significativas;
- módulo técnico esperado.

Assim frases naturais como `terminei IATF` ou `terminei vacinação da recria`
podem localizar tarefas maiores sem aceitar uma correspondência de módulo
errado. Se houver mais de uma candidata, o usuário precisa especificar melhor.

## Proteções

Novo gate:
`tools/atlas_post_v21_package7e_daily_routine_gate.py`

Ele bloqueia:
- fonte de rotina paralela à Agenda;
- prioridade inventada;
- baixa técnica isolada na Agenda;
- perda da relação operação ↔ tarefa;
- perda da confirmação pós-write;
- ocultação de falha parcial;
- HTTP/banco direto pelo Dr. Beserra;
- regra de negócio dentro da camada de voz;
- regressões dos contratos 7A–7D.

## Backend e banco

Nenhuma alteração.
Nenhuma migration.
Render + Supabase continuam sendo usados pelos serviços oficiais já existentes.
