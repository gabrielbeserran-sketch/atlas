# Atlas Pós-V21 — Pacote 7D: operações seguras do Dr. Beserra

## Baseline de entrada

Pacote 7C homologado no Windows:
- Flutter analyze sem problemas;
- 196 testes aprovados;
- toda a cadeia 6B → 6C → 6D-A → 6D-B → 6D-C → 6D-D → 7A → 7B → 7C aprovada.

## Objetivo

Permitir que o Dr. Beserra deixe de apenas abrir Sanidade, Reprodução e Manejo
quando a fala já contém dados suficientes para uma operação real.

A arquitetura é deliberadamente dividida em quatro etapas:

1. interpretar a frase;
2. montar um rascunho estruturado;
3. validar campos obrigatórios e pedir confirmação;
4. somente após confirmar, usar o serviço oficial e verificar o resultado.

## Sanidade

Exemplo suportado:

`vacinar brinco 101 com aftosa dose 5 ml responsável João`

Campos obrigatórios:
- brinco;
- tipo sanitário;
- produto;
- dose;
- responsável.

Depois da confirmação:
- o animal é localizado pela API oficial da fazenda;
- o lote oficial é localizado;
- é utilizado `AnimalHealthStorageService.createRecord`;
- o serviço já relê `/livestock/health`;
- o Dr. Beserra ainda exige `synced == true` e ID remoto antes de informar sucesso.

Também funciona para vermifugação e tratamento quando os dados obrigatórios
forem informados.

## Reprodução

Exemplos:

`fazer IATF no brinco 101 responsável João`

`diagnóstico de gestação brinco 205 prenhe responsável Maria`

Para diagnóstico de gestação, resultado é obrigatório.

Depois da confirmação:
- resolve animal e lote oficiais;
- usa `AnimalReproductionStorageService.createRecord`;
- exige resposta confirmada pelo serviço após nova leitura do servidor;
- nunca inventa animal ID.

## Manejo coletivo

Primeira operação conversacional em lote:

`mover brincos 100 a 120 para lote Recria responsável Pedro`

Fluxo:
- carrega os animais da fazenda pela API oficial;
- seleciona o intervalo de brincos;
- carrega lotes oficiais;
- resolve o lote de destino por correspondência segura;
- recusa lote ambíguo;
- pede confirmação;
- usa `FarmHandlingEnterpriseService.execute`;
- endpoint oficial: `/livestock/handling/batch`;
- exige `handlingId`;
- exige `affectedCount` igual ao número esperado antes de informar sucesso.

Isso atende ao requisito de não dar baixa ou movimentar animal por animal.

## Segurança

O Pacote 7D NÃO permite:
- venda/baixa por conversa;
- exclusão de registro;
- criação de animal;
- escrita direta por HTTP;
- escrita direta no banco/local storage;
- execução de rascunho incompleto;
- seleção ambígua de animal ou lote.

A camada de voz continua sem qualquer serviço de negócio. O áudio apenas
transcreve e passa pelo mesmo gateway.

## Evolução dos gates antigos

Os gates 7A, 7B e 7C foram atualizados para preservar seus invariantes
originais sem bloquear capacidades posteriores explicitamente confirmadas.

- 7A continua exigindo confirmação da Agenda e proíbe HTTP/banco direto;
- 7B continua exigindo voz sem escrita própria;
- 7C continua garantindo que a linguagem não conceda escrita por conta própria;
- 7D passa a ser o dono do contrato de escrita segura em Sanidade/Reprodução/Manejo.

## Prevenção

Novo gate:
`tools/atlas_post_v21_package7d_safe_operations_gate.py`

Ele bloqueia regressões de:
- operação sem confirmação;
- campo obrigatório ausente;
- ID inventado;
- HTTP/banco direto;
- perda dos serviços oficiais;
- ausência de confirmação pós-write;
- quantidade de manejo divergente;
- operação destrutiva pelo chatbot;
- escrita de negócio diretamente pela voz.

## Backend e banco

Nenhuma alteração.
Nenhuma migration.
Os endpoints oficiais já existentes foram reutilizados.
