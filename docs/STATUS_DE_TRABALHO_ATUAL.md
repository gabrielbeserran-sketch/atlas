# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: cálculo confiável do ganho médio diário de Corte.
- Progresso: 95%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes concluídos: a série preserva a data real da última pesagem e ignora registros futuros; o painel exibe data e idade da medição, além da cobertura da amostra; após 90 dias, a seção de dados a revisar orienta a atualização antes do uso de GMD e peso por hectare.
- Componentes implementados: GMD calculado com primeira e última pesagem válida de cada animal ativo nos últimos 12 meses; painel informa quantos animais têm pares válidos e sinaliza amostra pequena; parser rejeita datas impossíveis.
- Validações concluídas: testes de pareamento, exclusão de pesos e datas inválidos e contrato do painel aprovados.
- Validações concluídas: testes de pareamento, exclusão de dados inválidos, contrato do painel e APK Android debug aprovado (SHA-256 `01E0CA243AA48DE987C7486B9894A99AF31956B653439B8D19AD72D8A7C93226`).
- Validações restantes: checkpoint Git e publicação.
- Próximo marco: publicar o cálculo rastreável sem instalar o APK no aparelho nesta etapa.

## Próximo pacote planejado

Concluir o GMD pareado de Corte; depois, retomar a inspeção visual Windows quando a cadeia MSBuild estiver disponível.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
