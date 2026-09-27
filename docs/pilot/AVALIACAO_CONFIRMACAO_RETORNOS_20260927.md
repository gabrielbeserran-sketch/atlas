# Confirmação de retornos — 27/09/2026

## Fluxo entregue

No histórico reprodutivo individual, o menu do registro com previsão oferece concluir ou cancelar retorno. O diálogo pede responsável e exige motivo para cancelamento. A previsão e os resultados clínicos permanecem separados da baixa administrativa; concluir retorno não registra diagnóstico, parto, pagamento ou concepção.

A interface bloqueia ações concorrentes durante confirmação/gravação. O armazenamento relê o evento, exige contrato X-Atlas-Reproduction-Returns: v1 antes de enviar a baixa e recusa previsão alterada. Após PATCH exige releitura com auditoria correspondente e autoria autenticada registrada pelo servidor. Repetir uma baixa já confirmada no mesmo estado não reenvia PATCH. Sem confirmação, a interface mantém o retorno pendente; não existe nova fila de escrita offline neste pacote.

Auditoria local válida sem autoria do servidor é rascunho, não conclusão: permanece na triagem. O marcador de autoria e o cabeçalho constituem contrato com o servidor autenticado, não assinatura criptográfica nem trilha forense imutável. Cache antigo não recebe reparo automático.

## Validação local

89 testes Flutter de Reprodução/Leite/Corte aprovados, incluindo validação do diálogo, cancelamento sem baixa, menu/bloqueio, servidor antigo sem PATCH, servidor sem autoria, previsão alterada e retry sem escrita repetida. 14 testes Python executados diretamente com SQLite em memória, sem conftest que altera banco de teste. Análise estática dos componentes reprodutivos e testes sem apontamentos. Um overflow no menu foi detectado pelo teste e corrigido.

## Roteiro de aceite pendente

Build Windows profile oficial aprovado uma vez em 194,0 s. Artefato: release/windows/reproducao-confirmacao-20260927; identidade com.example/projeto_atlas; SHA-256 app.so FFD51511CF40054F5041C0EB72646D24D83F19B35F90683779559BF9B2D5251F. Checkpoint atlas-reproduction-return-confirmation-20260927. App anterior preservado, sem abertura ou instalação deste artefato.

1. Publicar backend autorizado e verificar contrato HTTP real em ambiente de avaliação. Servidor antigo é bloqueado sem enviar baixa; esta entrega não implantou o backend.
2. Com evento autorizado e previsão existente, concluir com responsável; reler histórico e conferir tarefa operacional correspondente.
3. Cancelar outro retorno com motivo; confirmar preservação da previsão/auditoria.
4. Repetir confirmação após resposta perdida e verificar envio único/estado já confirmado.
5. Desconectar: leitura de resolução previamente confirmada deve persistir, mas nova baixa não deve produzir sucesso falso.

Ainda pendentes: reconciliação com transições manuais de tarefas, ensaio HTTP/PostgreSQL/concorrência e dois dispositivos, autorização efetiva em produção e escrita offline idempotente. Nenhum dado real, login, PIN, OCR ou aplicativo do celular foi alterado.
