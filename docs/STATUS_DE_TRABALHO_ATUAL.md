# Status de trabalho atual — Atlas

Atualizado em 23/09/2026.

## Estado

- Situação: série histórica de pesos de Corte concluída e publicada; o PIN offline está cadastrado, mas o desbloqueio sem internet ainda não foi testado.
- Etapa atual: avaliação visual da nova evolução mensal no painel de Corte e conferência do GMD/cobertura com dados reais.
- Progresso: série mensal 100%; acesso local-primeiro 98%; GMD pareado 99% até conferência visual.
- Componentes concluídos: agregador mensal de pesos por última medição válida de cada animal, serviço do painel e cartão de evolução com média e tamanho da amostra; série histórica geral inclui animais que integraram o rebanho naquele mês, enquanto a cobertura atual permanece restrita aos ativos.
- Validações concluídas: 16 testes de Corte/painel, análise estática sem problemas e build Windows debug com URL de produção. Repetição do mesmo animal, pesos zero/negativos/não finitos, datas futuras e mês vazio cobertos.
- Checkpoint Git: `c400d57` — `feat(beef): show reliable monthly weight evolution`.
- Componentes concluídos: modelo de cobertura, cartão do número de animais ativos sem pesagem recente e alerta de baixa cobertura com o déficit da amostra.
- Validações concluídas: 13 testes de Corte/painel, análise estática sem problemas e build Windows debug com URL de produção; contagens verificadas para cobertura parcial, total e sem ativos.
- Checkpoint Git: `0d2ea0e` — `feat(beef): show animals missing recent weights`.
- Componentes concluídos: calculador de cobertura, rótulos e alertas do painel de Corte; a data da última pesagem válida permanece independente da janela de cobertura.
- Validações concluídas: 13 testes de Corte/painel, análise estática sem problemas e build Windows debug com URL de produção. A pesagem no 90º dia conta, a de 91 dias não; a virada do mês não zera a cobertura.
- Checkpoint Git: `f1f6c7c` — `fix(beef): use rolling 90-day weighing coverage`.
- Componentes concluídos: calculador de cobertura de pesagens de animais ativos, análise e painel técnico de Corte; série histórica geral preservada.
- Validações concluídas: 11 testes de Corte/painel passaram; `flutter analyze` dos seis arquivos envolvidos sem problemas; builds Windows debug e release com URL de produção aprovados. O release atualizado foi reaberto em 23/09 (PID 4252, janela responsiva). Casos de animal vendido mais recente, duplicidade, datas futuras, peso inválido e ausência de rebanho cobertos.
- Checkpoint Git: `2c61932` — `fix(beef): scope latest weighing coverage to active animals`.
- Componentes verificados neste pacote: `scripts/build_atlas_windows_production.ps1`, build Windows release com `ATLAS_ENV=production` e `ATLAS_API_BASE_URL=https://atlas-api-29y2.onrender.com/api/v1`, e janela `projeto_atlas` de produção.
- Validações concluídas neste pacote: endpoint `/api/v1/health/ready` retornou HTTP 200; `flutter build windows --release` concluiu; processo release PID 3380 aberto e responsivo. A execução debug anterior usava `127.0.0.1:8000` por não receber `dart-define`, o que explica a falha de conexão mostrada pelo usuário.
- Validação restante de acesso: testar o desbloqueio com o PIN cadastrado quando o dispositivo estiver sem internet; a autenticação online e a criação do PIN já foram confirmadas pelo usuário.
- Contexto da validação anterior: o APK Android atual foi gerado e os testes do cálculo passaram. A compilação Windows estava lenta, mas concluiu após a geração do snapshot Dart; não havia falha do MSBuild.
- Componentes implementados: GMD calculado com primeira e última pesagem válida de cada animal ativo nos últimos 12 meses; painel informa quantos animais têm pares válidos e sinaliza amostra pequena; parser rejeita datas impossíveis.
- Validações concluídas: testes de pareamento, exclusão de dados inválidos, contrato do painel e APK Android debug aprovado (SHA-256 `01E0CA243AA48DE987C7486B9894A99AF31956B653439B8D19AD72D8A7C93226`).
- Checkpoint Git publicado: `d24dc6f` — `fix(beef): calculate gain from paired animal weights`.
- Validação restante: conferir no painel de Corte, com sessão da fazenda, os números e alertas apresentados para pesagens reais.
- Próximo marco: validar o desbloqueio offline pelo usuário e conferir a evolução mensal, GMD e cobertura com dados reais; compilar um release de avaliação após o próximo conjunto de mudanças.

## Próximo pacote planejado

Conferir a evolução mensal, o GMD e a cobertura de pesagens no painel de Corte com sessão da fazenda. Validar uma abertura offline com o PIN cadastrado. Após novo conjunto de alterações, gerar um release Windows para avaliação; o OCR local depende de teste com nota real no aparelho.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
