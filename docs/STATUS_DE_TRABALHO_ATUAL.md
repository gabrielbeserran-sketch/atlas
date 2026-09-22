# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: rastreabilidade das pesagens nos indicadores de Corte.
- Progresso: 90%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes concluídos: o painel informa a cobertura da última pesagem e o número de animais na primeira e na última medição usadas no GMD; alerta quando faltam duas pesagens ou quando a última amostra cobre menos de 50% dos animais ativos; a orientação aparece na seção unificada de dados a revisar do Corte.
- Validações concluídas: contrato de painel, testes de indicadores de Corte e de produção diária de Leite aprovados; formatação e verificação de diff limpo aprovadas.
- Validação pendente: checkpoint Git e publicação.
- Próximo marco: publicar a rastreabilidade das pesagens para que o produtor interprete o GMD com a cobertura correta.

## Próximo pacote planejado

Concluir a rastreabilidade das pesagens no Corte; depois, retomar a inspeção visual Windows da entrada local-primeiro quando a cadeia MSBuild estiver disponível.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
