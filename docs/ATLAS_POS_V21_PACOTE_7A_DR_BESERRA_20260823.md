# Atlas Pós-V21 — Pacote 7A: Dr. Beserra

## Objetivo

Primeira camada conversacional segura do Atlas.

O Dr. Beserra aparece no grupo `Hoje` e depende da fazenda ativa. Nesta versão
ele funciona por texto e foi deliberadamente limitado a comandos que podem ser
garantidos pelos serviços oficiais já existentes.

## O que já faz

### Agenda

- responde o que existe para fazer hoje;
- usa `FarmAgendaStorageService.loadTasks`;
- entende frases simples como:
  - `o que tenho hoje?`;
  - `serviço de hoje`;
  - `trabaio de hoje`;
  - `o que é pra fazer hoje`;
- entende intenção de conclusão:
  - `terminei vacinação`;
  - `acabei vacinação`;
  - `fiz vacinação`;
- procura somente tarefas pendentes;
- se houver mais de uma correspondência, não escolhe sozinho;
- pede confirmação antes de concluir;
- depois da confirmação usa `FarmAgendaStorageService.updateTask`;
- relê a Agenda e só informa sucesso quando o servidor devolve a tarefa
  concluída.

### Navegação segura

Assuntos que ainda exigem dados técnicos completos não são gravados pelo
chatbot. O Dr. Beserra apenas leva o usuário ao módulo oficial:

- manejo → `Realizar manejo`;
- vacina, tratamento, vermífugo → `Sanidade`;
- IATF, inseminação, prenhez → `Reprodução`;
- animal, brinco, gado → `Rebanho`;
- compromisso/tarefa → `Agenda`.

Assim, o chatbot não cria registros parciais, não inventa IDs e não escreve
diretamente em banco ou HTTP.

## Linguagem do campo

Foi criada `DrBeserraLanguageService`, com normalização de acentos e um
vocabulário inicial que inclui formas simples e coloquiais, como `trabaio`,
`brete`, `vacinei`, `vermifuguei`, `acabei` e `terminei`.

Esse dicionário não é tratado como inteligência final. Ele é a camada
determinística de segurança que continuará existindo mesmo quando interpretação
por IA/voz for adicionada.

## Regra de segurança

No Pacote 7A existe apenas uma escrita conversacional permitida:

`concluir tarefa da Agenda`

Condições:
1. fazenda ativa com ID oficial;
2. tarefa encontrada na Agenda oficial;
3. tarefa não concluída/cancelada;
4. correspondência não ambígua;
5. confirmação explícita do usuário;
6. `updateTask` oficial;
7. nova leitura e confirmação da persistência.

Sanidade, Reprodução e Manejo possuem zero escrita direta pelo chatbot nesta
etapa.

## Voz

Nenhuma captura de voz fictícia foi adicionada. A interface é text-first.
Reconhecimento de voz entra no Pacote 7B sobre o mesmo gateway seguro, para que
voz e texto obedeçam exatamente às mesmas permissões e confirmações.

## Backend e banco

Nenhuma alteração de backend, banco ou migration foi necessária no Pacote 7A.
