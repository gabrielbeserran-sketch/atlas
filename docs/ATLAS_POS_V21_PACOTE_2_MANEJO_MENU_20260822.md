# Atlas Pós-V21 — Pacote 2: Realizar manejo + menu operacional

## Objetivo
Transformar "Realizar manejo" em uma operação coletiva real, sem criar uma tela
intermediária ou um CRUD paralelo.

## Seleção de animais
- Lote inteiro.
- Intervalo de brincos.
- Seleção manual com busca.
- RFID permanece apenas no contrato de domínio para a futura etapa de hardware;
  não é exibido como função disponível antes de existir integração real.

## Ações transacionais
O endpoint oficial é `POST /api/v1/livestock/handling/batch`.

Ações:
- venda/saída;
- movimentação de lote;
- pesagem coletiva com peso individual por animal;
- sanidade;
- reprodução;
- alteração de categoria.

A operação usa os IDs oficiais dos animais e uma única transação de banco.

### Venda/saída
- registra movimentação individual;
- retira os animais do lote e marca status de saída;
- registra metadados da venda;
- cria uma única receita financeira do lote vendido;
- a receita nasce como `pending`, evitando afirmar que o dinheiro foi recebido.

### Sanidade
- cria um evento por animal;
- mantém o vínculo com lote;
- gera custo financeiro quando informado;
- cria/atualiza retorno operacional quando existe próxima data.

### Reprodução
- cria evento por animal;
- atualiza estado reprodutivo;
- cria retorno operacional quando existe previsão/próxima data.

### Pesagem
- exige peso individual de todos os animais selecionados;
- atualiza peso/ECC do animal;
- preserva histórico e sincronização de tarefa de pesagem.

## Menu principal
O menu cotidiano deixa de expor ferramentas de desenvolvimento/implantação:
Precision Hub, Enterprise, SaaS, Dados, Segurança, Qualidade, Prontidão,
Releases, Comercial de prontidão, Piloto, Publicação e Escala.

Permanecem os módulos operacionais e "Realizar manejo". O centro Offline foi
preservado porque é uma capacidade funcional importante até receber um acesso
mais contextual no futuro.

## Implantação
O Pacote 2 altera backend, mas não requer migração de banco.

Primeiro rode a homologação local. Depois publique no Git/Render e execute
`check_post_v21_package2_deployed.ps1`, que confirma pelo OpenAPI remoto que o
novo endpoint foi realmente publicado.
