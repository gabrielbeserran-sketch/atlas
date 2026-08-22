# Atlas V20.5 — Validação, feedback e ações destrutivas

## Objetivo
Uniformizar o comportamento dos fluxos operacionais sem alterar contratos de backend ou regras pecuárias.

## Entrega
- Feedback único para formulários inválidos: o usuário recebe orientação e os campos continuam destacados pelo `Form`.
- Confirmação destrutiva única, não dispensável por toque externo, com linguagem clara e ação vermelha.
- Padronização aplicada a Animal, Lotes, Sanidade, Reprodução, Estoque, Financeiro e Agenda.
- Exclusão segura aplicada a Sanidade, Reprodução, Nutrição, Estoque, Financeiro e Agenda.
- Preservação do contexto: formulários continuam retornando seus modelos ao chamador; persistência permanece nas telas/serviços existentes.
- Nenhum endpoint, DTO, regra de cálculo ou contrato de persistência foi substituído.

## Critérios de regressão
1. O usuário nunca deve perder dados por fechar acidentalmente uma confirmação destrutiva.
2. Formulário inválido deve explicar que existem campos a revisar.
3. Criar e editar devem usar a mesma tela e o mesmo caminho de persistência já homologado.
4. Cancelar deve voltar ao contexto anterior sem gravar.
5. Nenhuma nomenclatura de desenvolvimento deve ser adicionada à camada de apresentação.
