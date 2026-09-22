# Status de trabalho atual — Atlas

Atualizado em 18/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: ativação guiada do acesso offline.
- Progresso: 90%.
- Componentes concluídos: o controlador expõe o estado real do PIN; a operação mostra um convite dispensável após a entrada autenticada; o convite abre Configurações e se reorganiza em telas estreitas sem sobreposição.
- Validações concluídas: contratos de sessão/navegação e de disponibilidade do login aprovados; formatação e verificação de diff limpo aprovadas.
- Validação pendente: checkpoint Git e publicação.
- Próximo marco: publicar a ativação guiada para que a entrada offline deixe de depender de o usuário descobrir a configuração por conta própria.

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
