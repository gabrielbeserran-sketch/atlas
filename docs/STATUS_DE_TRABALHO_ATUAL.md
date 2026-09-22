# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: cobertura operacional da produção diária de Leite.
- Progresso: 90%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes concluídos: a cobertura válida dos últimos 30 dias, dias ausentes e percentual de regularidade são calculados; as métricas aparecem no módulo e no painel técnico; o alerta informa quantos dias faltam para a base mínima de 20 dias.
- Validações concluídas: testes unitários da produção diária e contrato de painel aprovados; formatação e verificação de diff limpo aprovadas.
- Validação pendente: checkpoint Git e publicação.
- Próximo marco: publicar a leitura de cobertura para que o produtor identifique imediatamente se a média de leite tem base suficiente.

## Próximo pacote planejado

Concluir a cobertura operacional da produção diária de Leite; depois, retomar a inspeção visual Windows da entrada local-primeiro quando a cadeia MSBuild estiver disponível.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
