# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: atualidade e cobertura das pesagens de Corte.
- Progresso: 90%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes concluídos: a série preserva a data real da última pesagem e ignora registros futuros; o painel exibe data e idade da medição, além da cobertura da amostra; após 90 dias, a seção de dados a revisar orienta a atualização antes do uso de GMD e peso por hectare.
- Validações concluídas: contratos de série e de painel, além dos testes de indicadores de Corte, aprovados; formatação e verificação de diff limpo aprovadas.
- Validações concluídas: contratos de série e de painel, testes de Corte e APK Android debug atual gerado sem instalação; SHA-256 `1C38C6BDDB3C9FF74B4AC8753A734288D2351844D069E78B3D861B520BBC0320`.
- Validação pendente: checkpoint Git e publicação.
- Próximo marco: publicar a leitura de atualidade das pesagens e deixar o APK preparado para a próxima atualização acumulada do celular.

## Próximo pacote planejado

Concluir a atualidade das pesagens de Corte e gerar APK Android atual; depois, retomar a inspeção visual Windows da entrada local-primeiro quando a cadeia MSBuild estiver disponível.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
