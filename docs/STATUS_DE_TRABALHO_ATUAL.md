# Status de trabalho atual — Atlas

Atualizado em 22/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: reforço da qualidade de dados comerciais e sanitários do rebanho de Corte.
- Progresso: 90%.
- Contexto da validação anterior: o contrato de sessão passou, mas a cadeia nativa do build Windows permaneceu parada sem uso de CPU; os processos iniciados para a validação foram encerrados sem alterar código ou dados da fazenda. A validação visual será repetida em ambiente limpo.
- Componentes concluídos: validação estrita de datas de venda e óbito, alertas claros para data ausente ou inválida e testes que garantem exclusão de registros malformados dos denominadores.
- Validações concluídas: testes do calculador de Corte e do fluxo de sessão aprovados; formatação e verificação de diff limpo aprovadas.
- Validação pendente: checkpoint Git e publicação.
- Próximo marco: publicar a proteção contra datas impossíveis sem alterar os dados existentes da fazenda.

## Próximo pacote planejado

Concluir a qualidade de dados comerciais e sanitários do rebanho de Corte; em seguida, repetir a validação visual da entrada local-primeiro em ambiente Windows limpo.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
