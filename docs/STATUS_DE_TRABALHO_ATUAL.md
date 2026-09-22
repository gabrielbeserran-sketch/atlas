# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: alertas operacionais unificados de Leite e Corte.
- Progresso: 90%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes concluídos: alertas de Leite e Corte foram centralizados antes dos indicadores no painel técnico, com título específico da produção e contagem de itens que exigem revisão. Os cartões duplicados dos módulos foram removidos sem perder conteúdo.
- Validações concluídas: contrato de apresentação do painel, testes de produção diária de Leite e de indicadores de Corte aprovados; formatação e verificação de diff limpo aprovadas.
- Validação pendente: checkpoint Git e publicação.
- Próximo marco: publicar a leitura operacional única dos dados técnicos que precisam de revisão.

## Próximo pacote planejado

Publicar os alertas técnicos unificados e, em seguida, retomar a inspeção visual Windows quando a cadeia MSBuild estiver disponível.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
