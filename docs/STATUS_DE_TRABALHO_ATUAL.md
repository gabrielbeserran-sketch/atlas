# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: concluída e publicada.
- Etapa concluída: precisão do indicador por vaca na produção de Leite.
- Progresso: 100%.
- Contexto da validação anterior: o APK Android atual foi gerado e o contrato de sessão passou; a inspeção visual no Windows continua pendente porque o MSBuild local estaciona na etapa nativa, sem afetar código ou dados da fazenda.
- Componentes concluídos: L/vaca ordenhada usa soma de litros e de vacas de cada dia válido; L/vaca em lactação permanece explicitamente calculado a partir do último estado de lote; o módulo e o painel exibem as duas referências e a média diária de vacas ordenhadas.
- Validações concluídas: testes de média ponderada e contrato de painel aprovados; formatação e verificação de diff limpo aprovadas.
- Checkpoint publicado: `a8e84b1` — `feat(dairy): distinguish milked cow efficiency`.
- Próximo marco: retomar a inspeção visual Windows da entrada local-primeiro quando a cadeia MSBuild estiver disponível; novas ampliações técnicas seguem independentes dessa pendência.

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
