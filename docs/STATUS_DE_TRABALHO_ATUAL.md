# Status de trabalho atual — Atlas

Atualizado em 23/09/2026.

## Estado

- Situação: implementada e publicada; inspeção visual Windows pendente.
- Etapa atual: cálculo confiável do ganho médio diário de Corte.
- Progresso: 98%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes implementados: GMD calculado com primeira e última pesagem válida de cada animal ativo nos últimos 12 meses; painel informa quantos animais têm pares válidos e sinaliza amostra pequena; parser rejeita datas impossíveis.
- Validações concluídas: testes de pareamento, exclusão de dados inválidos, contrato do painel e APK Android debug aprovado (SHA-256 `01E0CA243AA48DE987C7486B9894A99AF31956B653439B8D19AD72D8A7C93226`).
- Checkpoint Git publicado: `d24dc6f` — `fix(beef): calculate gain from paired animal weights`.
- Validação restante: inspeção visual Windows, dependente da recuperação da cadeia MSBuild local.
- Próximo marco: concluir a validação Windows e tornar a cobertura da última pesagem restrita a animais ativos.

## Próximo pacote planejado

Validar o GMD pareado no Windows quando a cadeia MSBuild estiver disponível; qualificar a cobertura da última pesagem para contar apenas animais ativos.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
