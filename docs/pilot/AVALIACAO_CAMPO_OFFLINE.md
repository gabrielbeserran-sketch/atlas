# Avaliação agrupada de Campo sem internet

Versão Windows profile de avaliação 3, código dd47b57. Não é release de distribuição nem atualização do celular.

## Preparação

1. Entre com sua conta e selecione a fazenda autorizada. Configure o PIN caso ainda não exista; não use Sair para simular perda de internet, pois essa ação encerra a sessão.
2. Abra Campo. A abertura usa dados locais e não inicia a consulta de piquetes no servidor. Se não houver cópia, deve aparecer Não consultado, não zero.
3. Com conexão, toque Atualizar no painel ou consulte Piquetes e pastagens. Confirme a lista e a data da consulta. Uma lista realmente vazia deve ser distinguida da ausência de consulta.

## Ensaio manual

### Operações por fazenda (próxima compilação agrupada)

1. Com duas fazendas autorizadas, registre uma tarefa diferente em cada uma. Não use dados pessoais ou custos reais para ensaio descartável.
2. Pela Central acessada de Campo, edite a tarefa da fazenda A; volte à B e confirme que a tarefa dela permanece intacta. Exclua apenas a tarefa de teste de A e reconfira B.
3. Pelo dashboard, abra Operações: devem aparecer somente registros da fazenda ativa, nunca uma lista global. Sem sessão/fazenda autorizada, deve haver aviso, sem navegação nem tentativa de conexão.
4. Registros legados sem fazenda permanecem armazenados, mas não são atribuídos implicitamente à fazenda selecionada. Não os apagar ou reassociar por nome para passar no teste.
5. Faça o ensaio no aplicativo atualizado; testes automatizados não comprovam a versão que está aberta. A fila de escrita só serializa chamadas no mesmo processo, não duas janelas independentes.

6. Na versão com proteção contínua, altere a fazenda/conta por um fluxo permitido da sessão enquanto a rota antiga existir. A Central antiga deve sair da exibição e exigir reabertura; um novo login não reativa a mesma rota. Uma ação ainda pendente antes da chamada ao plugin não pode gravar no contexto anterior.

A reassociação do armazenamento legado continua separada. A guarda confere notificações de contexto local e não detecta revogação remota sem atualização de sessão. Não cancela uma escrita já entregue ao plugin e não serializa processos independentes.

### Armazenamento v2 de Operações

- A compilação com isolamento v2 guarda novas tarefas por tenant, empresa e fazenda; Central e painel Campo consultam a mesma chave. Trocar de empresa mesmo com o mesmo nome/ID de fazenda não deve revelar tarefas anteriores.
- A lista v1 permanece intacta. Como não contém proprietário empresarial verificável, não é copiada automaticamente para v2. A Central avisa sobre o legado sem revelar títulos ou valores.
- Esse aviso não significa exclusão. A versão com recuperação assistida oferece ao administrador Revisar operações antigas, com declaração de autorização, seleção individual e confirmação do destino. Não recriar custos reais ou excluir a lista antiga para contornar a validação.
- Fechar/reabrir sem “Sair” e com PIN permite conferir a persistência de uma tarefa v2 autorizada. Não considerar esse ensaio aprovado apenas pela reconstrução do repositório nos testes.

### Recuperação assistida do legado

1. Administrador abre Operações na fazenda correta e toca Revisar operações antigas. Operadores comuns não recebem esse comando.
2. Antes de carregar títulos/valores, declara autorização para revisar o legado deste dispositivo. Isso é declaração humana, não prova técnica de propriedade.
3. Seleciona apenas registros comprovadamente pertencentes à empresa/fazenda escolhida e confere ID, vínculo antigo, data e custo. A origem pode não ter fazenda ou ter vínculo diferente; somente o administrador confirma atribuição explícita.
4. Confirma o destino no diálogo. Cancelamento não grava; registros alterados desde a revisão, IDs ambíguos ou conflitos no destino impedem importação. O lote é validado antes da escrita.
5. Confere tarefas na Central e painel Campo. Repetir a mesma cópia no mesmo destino não duplica nem desfaz edições da cópia. A lista v1 permanece intacta.
6. Proveniência de recuperação está incorporada à tarefa v2 com autor/data/origem/destino e confirmação, preservada na edição. Não é trilha imutável, exportação de auditoria ou sincronização entre dispositivos; excluir a cópia também remove essa proveniência do v2. A origem v1 não é apagada.

Não executar este roteiro com dados de outro cliente ou dispositivo compartilhado sem autorização. O recurso não consulta servidor para comprovar propriedade empresarial de registros legados.

1. Desconecte a rede por conta própria e volte a Campo: a referência datada deve continuar disponível sem aguardar a API.
2. Abra Piquetes e pastagens e Suporte. A referência oficial deve manter sua data; ela não substitui medições de pasto nem confirma área efetiva.
3. Toque Atualizar sem conexão: a tentativa remota é limitada a oito segundos, sem apagar a cópia nem alterar sua data. A tela continua navegável.
4. Feche e reabra o aplicativo, sem tocar Sair. Entre offline com seu PIN e confira a mesma fazenda e referência. Esta etapa depende do usuário: não é automatizada nem considerada aprovada pelo build.
5. Se houver mais de uma fazenda autorizada, troque a fazenda. Dados da anterior não devem aparecer na seguinte; nomes iguais não autorizam compartilhamento.
6. Reconecte e atualize: somente uma consulta concluída deve renovar a data. Rejeição explícita 401/403 exige conferir sessão/permissões; não é tratada como falha transitória de rede.

## Limites e registro

- Cadastro, edição e exclusão de piquetes continuam exigindo confirmação da API; a cópia é de leitura.
- O painel não cria novas tarefas demonstrativas; tarefas antigas de outros fluxos não foram migradas por este pacote.
- Registre versão, fazenda (sem credenciais), etapa, resultado esperado/observado e horário. Não envie PIN, senha ou chaves.
- Testes automatizados validam leitor/cache/escopo; não substituem os passos reais de conexão, persistência do PIN e reabertura.
