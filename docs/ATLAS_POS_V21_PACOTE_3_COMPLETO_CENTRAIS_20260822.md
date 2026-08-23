# Atlas Pós-V21 — Pacote 3 completo

## Arquitetura das centrais
O Pacote 3 passa a cobrir as áreas gerais da fazenda usando o mesmo padrão:
**situação → atenção → ação**.

### Campo e Pastagens
O item Campo passa a abrir a `Central de Campo`, vinculada à fazenda ativa.
Ela consolida:
- piquetes e pastagens;
- ocupação e descanso;
- operações abertas e atrasadas;
- responsáveis/equipe vinculados às operações;
- equipamentos e custos através do Centro de Operações existente;
- ferramentas de campo e fila offline existente.

Nenhum armazenamento novo foi criado.

### Estoque/Suprimentos
O menu deixa de pular direto para a lista de produtos e passa pela Central de
Estoque. A central mostra produtos sem estoque, abaixo do mínimo, vencidos,
próximos do vencimento e valor armazenado. A ação `Gerenciar estoque` abre o
CRUD canônico existente.

### Financeiro
O menu passa a abrir a Central Financeira. O módulo diferencia:
- realizado;
- pendente a pagar;
- pendente a receber;
- vencido.

Um saldo negativo isolado não é tratado automaticamente como falha: a leitura
orienta o usuário a considerar o ciclo produtivo pecuário e o planejamento do
investimento. Compromissos vencidos continuam sendo prioridade operacional.

### Inteligência e Relatórios
Não foram fundidos porque cumprem papéis diferentes:
- **Inteligência** interpreta, recomenda, simula e exige aprovação humana;
- **Relatórios** documentam, comparam, exportam e acompanham planos de ação.

A Inteligência recebeu acesso direto aos Relatórios gerenciais para eliminar
navegação desnecessária sem duplicar suas funções.

### Operações e Equipe
A equipe não ganhou um CRUD paralelo. A Central de Campo calcula a equipe
operacional a partir dos responsáveis e membros já vinculados às operações
existentes. O Centro de Operações continua sendo o dono das atividades,
responsáveis, equipes, equipamentos, custos, prazos e execução.
