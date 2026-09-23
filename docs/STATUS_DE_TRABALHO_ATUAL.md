# Status de trabalho atual — Atlas

Atualizado em 23/09/2026.

## Estado

- Situação: build Windows recuperado e aplicativo atual aberto; conferência visual do GMD pelo usuário pendente.
- Etapa atual: validar na interface o ganho médio diário pareado de Corte.
- Progresso: 99% do pacote de GMD.
- Componentes verificados neste pacote: build Windows debug, `kernel_blob.bin` atualizado em 23/09 e janela `projeto_atlas` reiniciada com os arquivos novos.
- Validações concluídas neste pacote: `flutter build windows --debug -v` terminou com 0 avisos e 0 erros; processo `projeto_atlas` (PID 14936) aberto e responsivo.
- Contexto da validação anterior: o APK Android atual foi gerado e os testes do cálculo passaram. A compilação Windows estava lenta, mas concluiu após a geração do snapshot Dart; não havia falha do MSBuild.
- Componentes implementados: GMD calculado com primeira e última pesagem válida de cada animal ativo nos últimos 12 meses; painel informa quantos animais têm pares válidos e sinaliza amostra pequena; parser rejeita datas impossíveis.
- Validações concluídas: testes de pareamento, exclusão de dados inválidos, contrato do painel e APK Android debug aprovado (SHA-256 `01E0CA243AA48DE987C7486B9894A99AF31956B653439B8D19AD72D8A7C93226`).
- Checkpoint Git publicado: `d24dc6f` — `fix(beef): calculate gain from paired animal weights`.
- Validação restante: conferir no painel de Corte, com sessão da fazenda, os números e alertas apresentados para pesagens reais.
- Próximo marco: obter essa conferência e tornar a cobertura da última pesagem restrita a animais ativos.

## Próximo pacote planejado

Conferir o GMD pareado na janela Windows aberta; depois, qualificar a cobertura da última pesagem para contar apenas animais ativos. Em paralelo, testar o OCR local em aparelho com uma nota real quando o celular estiver disponível.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
