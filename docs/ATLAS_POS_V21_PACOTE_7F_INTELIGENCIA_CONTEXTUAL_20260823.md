# Atlas Pós-V21 — Pacote 7F: Inteligência Contextual

## Baseline

Pacote 7E homologado no Windows com toda a cadeia anterior aprovada.

## Princípio

O 7F é uma camada de leitura. Ele não grava, não corrige e não cria registros.

As respostas são montadas a partir dos serviços oficiais já existentes e
sempre informam as fontes utilizadas. Quando faltam dados, o Dr. Beserra
declara a insuficiência em vez de completar lacunas por inferência.

## Perguntas contextuais iniciais

### O que merece atenção hoje?

Cruza:
- Agenda;
- Financeiro;
- Estoque;
- Nutrição.

Destaca apenas condições objetivas:
- atividades atrasadas;
- prioridades cadastradas para hoje;
- despesas vencidas;
- estoque baixo/zerado;
- ganho observado abaixo da meta nutricional cadastrada.

A resposta deixa explícito que os pontos não constituem diagnóstico automático.

### Como estão as matrizes?

O Dr. Beserra não considera qualquer fêmea automaticamente como matriz.

Primeiro exige animais classificados no Rebanho como `Matriz/Matrizes`.
Sobre esse conjunto consulta os registros oficiais de Reprodução e resume o
último diagnóstico de gestação disponível.

Mostra:
- quantidade cadastrada;
- último diagnóstico positivo;
- último diagnóstico negativo;
- matrizes sem diagnóstico conclusivo;
- cobertura dos diagnósticos no conjunto analisado.

Para não gerar dezenas de chamadas simultâneas ao Render, o detalhamento é
limitado a 40 matrizes e as leituras reprodutivas são executadas em lotes de
cinco requisições.

A resposta é apresentada como resumo de registros, nunca como diagnóstico
veterinário.

### Qual lote está pior?

A primeira comparação contextual de lote é estritamente nutricional.

Somente entram lotes/planos que possuem:
- meta de ganho diário maior que zero;
- ganho observado maior que zero.

O lote com menor relação `ganho observado / meta` é apresentado como o lote
que mais merece atenção dentro dessa comparação.

Se esses dados não existirem, o Dr. Beserra se recusa a apontar um pior lote.

A resposta não atribui causa ao desempenho.

### O que está pesando no financeiro?

Usa os lançamentos oficiais do Financeiro.

Apresenta:
- até três maiores categorias de despesas registradas;
- total pendente;
- total vencido.

A linguagem foi deliberadamente construída para respeitar o ciclo pecuário.
Pressão de caixa ou saldo temporário não é automaticamente tratado como
fracasso, prejuízo estrutural ou fazenda "no vermelho".

O resumo informa que seria necessário considerar ciclo produtivo e
planejamento antes de classificar a saúde do negócio.

## Transparência de fonte

O `DrBeserraReply` contextual inclui no texto as fontes utilizadas, por
exemplo:

`Fontes: Agenda, Financeiro, Estoque, Nutrição.`

Quando os dados não permitem conclusão:

`Dados insuficientes para uma conclusão mais forte.`

## Segurança

O serviço contextual não possui:
- create;
- update;
- delete;
- movimentação de estoque;
- baixa de Agenda;
- HTTP direto;
- SharedPreferences;
- banco local.

A voz continua sendo somente transporte:

`microfone -> transcrição -> sendText -> gateway`

Nenhuma inteligência de negócio foi movida para a camada de voz.

## Prevenção

Novo gate:
`tools/atlas_post_v21_package7f_contextual_intelligence_gate.py`

Ele bloqueia:
- escrita pela camada contextual;
- uso de HTTP/banco direto;
- resposta de pior lote sem dados comparáveis;
- inferência automática de matrizes;
- ausência de limites de diagnóstico;
- interpretação financeira simplista;
- perda do batching de Reprodução;
- ausência de transparência de fontes;
- inteligência de negócio dentro da camada de voz.

O gate de helpers privados órfãos também passou a auditar o novo serviço
contextual.

## Backend e banco

Nenhuma alteração.
Nenhuma migration.
Os serviços oficiais de Render + Supabase já existentes foram reutilizados.
