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

O isolamento de armazenamento legado por tenant/empresa continua separado. A guarda confere notificações de contexto local e não detecta revogação remota sem atualização de sessão. Não cancela uma escrita já entregue ao plugin e não serializa processos independentes.

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
