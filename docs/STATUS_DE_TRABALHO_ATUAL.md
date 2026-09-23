# Status de trabalho atual — Atlas

Atualizado em 23/09/2026.

## Estado

- Situação: usuário confirmou login online mais rápido e cadastrou o PIN offline; cobertura da última pesagem de Corte concluída e validada.
- Etapa atual: conferência visual do painel de Corte com dados reais e teste de desbloqueio offline com o PIN recém-configurado.
- Progresso: cobertura da última pesagem 100%; acesso local-primeiro 98% até teste explícito de desbloqueio offline; GMD pareado 99% até conferência visual.
- Componentes concluídos: calculador de cobertura de pesagens de animais ativos, análise e painel técnico de Corte; série histórica geral preservada.
- Validações concluídas: 11 testes de Corte/painel passaram; `flutter analyze` dos seis arquivos envolvidos sem problemas; builds Windows debug e release com URL de produção aprovados. O release atualizado foi reaberto em 23/09 (PID 4252, janela responsiva). Casos de animal vendido mais recente, duplicidade, datas futuras, peso inválido e ausência de rebanho cobertos.
- Checkpoint Git: `2c61932` — `fix(beef): scope latest weighing coverage to active animals`.
- Componentes verificados neste pacote: `scripts/build_atlas_windows_production.ps1`, build Windows release com `ATLAS_ENV=production` e `ATLAS_API_BASE_URL=https://atlas-api-29y2.onrender.com/api/v1`, e janela `projeto_atlas` de produção.
- Validações concluídas neste pacote: endpoint `/api/v1/health/ready` retornou HTTP 200; `flutter build windows --release` concluiu; processo release PID 3380 aberto e responsivo. A execução debug anterior usava `127.0.0.1:8000` por não receber `dart-define`, o que explica a falha de conexão mostrada pelo usuário.
- Validação restante de acesso: autenticação real pelo usuário e criação do PIN em Configurações → Segurança e acesso; sem esse vínculo previamente autorizado, o aplicativo não deve liberar entrada offline.
- Contexto da validação anterior: o APK Android atual foi gerado e os testes do cálculo passaram. A compilação Windows estava lenta, mas concluiu após a geração do snapshot Dart; não havia falha do MSBuild.
- Componentes implementados: GMD calculado com primeira e última pesagem válida de cada animal ativo nos últimos 12 meses; painel informa quantos animais têm pares válidos e sinaliza amostra pequena; parser rejeita datas impossíveis.
- Validações concluídas: testes de pareamento, exclusão de dados inválidos, contrato do painel e APK Android debug aprovado (SHA-256 `01E0CA243AA48DE987C7486B9894A99AF31956B653439B8D19AD72D8A7C93226`).
- Checkpoint Git publicado: `d24dc6f` — `fix(beef): calculate gain from paired animal weights`.
- Validação restante: conferir no painel de Corte, com sessão da fazenda, os números e alertas apresentados para pesagens reais.
- Próximo marco: validar o desbloqueio offline pelo usuário, conferir GMD/cobertura com dados reais e seguir para a próxima lacuna técnica de Corte.

## Próximo pacote planejado

Conferir o GMD e a cobertura de pesagens no painel de Corte com sessão da fazenda. Validar uma abertura offline com o PIN cadastrado. O OCR local depende de teste com nota real no aparelho.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
