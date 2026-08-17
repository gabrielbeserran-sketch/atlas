# Atlas V1 — Passos 11 a 20

## 11. Dashboards reais
Todos os dashboards da V1 devem usar dados persistidos ou declarar claramente ausência de dados.
O script `scripts/v1/11_audit_dashboards.ps1` gera candidatos a mocks/hardcodes para revisão.
Não é seguro substituir automaticamente todo literal por chamada remota: alguns textos são rótulos legítimos.

## 12. IA consolidada
A V1 mantém IA como apoio à decisão. Recomendações devem trazer confiança/evidência quando disponíveis.
Ações críticas continuam supervisionadas. O inventário é gerado por `12_audit_ai_v1.ps1`.

## 13. Tratamento global de erros
`main.dart` agora registra erros Flutter e de plataforma em `AtlasErrorReporter` e usa um `ErrorWidget`
controlado para evitar tela vermelha/branca em produção.

## 14. Loading, vazio e retry
Foram adicionados widgets centrais:
- `AtlasLoadingState`
- `AtlasEmptyState`
- `AtlasErrorState`

Eles são o padrão obrigatório para novas correções de telas V1.

## 15. Padronização visual
A V1 preserva `AppTheme.lightTheme` como fonte única de tema e os estados acima como componentes padrão.
A responsividade Android dos passos 1–10 foi mantida.

## 16. Testes automatizados
Execute `scripts/v1/16_quality_gate.ps1`.

## 17. Android ponta a ponta
O teste físico continua obrigatório. Use `scripts/v1/17_android_e2e.ps1`.
Aprovação depende do checklist em `release/checklists/ANDROID_E2E_CHECKLIST.md`.

## 18. Produção
A build release não deve usar HTTP, senha padrão, segredo de desenvolvimento ou banco local de testes.
`AndroidManifest.xml` agora é seguro por padrão; apenas a variante debug permite cleartext local.

## 19. APK/AAB
Use `scripts/v1/19_build_android_release.ps1 -ApiBaseUrl https://...`.
A publicação exige chave de assinatura de release própria.

## 20. Play Store
O pacote inclui checklist de publicação e rascunhos jurídicos. Política de privacidade e termos precisam
de revisão jurídica antes de serem apresentados como documentos finais.

## Status honesto
Os passos 11–16 e a preparação técnica de 18–20 estão implementados nesta entrega.
Os passos 17, 19 e 20 possuem ações que só podem ser concluídas no aparelho/computador do usuário
e na Google Play Console. O projeto contém os scripts e critérios para executá-las sem criar novos módulos.
