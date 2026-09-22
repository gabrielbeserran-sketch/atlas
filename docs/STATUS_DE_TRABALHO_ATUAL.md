# Status de trabalho atual — Atlas

Atualizado em 18/09/2026.

## Estado

- Situação: em execução.
- Etapa atual: entrada local imediata e sincronização em segundo plano.
- Progresso: 90%.
- Componentes concluídos: formulário liberado durante a verificação de saúde, carteira local filtrada pela empresa, abertura imediata após autenticação quando houver contexto local e sincronização de sessão/fazendas em segundo plano com aviso de modo offline.
- Validações concluídas: contratos do controlador de sessão, contrato do login, dois testes de cálculo de Corte e análise estática Flutter.
- Validação em diagnóstico: o build Windows terminou a geração Dart, mas o processo nativo de instalação local não finalizou; a alteração não depende dele para o Android e será revalidada no próximo build limpo.
- Próximo marco: registrar o checkpoint do pacote acumulado e retomar a validação do artefato Windows sem bloquear a evolução local.

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
