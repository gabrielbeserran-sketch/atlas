# Operações e Campo — avaliação Windows agrupada

Código funcional: c951e05. Compilação profile oficial, não instalador de distribuição nem versão demonstrativa. Executável preservado: C:/Projetos/Projetos Atlas/release/windows/operacoes-c951e05/projeto_atlas.exe.

SHA-256 de data/app.so: 559B471FC438EA4E9082CEFE453FC7862DFE8E6EAEA8C0B8377FD0D2490CE097. CompanyName com.example, ProductName projeto_atlas, entrada main.dart e URL oficial. Mesma identidade de armazenamento do Atlas; não abrir duas versões ao mesmo tempo. Não apagar dados/PIN para testar.

## O que avaliar

1. Entre pessoalmente e selecione a fazenda autorizada. Campo → Operações abre somente essa fazenda; o dashboard usa o mesmo contexto.
2. Crie uma tarefa identificada como TESTE, sem informações pessoais, para conferir leitura e edição. Se houver segunda fazenda autorizada, repita com outra tarefa e verifique que editar/excluir a primeira não altera a segunda. Não crie nova fazenda ou conta só para passar no teste.
3. Com sessão/PIN configurados, feche sem usar Sair, desligue a rede por conta própria e reabra com PIN. Confira tarefa e Campo. Esse ensaio não foi automatizado; login/PIN devem ser feitos pelo usuário.
4. Se houver operações antigas, o administrador pode usar Revisar operações antigas. Declare autorização, confira os registros e confirme somente a atribuição correta. Cancelar não copia, origem é preservada e repetir no mesmo destino não duplica. Não recuperar dados de outro cliente para preencher a interface.
5. Ao alterar contexto por fluxo permitido, a rota antiga é invalidada e uma ação ainda pendente antes de solicitar escrita não pode salvar nele. A revogação remota só é conhecida após atualização de sessão.

## Resultado a informar

Informe a etapa, o que esperava e o que apareceu, sem enviar senha/PIN. A abertura da tela de login não comprova navegação autenticada, recuperação real ou funcionamento completo offline.

Sem reinstalação Android, nova compilação ou sondagem externa neste pacote de abertura. Referência: 46 testes de regressão e nove focalizados finais do pacote funcional (47 casos distintos), análise e build anteriores aprovados; não repetidos sem mudança de código.

Limites: tarefas v2 locais não foram sincronizadas entre dispositivos por esta entrega. Proveniência de recuperação está no próprio registro, não em trilha externa imutável. Fonte v1 preservada; isolamento por chave não é criptografia nem trava entre processos. Homologações de banco/servidor e demais módulos seguem no cronograma geral.
