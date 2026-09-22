# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: concluída e publicada.
- Etapa concluída: atualidade dos dados técnicos de Leite.
- Progresso: 100%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes concluídos: a produção informa a data e a idade da última ordenha válida e alerta após três dias sem atualização; o painel técnico informa a idade do último estado do lote e orienta o produtor quando ele não existe ou está há mais de sete dias sem atualização.
- Validações concluídas: testes de atualidade da produção e contrato de painel aprovados; formatação e verificação de diff limpo aprovadas.
- Checkpoint publicado: `50b0e9f` — `feat(dairy): signal data freshness`.
- Próximo marco: retomar a inspeção visual Windows da entrada local-primeiro quando a cadeia MSBuild estiver disponível; futuras ampliações técnicas continuam independentes dessa pendência.

## Próximo pacote planejado

Retomar a inspeção visual Windows da entrada local-primeiro quando a cadeia MSBuild estiver disponível, sem reinstalar o APK até um conjunto maior de entregas.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
