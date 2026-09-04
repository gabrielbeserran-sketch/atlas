# Gate de reconciliação Atlas — 2026-09-04

## Decisão de fontes

| Papel | Caminho | Estado comprovado |
| --- | --- | --- |
| Candidata à baseline oficial | `C:\Projetos\Projetos Atlas` | `master` em `bf870f2a55728cc807ea8a3c98e6d5d7ca3122c3` (11A), versão `1.0.0+6`, com avanços posteriores ainda não versionados. |
| Checkpoint de recuperação | `C:\Projetos\Atlas_Recovery_10D` | `5b51a97f2e74358a66cfdab1690b9654d86aa5a6`, 2026-08-31, fase 6.5.2 de iconografia. Não é diretório de desenvolvimento ativo. |
| Ponte estável anterior | `C:\Projetos\ATLAS_BASE_ESTAVEL_20260815` | `fd9c00a9ca56f84c0ae14589a272cb28188c4602`, versão `1.0.0+2`. Contém a recuperação estática da APK, mas não deve receber novos recursos. |

`Projetos Atlas` só passará a ser a baseline oficial após os gates abaixo e um commit auditável. Até lá, nenhuma das três cópias pode ser removida ou sobrescrita.

## Evidências apuradas

- A candidata possui 37 mudanças versionadas e 603 itens não versionados.
- Somente 10 dos itens não versionados são fonte, configuração ou testes. Os outros 593 são principalmente payloads ZIP, manifestos, scripts de aplicação/rollback e arquivos de evidência. Eles não são fonte de verdade e não podem ser executados durante a consolidação.
- Os módulos vistos na APK Android `1.0.0+6` existem na candidata: Dr. Beserra, Centro de Campo, Manejo, Operações de Campo e Centro de Inteligência.
- O menu atual está organizado por capacidades operacionais: Dashboard, Fazendas, Rebanho, Realizar manejo, Sanidade, Reprodução, Nutrição, Financeiro, Estoque, Agenda, Dr. Beserra, Offline, Campo, Inteligência, Relatórios e Consultoria.
- A auditoria 6.5.2 registrada no Recovery define: Animais usa ícone semântico de brinco (`sell_outlined`), nunca pata de pet; Rebanho usa o Nelore vetorial canônico; os consumidores devem compartilhar essa iconografia.

## Gate anti-tela-branca

Validações executadas na candidata em 2026-09-04:

- [x] `flutter analyze` sem diagnósticos.
- [x] `git diff --check` sem erros de whitespace.
- [x] `flutter test test/core/bootstrap --reporter compact`: 9 testes passaram.
- [x] `flutter test`: 276 testes visíveis passaram, zero falhas.
- [x] `flutter build windows` com os `dart-define` oficiais: Release gerado em `build/windows/x64/runner/Release/projeto_atlas.exe`.
- [x] SHA-256 do Release Windows: `5F53433228F5538A11CF11FA6FACDBE518C73173B40D1037FFA9B28CB861D059` (92.672 bytes, 2026-09-04 06:45:10).
- [x] Bootstrap mostra um primeiro frame antes de inicializar a camada operacional.
- [x] Runner Windows anexa a view, aguarda `SetNextFrameCallback`, então mostra a janela e solicita redraw.
- [x] Sessão tem timeout de 30 segundos e telas explícitas de falha/retentativa; não há caminho intencional para tela em branco.

Os quatro testes inicialmente vermelhos continham expectativas obsoletas de implementações 11C.3.6 anteriores. Foram atualizados para verificar a baseline 11C.3.8 efetivamente presente: primeiro frame, handshake Windows, timeout e recuperação visível. Nenhum arquivo de produção foi alterado por esse ajuste.

A regressão completa revelou e corrigiu dois defeitos reais antes da promoção:

- `AtlasApp` mantinha um temporizador do primeiro frame após o descarte do widget. O temporizador agora é guardado e cancelado em `dispose`.
- O login desktop combinava rolagem vertical com `Row`/`Spacer` que exigiam altura finita. A tela agora usa alinhamento e espaçamento explícitos, eliminando `BoxConstraints` infinitas e o risco de RenderBox sem layout.

O checkpoint de fonte anterior à validação é `f3db6d97b6dc7d87c247dae47694a79253455378`, na branch `codex/reconciliation-prebaseline-20260904`, etiquetado como `atlas-preconsolidacao-20260904`. A validação atual será registrada em commit separado para que ambas as etapas possam ser recuperadas.

## Escopo a promover, em commits separados

1. **Bootstrap e segurança de inicialização:** `lib/main.dart`, `lib/app.dart`, sessão, runner Windows e respectivos testes.
2. **Navegação e design system:** shell, rotas, tema, branding, ícone Nelore/brinco e telas que o consomem.
3. **Módulos funcionais já presentes:** Campo, Manejo, Dr. Beserra, Fazendas, Rebanho, Dashboard, autenticação e Inteligência.
4. **Contratos e persistência:** `pubspec`, dependências, backend/migrations somente após checagem de origem e sem promover `atlas_test.db` como dado de produção.
5. **Evidência fora da baseline:** ZIPs, scripts históricos, manifestos de entrega e backups permanecem arquivados, fora do commit de produto.

## Gate de navegação

`test/core/navigation/atlas_home_shell_route_contract_test.dart` protege o menu operacional atual. Ele verifica que os itens com builder de reserva são resolvidos no shell para Manejo, Agenda, Dr. Beserra, Campo, Relatórios, Consultoria e Inteligência. Para módulos dependentes de fazenda, a ausência de contexto leva à tela de seleção de fazenda, nunca a uma área em branco.

## Próximos gates obrigatórios

- [ ] Rodar a suíte Flutter completa com resultado registrado e classificar cada falha real.
- [ ] Auditar imports, rotas e permissões de todos os itens de menu; cada rota deve ter tela, estado vazio/erro e autorização.
- [ ] Rodar build Windows da candidata com os `dart-define` oficiais e fazer uma abertura controlada.
- [ ] Executar regressão Android sem alterar a APK homologada; registrar hashes de APK/AAB.
- [ ] Configurar keystore de release Android: o `build.gradle.kts` ainda aponta a configuração `release` para a assinatura debug. Isso bloqueia publicação, embora não bloqueie o checkpoint de fonte/Windows.
- [ ] Revisar migrations e endpoints de Campo/Manejo/Dr. Beserra antes de declarar operações remotas prontas.
- [ ] Fazer snapshot imutável e criar commits lógicos, tag de baseline e manifesto mestre.
- [ ] Só então retirar resíduos regeneráveis. Backup, payloads e evidências só poderão ser movidos após hash e inventário.

## Proibição operacional até a consolidação

- Não executar scripts `APLICAR_*`, `PROMOVER_*`, `ROLLBACK_*`, `LIMPAR_*` ou payloads ZIP históricos.
- Não rodar `git reset`, `git clean`, cópia em massa ou exclusão entre as três árvores.
- Não iniciar a fase funcional 6.5.3 enquanto a baseline acima não estiver commitada, etiquetada e homologada.
