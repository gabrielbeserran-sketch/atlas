# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: concluída e publicada.
- Etapa concluída: reforço da qualidade de dados comerciais e sanitários do rebanho de Corte.
- Progresso: 100%.
- Contexto da validação anterior: o contrato de sessão passou, mas a cadeia nativa do build Windows permaneceu parada sem uso de CPU; os processos iniciados para a validação foram encerrados sem alterar código ou dados da fazenda. A validação visual será repetida em ambiente limpo.
- Componentes concluídos: validação estrita de datas de venda e óbito, alertas claros para data ausente ou inválida e testes que garantem exclusão de registros malformados dos denominadores.
- Validações concluídas: testes do calculador de Corte e do fluxo de sessão aprovados; formatação e verificação de diff limpo aprovadas.
- Checkpoint publicado: `72d1b4a` — `fix(beef): reject invalid commercial event dates`.
- Próximo marco: repetir a validação visual da entrada local-primeiro em ambiente Windows limpo; a etapa depende apenas da cadeia nativa local, não de alteração de dados ou de servidor.

## Próximo pacote planejado

Repetir a validação visual da entrada local-primeiro em ambiente Windows limpo, isolando a cadeia nativa que ficou parada na tentativa anterior.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
