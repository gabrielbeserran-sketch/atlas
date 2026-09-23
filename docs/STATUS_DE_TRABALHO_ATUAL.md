# Status de trabalho atual — Atlas

Atualizado em 23/09/2026.

## Estado

- Situação: diagnóstico pontual da disponibilidade da API concluído; release Windows agrupado permanece aberto e responsivo (PID 20340).
- Etapa atual: conferir Corte com dados reais e testar entrada offline com o PIN cadastrado; continuar observando a primeira conexão após períodos de inatividade.
- Progresso: 100% do diagnóstico pontual; release agrupado 100%; acesso local-primeiro 98% até teste de PIN sem internet.
- Componentes previstos: concluídos — URL configurada do backend, sondagens HTTP/DNS/TLS e registro no cronograma; sem alterações de credenciais nem do aplicativo.
- Validações concluídas: uma chamada anterior a `/health/ready` expirou em 70 segundos; em seguida, duas chamadas limitadas a 25 segundos retornaram HTTP 200 em 0,63 s e 0,97 s. `/health/live` retornou 200 em 0,78 s; referência HTTPS externa retornou 204 em 0,67 s. DNS e TLS responderam em frações de segundo nas sondagens bem-sucedidas. Isto demonstra intermitência, não falha contínua; não há prova suficiente da causa exata.
- Checkpoint Git do diagnóstico: tag `atlas-api-disponibilidade-20260923` publicada com a documentação; não houve mudança funcional.
- Próximo marco: coletar horário e duração de uma nova lentidão se ocorrer; o login local-primeiro e o PIN devem permanecer disponíveis sem aguardar a API.
- Componentes concluídos neste pacote: release Windows de produção reúne peso médio do rebanho ativo com cobertura, denominador explícito da área total e relação de animais com pesagem pendente. Aplicativo aberto para avaliação; APK não alterado.
- Próximo marco: obter feedback da janela aberta, testar o PIN sem internet e investigar a disponibilidade remota separadamente caso continue lenta.
- Componentes concluídos neste pacote: cartão “Animais para pesar” com lista navegável de animais ativos sem pesagem válida nos últimos 90 dias; cada item apresenta brinco/nome, lote e data da última pesagem válida ou ausência dela. A lista é carregada sob demanda visual em diálogo rolável e usa a mesma base da contagem do painel.
- Validações concluídas neste pacote: 26 testes de Corte/painel, análise estática sem problemas e build Windows debug com URL HTTPS de produção em 23/09. Banco local do usuário preservado; APK não alterado.
- Checkpoint Git publicado do pacote: `35a75b7` — `feat(beef): list animals overdue for weighing`.
- Próximo marco: conferir a lista com dados reais no próximo release Windows agrupado e testar desbloqueio offline com o PIN cadastrado.
- Componentes concluídos neste pacote: rótulos de animais/ha e kg/ha explicitam que o denominador é a área total cadastrada; cartão mostra essa área e informa que não representa lotação do pasto. Quando ela falta, ambos os índices ficam indisponíveis e surge orientação para completar o cadastro. Valores longos do cartão agora quebram linha no Windows e em telas estreitas.
- Validações concluídas neste pacote: 23 testes de Corte/painel, análise estática sem problemas e build Windows debug com URL HTTPS de produção em 23/09. Banco local do usuário preservado.
- Checkpoint Git publicado do pacote: `c2acc9d` — `fix(beef): clarify total-area density indicators`.
- Componentes concluídos neste pacote: peso médio calculado somente com animais ativos de peso válido; base X/Y visível; peso vivo/ha indisponível quando faltar peso de algum ativo; área não finita rejeitada também no cálculo de Leite. A tela informa o dado que falta sem exibir zero enganoso.
- Validações concluídas neste pacote: 22 testes de Corte/painel, análise estática sem problemas e build Windows debug com URL HTTPS de produção em 23/09. Banco local do usuário preservado.
- Checkpoint Git publicado do pacote: `e605f33` — `fix(beef): validate active herd weight coverage`.
- Componentes concluídos: build Windows release com URL HTTPS de produção, executável atualizado e janela do Atlas.
- Validações concluídas: `scripts/build_atlas_windows_production.ps1` aprovado em 23/09; processo release PID 6704 aberto e responsivo. Banco local do usuário preservado.
- Checkpoint Git do código incluído: `a2d1f5b` (idade na venda), `c400d57` (evolução mensal) e os pacotes de cobertura `f1f6c7c`/`0d2ea0e`.
- Componentes concluídos: indicador de idade média aproximada na venda, tamanho da amostra e alerta de nascimento inválido/ausente.
- Validações concluídas: 18 testes de Corte/painel, análise estática sem problemas e build Windows debug com URL de produção; casos de nascimento válido, data impossível, venda anterior ao nascimento e janela anual cobertos.
- Checkpoint Git: `a2d1f5b` — `feat(beef): report verified age at sale`.
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
- Próximo marco: validar desbloqueio offline pelo usuário e conferir os indicadores de Corte com dados reais na janela aberta; após feedback, definir a próxima lacuna operacional.

## Próximo pacote planejado

Conferir, em Produção de corte, a evolução mensal, a idade na venda, o GMD e a cobertura de pesagens com dados reais. Validar uma abertura offline com o PIN cadastrado. O OCR local depende de teste com nota real no aparelho.

## Como acompanhar

Em cada pacote, este arquivo será atualizado com:

1. porcentagem real da etapa atual;
2. arquivos e componentes em alteração;
3. validações já executadas e pendentes;
4. checkpoint Git publicado;
5. próximo marco objetivo.

Uma etapa só é marcada como concluída depois de análise/teste aplicável, checkpoint Git e publicação. Mudanças visuais também exigem build Windows confirmado.
