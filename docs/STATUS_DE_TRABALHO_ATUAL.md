# Status de trabalho atual — Atlas

Atualizado em 18/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: acesso offline explícito e mensagem de conexão honesta.
- Progresso: 95%.
- Componentes concluídos: entrada com credenciais online separada do desbloqueio local com PIN; ação “Entrar offline com PIN” em destaque quando houver contexto; mensagem de indisponibilidade condicionada à existência real de acesso offline.
- Validações concluídas: contrato de interface e contratos do fluxo de sessão aprovados.
- Validação em diagnóstico: a análise Flutter continua sujeita a lentidão local do processo de compilação, já isolada do código e sem erros de formatação.
- Próximo marco: checkpoint Git publicado e, na próxima conexão bem-sucedida, configurar o PIN deste dispositivo para habilitar o caminho offline.

## Próximo pacote planejado

Qualificar a base de dados do rebanho de Corte, explicitando registros incompletos sem esconder indicadores calculados com base válida.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
