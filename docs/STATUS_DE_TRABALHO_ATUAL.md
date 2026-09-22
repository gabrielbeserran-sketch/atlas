# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: qualidade da produção diária de Leite.
- Progresso: 90%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes concluídos: ordenhas futuras, duplicadas, negativas ou sem vacas ordenhadas ficam fora do cálculo; o módulo de Leite apresenta um cartão de qualidade da base; novos registros exigem ao menos uma vaca ordenhada.
- Validações concluídas: testes de produção diária, reprodução de Leite e sessão aprovados; formatação e verificação de diff limpo aprovadas.
- Validação pendente: checkpoint Git e publicação.
- Próximo marco: publicar a proteção para que litros/dia, L/ha e L/vaca reflitam somente dias operacionais válidos.

## Próximo pacote planejado

Qualificar a produção diária de Leite, garantindo que dias futuros, duplicados ou sem vacas ordenhadas não alterem litros/dia; em paralelo, retomar a inspeção visual Windows quando a cadeia MSBuild estiver disponível.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
