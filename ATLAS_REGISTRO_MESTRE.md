# PROJETO ATLAS — REGISTRO MESTRE

> **ARQUIVO CANÔNICO DE ORGANIZAÇÃO DO PROJETO**
>
> A partir da adoção deste arquivo, **toda modificação futura de arquitetura, funcionalidade, correção, sprint, ciclo,
> configuração, decisão de produto, validação, teste ou procedimento de publicação deve ser registrada aqui**.
> Não devem ser criados novos arquivos soltos do tipo `LEIA_ME_*`, `CICLO_*_IMPLEMENTADO`, `CORRECAO_*`,
> `VALIDACAO_*` ou equivalentes para registrar evolução. Se um documento técnico específico for indispensável,
> ele deve ser referenciado neste Registro Mestre na mesma entrega.

**Versão do registro:** 1.0 — consolidado em 2026-08-07
**Base analisada:** Projeto Atlas V1 — passos 1 a 20
**Telas inventariadas:** 248
**Módulos Flutter (`lib/features`):** 163
**Arquivos históricos de orientação consolidados neste registro:** 170

---

## 1. Regra obrigatória de organização daqui para frente

1. Este arquivo é a **fonte única de verdade sobre o histórico de evolução do Atlas**.
2. Cada alteração futura deve acrescentar uma entrada em **Registro de alterações futuras**, no final deste arquivo.
3. A entrada deve informar: data, objetivo, arquivos alterados, funções afetadas, backend/endpoints envolvidos, testes executados, resultado, pendências e instruções de rollback.
4. Não registrar uma função como concluída apenas porque existe uma tela ou código. Para `CONCLUÍDO`, exigir evidência de persistência, integração, tratamento de erro e teste.
5. Funcionalidades demonstrativas devem ser marcadas como `DEMO` e não podem ser apresentadas como produção.
6. Funções pós-V1 podem permanecer no código, mas devem ser ocultadas do usuário final se não estiverem homologadas.
7. Os arquivos históricos individuais consolidados no Apêndice podem ser movidos para uma pasta de arquivo morto depois de este Registro Mestre ser colocado na raiz do projeto.
8. **Nome recomendado e permanente na raiz:** `ATLAS_REGISTRO_MESTRE.md`.

---

## 2. Estado consolidado dos passos 1 a 20

### Passos 1 a 10 — consolidação da V1

- **Passo 1 — Responsividade Android**: `IMPLEMENTADO_NESTE_PACOTE`. farm_detail_screen.dart: FarmDashboardHeader responsivo paddock_list_screen.dart: PaddockCard responsivo atlas_livestock_module_screen.dart: padding móvel
- **Passo 2 — Contexto da fazenda**: `IMPLEMENTADO_NESTE_PACOTE`. FarmListScreen seleciona a fazenda da sessão antes de abrir detalhes AtlasSessionController persiste activeFarm
- **Passo 3 — Auditoria das 248 telas**: `IMPLEMENTADO_NESTE_PACOTE`. ATLAS_V1_AUDITORIA_248_TELAS.csv classificação V1/Admin/Avançado/Revisar
- **Passo 4 — Seis módulos operacionais centrais**: `CONSOLIDADO_SEM_RECRIAR`. Rebanho usa HerdOverviewScreen Sanidade/Reprodução/Nutrição/Financeiro/Estoque usam AtlasLivestockModuleScreen oficial
- **Passo 5 — Fazendas e manejo**: `CONSOLIDADO_COM_PENDENCIA_DE_BACKEND_PARA_PIQUETES`. Fazendas usam FarmStorageService com API como autoridade quando autenticado Piquetes ainda persistem localmente
- **Passo 6 — Persistência real**: `PARCIAL_E_EXPLICITA`. Fazendas CRUD remoto + cache local Módulos centrais consultam backend Piquetes e partes legadas ainda usam SharedPreferences
- **Passo 7 — Eliminar dados demonstrativos**: `IMPLEMENTADO_NO_FLUXO_CRITICO`. Removida criação automática de Piquete 01/Piquete 02/42 animais
- **Passo 8 — Autenticação real**: `ENDURECIDA`. Restauração de sessão existente logout limpa activeFarm falha de restore limpa sessão/contexto
- **Passo 9 — Permissões e multiempresa**: `ENDURECIDA`. default-deny para sessão não-admin sem permissões fazenda só pode ser selecionada se autorizada
- **Passo 10 — Offline e sincronização**: `ENDURECIDA`. sync exige companyId, tenantId e deviceId fila/push/pull/conflitos existentes preservados

### Passos 11 a 20 — fechamento técnico da V1

- **Passo 11 — Dashboards reais**: `implemented_with_audit`.
- **Passo 12 — IA consolidada**: `implemented_with_inventory`.
- **Passo 13 — Tratamento global de erros**: `implemented`.
- **Passo 14 — Loading/vazio/retry**: `implemented_standard`.
- **Passo 15 — Padronização visual**: `implemented_standard`.
- **Passo 16 — Testes automatizados**: `gate_created_requires_local_run`.
- **Passo 17 — Android E2E**: `requires_physical_device_validation`.
- **Passo 18 — Produção**: `technical_preparation_implemented`.
- **Passo 19 — APK/AAB release**: `script_ready_requires_release_signing_and_https`.
- **Passo 20 — Play Store**: `external_action_checklist_ready`.

### Leitura correta do status

- Os passos 1–15 representam consolidação técnica já incorporada ao código, mas continuam sujeitos à validação no ambiente real.
- O passo 16 possui gate criado, porém deve ser executado sempre que houver alteração.
- O passo 17 depende obrigatoriamente do aparelho físico.
- Os passos 19 e 20 dependem de chave de assinatura, HTTPS, Play Console e decisões externas.

---

## 3. Análise das funções que ainda não estão concluídas

Os itens abaixo são **lacunas confirmadas ou fortemente evidenciadas na base atual**. Eles têm prioridade sobre criação de novos recursos.

| Função/área | Prioridade | Motivo da pendência |
|---|---|---|
| Piquetes — persistência remota | **CRÍTICO V1** | PaddockStorageService usa SharedPreferences e não foi localizada rota oficial de piquetes no backend. Cadastro/edição no aparelho não é multi-dispositivo nem autoridade de produção. |
| Nutrição — CRUD completo | **ALTO** | O backend possui POST/GET de ingredientes, planos e consumo, mas o storage/tela legada de planos ainda usa persistência local e a central integrada é principalmente leitura. |
| Financeiro — CRUD remoto unificado | **ALTO** | O backend possui lançamentos, liquidação, resumo e fluxo de caixa. O módulo legado de edição usa SharedPreferences e a central integrada atual é principalmente leitura. |
| Estoque — CRUD e movimentações remotas unificadas | **ALTO** | O backend possui cadastro de produto, movimentações e alertas. O storage legado ainda é local e a central integrada atual é principalmente leitura. |
| Fotos de animais | **ALTO** | AnimalPhotoStorageService armazena metadados localmente; falta upload e persistência remota/objeto. |
| Documentos de animais | **ALTO** | AnimalDocumentStorageService armazena localmente; falta upload e persistência remota. |
| Agenda da fazenda | **MÉDIO** | FarmAgendaStorageService ainda usa SharedPreferences; precisa sincronização/autoridade remota para uso em mais de um aparelho. |
| Autoridade única de dados legados | **ALTO** | Há serviços enterprise remotos e storages locais paralelos para animais, pesos, movimentações e outros módulos. É necessário retirar o caminho legado ou transformá-lo explicitamente em cache/offline. |
| Central dos cinco módulos pecuários | **ALTO** | AtlasLivestockModuleScreen consulta dados oficiais, porém é predominantemente leitura. Nem todas as operações POST/PATCH disponíveis no backend estão expostas nessa central. |
| Offline de campo | **ALTO** | Existem operações demo no repositório e o checklist E2E ainda não foi aprovado no aparelho. Falta comprovar fila, reconexão, idempotência e resolução de conflito com dados reais. |
| Digital Twin | **PÓS-V1** | A tela possui modo/propriedade demonstrativa. Não está pronta para ser tratada como produto operacional. |
| Consultoria — Hub | **MÉDIO/PÓS-V1** | Há Cliente Demonstração no repositório. O fluxo precisa trabalhar apenas com clientes e dados reais. |
| Consultoria — Workflow | **MÉDIO/PÓS-V1** | Há caso demonstrativo. Persistência e execução real do caso precisam de validação. |
| Hub de integrações | **MÉDIO/PÓS-V1** | Há conexão meteorológica demonstrativa. Cada integração externa precisa credenciais, homologação, retry e monitoramento reais. |
| Relatórios | **MÉDIO** | Há dados demonstrativos em repositório de reporting; é necessário validar que relatórios da V1 saem exclusivamente de dados persistidos. |
| Analytics — testes | **MÉDIO** | Existe teste placeholder de analytics; a cobertura ainda não comprova comportamento real. |
| Telas duplicadas | **ALTO** | Há duplicidades nominais de Copilot, Enterprise Operations, Executive Intelligence, Intelligence e Predictive AI. Uma única implementação canônica deve permanecer navegável. |
| 78 telas classificadas como REVISAR | **ALTO ORGANIZACIONAL** | Precisam decisão explícita: manter, fundir, ocultar da V1 ou remover. |
| 71 telas avançadas/pós-V1 | **NÃO BLOQUEIA V1** | Não precisam ser finalizadas para lançar a V1, mas não devem aparecer como recursos prontos se ainda não forem homologadas. |
| Migrações Alembic | **CRÍTICO PRODUÇÃO** | Foi observado `alembic upgrade head` falhando porque `users.email_verified` já existe. O backend inicia, mas o histórico de migração precisa ser reconciliado antes de produção. |
| Teste Android E2E completo | **CRÍTICO RELEASE** | O checklist físico ainda contém itens não validados: persistência de cadastro/edição, offline, todos os módulos, ausência de overflow e restauração de contexto. |
| APK/AAB release | **CRÍTICO RELEASE** | A build de produção exige URL HTTPS e `android/key.properties` com chave de assinatura release. O script existe, mas a execução final ainda depende do ambiente do usuário. |
| Play Store e jurídico | **CRÍTICO PUBLICAÇÃO** | Política de privacidade pública, termos revisados, Data Safety, classificação indicativa, screenshots, testes interno/fechado e aprovação humana ainda são ações externas. |
| Homologação/produção do backend | **CRÍTICO PRODUÇÃO** | Ainda é necessário validar HTTPS, backup/restore, rollback, monitoramento, logs, alertas e configuração de segredos no ambiente final. |

### 3.1 O que está suficientemente consolidado para continuar validando

- **Login/sessão:** autenticação e restauração existem; o contexto da fazenda foi endurecido.
- **Fazendas:** há integração remota com cache local.
- **Rebanho principal:** lotes e animais usam serviços enterprise remotos com criação, edição e exclusão.
- **Reprodução individual:** eventos possuem POST/GET remoto com fallback local.
- **Sanidade individual:** eventos possuem POST/GET remoto com fallback local.
- **Pesagens e movimentações:** existem serviços enterprise remotos, embora ainda coexistam storages legados.
- **Central offline:** estrutura de fila, pull/push e conflitos existe; falta aprovação E2E com dados reais.
- **Segurança/permissões:** contexto de empresa/tenant/fazenda e default-deny foram reforçados.

### 3.2 O que não deve bloquear a V1 se estiver oculto

- Digital Twin demonstrativo.
- Parte das IAs avançadas e suítes enterprise classificadas como pós-V1.
- Recursos de escala, ecossistema, comercial enterprise e laboratórios de decisão que não façam parte do fluxo produtor V1.

---

## 4. Duplicidades que precisam ser consolidadas

- **atlascopilot**
  - `features/atlas_copilot/presentation/screens/atlas_copilot_screen.dart`
  - `features/copilot/presentation/screens/atlas_copilot_screen.dart`
- **atlasenterpriseoperations**
  - `features/atlas_enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart`
  - `features/enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart`
- **atlasexecutiveintelligence**
  - `features/atlas_executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart`
  - `core/operational_intelligence/action_plan/atlas_executive_intelligence_screen.dart`
  - `features/executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart`
- **atlasintelligence**
  - `features/atlas_intelligence/presentation/screens/atlas_intelligence_screen.dart`
  - `features/dashboard/presentation/screens/atlas_intelligence_screen.dart`
- **atlaspredictiveai**
  - `features/atlas_predictive_ai_suite/presentation/screens/atlas_predictive_ai_screen.dart`
  - `features/predictive_ai/presentation/screens/atlas_predictive_ai_screen.dart`

---

## 5. Matriz de todos os módulos Flutter

> Esta matriz é uma análise estática. `IMPLEMENTADO_VALIDAR` significa que há integração aparente no código, mas a função só deve ser considerada concluída após teste funcional. `PERSISTÊNCIA_LOCAL_REVISAR` não significa automaticamente erro: alguns storages podem ser cache legítimo, mas precisam ser classificados explicitamente.

| Módulo | Telas | API | Mutação remota detectada | Storage local | Demo/mock | Testes | Classificação | Status atual | Observação |
|---|---:|:---:|:---:|:---:|:---:|---:|---|---|---|
| `action_plan` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `analytics` | 1 | Sim | Sim | Não | Não | 36 | AVANCADO_POS_V1 | **TESTE_INCOMPLETO** | Existe teste placeholder de analytics; cobertura funcional real precisa ser implementada. |
| `animal` | 3 | Sim | Sim | Sim | Não | 1 | V1_ESSENCIAL | **IMPLEMENTADO_PRINCIPAL_COM_LEGADO** | O fluxo principal de Rebanho usa AnimalEnterpriseService remoto; ainda existe AnimalStorageService local legado que deve ser aposentado/migrado. |
| `animal_document` | 2 | Não | Não | Sim | Não | 0 | REVISAR | **PARCIAL_V1** | Documentos do animal são persistidos localmente em SharedPreferences; falta upload/persistência remota. |
| `animal_enterprise_suite` | 0 | Não | Não | Não | Não | 0 | - | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `animal_event` | 2 | Sim | Não | Sim | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `animal_executive_panel` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `animal_genealogy` | 1 | Sim | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `animal_health` | 3 | Sim | Sim | Sim | Não | 0 | V1_ESSENCIAL | **IMPLEMENTADO_HÍBRIDO_VALIDAR** | Eventos sanitários usam API com fallback/cache local; protocolos e fluxos avançados ainda exigem validação E2E. |
| `animal_health_enterprise` | 1 | Não | Não | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `animal_intelligence_360` | 1 | Não | Não | Sim | Não | 0 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `animal_movement` | 2 | Sim | Sim | Sim | Não | 0 | REVISAR | **IMPLEMENTADO_HÍBRIDO_VALIDAR** | Há serviço enterprise remoto e storage legado local; consolidar uma única autoridade de dados. |
| `animal_nutrition_enterprise` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `animal_operations_center` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `animal_photo` | 2 | Não | Não | Sim | Não | 0 | REVISAR | **PARCIAL_V1** | Fotos do animal são persistidas localmente em SharedPreferences; falta upload/persistência remota de arquivos. |
| `animal_reproduction` | 3 | Sim | Sim | Sim | Não | 0 | V1_ESSENCIAL | **IMPLEMENTADO_HÍBRIDO_VALIDAR** | Eventos reprodutivos usam API com fallback/cache local; protocolos avançados ainda exigem validação E2E. |
| `animal_reproduction_enterprise` | 1 | Não | Não | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `animal_weight` | 2 | Sim | Sim | Sim | Não | 0 | REVISAR | **IMPLEMENTADO_HÍBRIDO_VALIDAR** | Há serviço enterprise remoto e storage legado local; consolidar uma única autoridade de dados. |
| `animal_weight_intelligence` | 1 | Não | Não | Não | Não | 0 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `animal_zootechnical` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `atlas_advanced` | 1 | Sim | Sim | Não | Não | 1 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `atlas_advanced_ai` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_ai` | 2 | Não | Não | Sim | Não | 2 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_ai_2` | 2 | Sim | Sim | Não | Não | 1 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `atlas_ai_enterprise` | 1 | Sim | Sim | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `atlas_auth_sync_enterprise` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_automation_operations` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_autonomous_enterprise` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_backend_foundation` | 1 | Não | Não | Sim | Não | 1 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_bi` | 5 | Não | Não | Não | Não | 0 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `atlas_bi_analytics` | 1 | Não | Não | Não | Não | 0 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `atlas_business` | 1 | Sim | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `atlas_climate_enterprise` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_cloud_security_enterprise` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_commercial_enterprise` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_commercial_operations` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_copilot` | 1 | Não | Não | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `atlas_enterprise_50` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_enterprise_operations` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `atlas_environmental_ai` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_executive_intelligence` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `atlas_executive_platform` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_finance_enterprise` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_financial_integrations` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_geospatial_platform` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_global_platform` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_governance_operations` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_governance_people_enterprise` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_intelligence` | 1 | Não | Não | Não | Não | 2 | AVANCADO_POS_V1 | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `atlas_intelligence_center` | 1 | Sim | Sim | Não | Não | 1 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `atlas_intelligence_reports_experience` | 1 | Não | Não | Sim | Não | 0 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_iot_platform` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_land_intelligence` | 1 | Não | Não | Sim | Não | 0 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_livestock_integration` | 1 | Não | Não | Sim | Não | 1 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_official_integrations` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_operations_enterprise` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_os` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `atlas_platform_resilience` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_precision_livestock` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_predictive_ai_suite` | 1 | Não | Não | Sim | Não | 0 | AVANCADO_POS_V1 | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `atlas_quality_release` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_reproductive_ai` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_reproductive_premium` | 1 | Não | Não | Sim | Não | 1 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_rural_business` | 1 | Não | Não | Sim | Não | 1 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_saas_platform` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_scale` | 1 | Não | Não | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `atlas_sprints_11_15` | 1 | Sim | Sim | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `atlas_sprints_16_20` | 1 | Sim | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `atlas_sprints_21_25` | 1 | Sim | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `atlas_supply_chain` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_supply_logistics_enterprise` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_sustainability_ecosystem` | 1 | Não | Não | Sim | Não | 0 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_sustainability_enterprise` | 1 | Não | Não | Sim | Não | 1 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `atlas_veterinary_ai` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `authentication` | 5 | Sim | Não | Não | Não | 0 | V1_ESSENCIAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `automation_strategy` | 1 | Sim | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `autonomous_consultant` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `benefits_realization` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `command_center` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `commercial_platform` | 1 | Sim | Não | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `commercial_readiness` | 1 | Não | Não | Não | Sim | 1 | ADMIN_OU_OPERACIONAL | **PÓS_V1_CHECKLIST** | É um checklist/roteiro de prontidão comercial, com item de demonstração; não é função operacional central do produtor. |
| `consultancy_hub` | 0 | Não | Não | Sim | Sim | 0 | - | **DEMO_PARCIAL** | Repositório contém Cliente Demonstração; precisa ser ligado a dados reais. |
| `consultancy_workflow` | 1 | Não | Não | Sim | Sim | 0 | REVISAR | **DEMO_PARCIAL** | Repositório contém caso demonstrativo; precisa persistência/fluxo real validado. |
| `continuous_improvement` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `copilot` | 5 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `dashboard` | 6 | Não | Não | Não | Não | 0 | V1_ESSENCIAL | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `data_governance` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `data_intelligence` | 1 | Sim | Sim | Não | Não | 1 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `decision_engine` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `decision_engine_v2` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `decision_intelligence_lab` | 1 | Não | Não | Não | Não | 0 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `decision_tracking` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `diagnostics` | 2 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `digital_twin` | 1 | Não | Não | Sim | Sim | 0 | AVANCADO_POS_V1 | **DEMO_PÓS_V1** | Tela possui propriedade/modo demonstrativo; não deve ser tratada como função pronta de produção. |
| `enterprise_operations` | 1 | Não | Não | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `enterprise_platform` | 5 | Sim | Sim | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `executive_ai_advisor` | 1 | Não | Não | Não | Não | 0 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `executive_alerts` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `executive_brain` | 3 | Não | Não | Sim | Não | 0 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `executive_core` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `executive_goals` | 2 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `executive_intelligence` | 1 | Não | Não | Não | Não | 1 | AVANCADO_POS_V1 | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `executive_kpis` | 2 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `farm` | 4 | Sim | Sim | Sim | Não | 1 | V1_ESSENCIAL | **IMPLEMENTADO_HÍBRIDO_VALIDAR** | Fazendas usam API como autoridade quando autenticado com cache local; ainda requer validação E2E completa. |
| `farm_agenda` | 2 | Não | Não | Sim | Não | 0 | REVISAR | **PARCIAL_V1** | Agenda usa armazenamento local e precisa de autoridade remota/offline oficial para uso multi-dispositivo. |
| `farm_audit` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `farm_finance` | 3 | Sim | Não | Sim | Não | 0 | V1_ESSENCIAL | **PARCIAL_V1** | CRUD legado usa SharedPreferences. O backend possui endpoints financeiros; a central integrada atual é predominantemente consulta/indicadores. |
| `farm_inventory` | 3 | Sim | Não | Sim | Não | 0 | V1_ESSENCIAL | **PARCIAL_V1** | CRUD legado usa SharedPreferences. O backend possui endpoints de estoque; a central integrada atual é predominantemente consulta/indicadores. |
| `farm_operations` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `field_operations` | 1 | Não | Não | Não | Não | 1 | V1_ESSENCIAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `flutter_quality` | 1 | Não | Não | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `governance_resilience` | 1 | Sim | Não | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `herd` | 3 | Sim | Sim | Sim | Não | 1 | V1_ESSENCIAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `indicators` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `integration_ecosystem` | 1 | Sim | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `integration_hub` | 1 | Não | Não | Sim | Sim | 0 | REVISAR | **DEMO_PARCIAL** | Possui conexão meteorológica demonstrativa; integrações reais ainda precisam de homologação. |
| `investment_capital_allocation` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `iot_enterprise` | 1 | Sim | Sim | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `knowledge_learning` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `livestock_integration` | 0 | Sim | Sim | Não | Não | 1 | - | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `livestock_operations` | 1 | Sim | Não | Não | Não | 1 | V1_ESSENCIAL | **PARCIAL_V1** | A central integrada de Reprodução/Sanidade/Nutrição/Estoque/Financeiro é majoritariamente leitura. Há endpoints de mutação no backend que não estão todos ligados a esta interface. |
| `mission_control` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `ml_platform` | 1 | Sim | Não | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `nutrition` | 1 | Sim | Não | Sim | Não | 0 | V1_ESSENCIAL | **PARCIAL_V1** | Plano nutricional legado usa SharedPreferences. O backend possui endpoints de nutrição, mas o CRUD legado ainda não está totalmente ligado à API. |
| `observability` | 0 | Não | Não | Sim | Não | 0 | - | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `offline_field` | 1 | Não | Não | Sim | Sim | 0 | V1_ESSENCIAL | **DEMO_PARCIAL** | O repositório contém operações demo; remover dados demonstrativos e validar o fluxo offline real ponta a ponta. |
| `operational_readiness` | 1 | Não | Não | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `operations` | 0 | Sim | Sim | Não | Não | 1 | - | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `optimization_engine` | 2 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `paddock` | 2 | Não | Não | Sim | Não | 0 | V1_ESSENCIAL | **INCOMPLETO_CRÍTICO** | CRUD existe no Flutter, mas a persistência é somente local em SharedPreferences e não foi localizada rota oficial de piquetes no backend. |
| `performance_center` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `performance_intelligence` | 1 | Não | Não | Sim | Não | 0 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `pilot_program` | 1 | Não | Não | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `platform_hubs` | 0 | Sim | Sim | Não | Não | 1 | - | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `platform_v1` | 1 | Sim | Sim | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `portfolio_management` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `precision_hub` | 1 | Não | Não | Não | Não | 0 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `predictive` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `predictive_ai` | 1 | Não | Não | Sim | Não | 1 | AVANCADO_POS_V1 | **REVISAR_DUPLICIDADE** | Há tela nominalmente duplicada em outro módulo; consolidar antes da V1 final. |
| `predictive_analytics` | 1 | Não | Não | Não | Não | 0 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `publication_center` | 1 | Não | Não | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `quality_center` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `realtime` | 1 | Sim | Sim | Não | Não | 1 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `recommendation_intelligence` | 1 | Não | Não | Não | Não | 0 | AVANCADO_POS_V1 | **PÓS_V1_NÃO_BLOQUEIA** | Classificado como avançado/pós-V1; não bloqueia a primeira versão operacional. |
| `release_engineering` | 1 | Sim | Não | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `release_management` | 1 | Não | Não | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `reporting` | 0 | Não | Não | Sim | Sim | 0 | - | **DEMO_PARCIAL** | Repositório contém produtor demonstrativo; geração real de relatórios precisa ser validada. |
| `reports` | 2 | Não | Não | Sim | Não | 1 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `saas_admin` | 1 | Não | Não | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **DOMÍNIO_LOCAL_OU_AUXILIAR** | Código existente sem evidência suficiente de API; revisar somente se fizer parte da V1. |
| `scenario_simulator` | 2 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `security_center` | 1 | Sim | Sim | Não | Não | 1 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `security_privacy_continuity` | 1 | Sim | Não | Não | Não | 0 | ADMIN_OU_OPERACIONAL | **IMPLEMENTADO_VALIDAR** | Integração remota detectada; falta teste funcional/E2E antes de declarar concluído. |
| `strategic_alignment` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `strategic_capacity` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `strategic_execution_engine` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `strategic_scenario_planning` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `strategy_center` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `strategy_execution` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `sync_platform` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `technical_dashboard` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |
| `unified_workflow` | 1 | Não | Não | Sim | Não | 0 | REVISAR | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `value_governance` | 1 | Não | Não | Sim | Não | 0 | ADMIN_OU_OPERACIONAL | **PERSISTÊNCIA_LOCAL_REVISAR** | Persistência local detectada sem cliente/API neste módulo. Confirmar se é cache legítimo ou autoridade indevida. |
| `workflow_engine` | 1 | Não | Não | Não | Não | 0 | REVISAR | **REVISAR** | Classificado para revisão antes de manter, fundir ou ocultar. |

---

## 6. Bloqueadores objetivos para declarar “Atlas V1 100% pronto”

- [ ] `flutter analyze` sem issues após a versão final.
- [ ] `flutter test` integral aprovado sem testes placeholder relevantes.
- [ ] Gate do backend aprovado.
- [ ] Histórico Alembic reconciliado; `upgrade head` deve concluir em banco limpo e em banco existente.
- [ ] Piquetes persistidos por backend/API ou repository offline oficial.
- [ ] Nutrição, Financeiro e Estoque com CRUD real integrado ao backend no fluxo V1.
- [ ] Fotos/documentos com upload e persistência remota, ou explicitamente removidos da V1.
- [ ] Nenhuma tela essencial V1 dependendo de dado demonstrativo.
- [ ] Checklist Android E2E 100% marcado em aparelho físico.
- [ ] Teste sem internet + reconexão + não duplicação aprovado.
- [ ] APK/AAB assinado com chave release.
- [ ] Backend de produção em HTTPS.
- [ ] Backup e restauração testados.
- [ ] Monitoramento/logs/alertas de produção ativos.
- [ ] Política de privacidade publicada e termos revisados.
- [ ] Play Console: Data Safety, screenshots, classificação indicativa e testes exigidos concluídos.

---

## 7. Registro de alterações futuras — MODELO OBRIGATÓRIO

Copiar o bloco abaixo para cada nova entrega:

```markdown
### AAAA-MM-DD — <nome curto da alteração>
- **Objetivo:**
- **Funções afetadas:**
- **Arquivos alterados:**
- **Backend/endpoints:**
- **Migrações:**
- **Persistência/offline:**
- **Permissões/segurança:**
- **Testes executados:**
- **Resultado:**
- **Pendências restantes:**
- **Rollback:**
- **Status final:** CONCLUÍDO / PARCIAL / BLOQUEADO / PÓS-V1
```

---

## 8. Índice dos documentos históricos consolidados

1. `ATLAS_ANDROID_1_IMPLEMENTADO.txt`
2. `ATLAS_ANDROID_1_MANIFEST.json`
3. `ATLAS_ANDROID_1_PASSOS_11_A_20.txt`
4. `ATLAS_PUBSPEC_DEPENDENCIES_SPRINTS_51_60.txt`
5. `ATLAS_V1_READINESS_PASSOS_11_A_20.json`
6. `ATLAS_V1_READINESS_PASSOS_1_A_10.json`
7. `backend/CHECKPOINT_ESTAVEL_OPENAPI.txt`
8. `backend/CONSOLIDACAO_FASES_1_A_5.md`
9. `backend/CONSOLIDACAO_MODELS_CONFIRMADA.txt`
10. `backend/CONSOLIDACAO_MODELS_SCHEMAS_CONFIRMADA.txt`
11. `backend/CORRECAO_CHECK_OPENAPI_CONFIRMADA.txt`
12. `backend/CORRECAO_TESTES_LEGADOS_CONFIRMADA.txt`
13. `backend/CORRECAO_WORKFLOW_DUPLICADO_CONFIRMADA.txt`
14. `backend/docs/ai/SPRINTS_61_A_70.md`
15. `backend/docs/ARCHITECTURE.md`
16. `backend/docs/archive/delivery_history/ai_SPRINTS_61_A_70.md`
17. `backend/docs/archive/delivery_history/data_platform_SPRINTS_101_A_110.md`
18. `backend/docs/archive/delivery_history/enterprise_SPRINTS_81_A_90.md`
19. `backend/docs/archive/delivery_history/LEIA_ME_BACKEND_COMPLETO_SPRINTS_26_A_30.md`
20. `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_101_A_110.md`
21. `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_111_A_120.md`
22. `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_121_A_130.md`
23. `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_31_A_40.md`
24. `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_41_A_50.md`
25. `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_81_A_90.md`
26. `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_91_A_100.md`
27. `backend/docs/archive/delivery_history/offline_SPRINTS_51_A_60.md`
28. `backend/docs/archive/delivery_history/operational_SPRINTS_41_A_50.md`
29. `backend/docs/archive/delivery_history/precision_SPRINTS_71_A_80.md`
30. `backend/docs/archive/delivery_history/quality_SPRINTS_31_A_40.md`
31. `backend/docs/archive/delivery_history/release_SPRINTS_121_A_130.md`
32. `backend/docs/archive/delivery_history/saas_SPRINTS_91_A_100.md`
33. `backend/docs/archive/delivery_history/security_SPRINTS_111_A_120.md`
34. `backend/docs/BACKEND_AUDIT.json`
35. `backend/docs/data_platform/SPRINTS_101_A_110.md`
36. `backend/docs/enterprise/SPRINTS_81_A_90.md`
37. `backend/docs/FASE_41_PACOTES_301_A_310.md`
38. `backend/docs/FASE_42_PACOTES_311_A_320.md`
39. `backend/docs/FASE_42_STATUS.json`
40. `backend/docs/FASE_43_PACOTES_321_A_330.md`
41. `backend/docs/FASE_43_STATUS.json`
42. `backend/docs/offline/SPRINTS_51_A_60.md`
43. `backend/docs/operational/SPRINTS_41_A_50.md`
44. `backend/docs/PACOTE_301_AUDITORIA_BACKEND.md`
45. `backend/docs/PACOTE_302_ARQUITETURA_SERVIDOR.md`
46. `backend/docs/PACOTE_309_DOCUMENTACAO_API.md`
47. `backend/docs/PACOTE_311_CADASTRO_REAL.md`
48. `backend/docs/PACOTE_312_HASH_SENHAS.md`
49. `backend/docs/PACOTE_313_CONFIRMACAO_EMAIL.md`
50. `backend/docs/PACOTE_314_LOGIN_REAL.md`
51. `backend/docs/PACOTE_315_SESSOES.md`
52. `backend/docs/PACOTE_316_RECUPERACAO_SENHA.md`
53. `backend/docs/PACOTE_317_MFA.md`
54. `backend/docs/PACOTE_318_RBAC.md`
55. `backend/docs/PACOTE_319_PROTECAO_ROTAS.md`
56. `backend/docs/PACOTE_320_AUDITORIA_SEGURANCA.md`
57. `backend/docs/precision/SPRINTS_71_A_80.md`
58. `backend/docs/quality/API_CONVENTIONS.md`
59. `backend/docs/quality/FLUTTER_QUALITY_GUIDE.md`
60. `backend/docs/quality/SPRINTS_31_A_40.md`
61. `backend/docs/release/SPRINTS_121_A_130.md`
62. `backend/docs/saas/SPRINTS_91_A_100.md`
63. `backend/docs/security/SPRINTS_111_A_120.md`
64. `backend/docs/TEST_RESULT_PHASE_41.json`
65. `backend/docs/TEST_RESULT_PHASE_42.json`
66. `backend/docs/TEST_RESULT_PHASE_43.json`
67. `backend/LEIA_ME_BACKEND_COMPLETO_SPRINTS_26_A_30.md`
68. `backend/LEIA_ME_CORRECAO_204.md`
69. `backend/LEIA_ME_CORRECAO_CONTEXT_BUILDER.md`
70. `backend/LEIA_ME_CORRECAO_DEPENDENCIES.md`
71. `backend/LEIA_ME_CORRECAO_MODELOS_PECUARIOS.md`
72. `backend/LEIA_ME_CORRECAO_TABELAS_DUPLICADAS.md`
73. `backend/LEIA_ME_INSTALACAO_CORRIGIDA.txt`
74. `backend/LEIA_ME_SPRINTS_101_A_110.md`
75. `backend/LEIA_ME_SPRINTS_111_A_120.md`
76. `backend/LEIA_ME_SPRINTS_121_A_130.md`
77. `backend/LEIA_ME_SPRINTS_31_A_40.md`
78. `backend/LEIA_ME_SPRINTS_41_A_50.md`
79. `backend/LEIA_ME_SPRINTS_81_A_90.md`
80. `backend/LEIA_ME_SPRINTS_91_A_100.md`
81. `CHECKLIST_FINAL_PROJETO_ATLAS.md`
82. `CICLO_1_IMPLEMENTADO.txt`
83. `CICLO_2_IMPLEMENTADO.txt`
84. `CICLO_3_IMPLEMENTADO.txt`
85. `CICLO_4_IMPLEMENTADO.txt`
86. `CICLOS_10_A_12_IMPLEMENTADOS.txt`
87. `CICLOS_13_A_15_IMPLEMENTADOS.txt`
88. `CICLOS_16_A_18_IMPLEMENTADOS.txt`
89. `CICLOS_19_E_20_IMPLEMENTADOS.txt`
90. `CICLOS_5_E_6_IMPLEMENTADOS.txt`
91. `CICLOS_7_A_9_IMPLEMENTADOS.txt`
92. `CORRECAO_19_CURLY_BRACES_CONFIRMADA.txt`
93. `CORRECAO_ADB_AUTOMATICO_CONFIRMADA.txt`
94. `CORRECAO_FINAL_ENUM_44_45_46_LEIA_ME.txt`
95. `CORRECAO_NAVEGACAO_DUAS_LINHAS_LEIA_ME.txt`
96. `CORRECAO_NAVEGACAO_MODULOS_LEIA_ME.txt`
97. `docs/android/ATLAS_ANDROID_1_PASSOS_11_A_20.md`
98. `docs/android/ATLAS_ANDROID_1_PRIMEIRO_DISPOSITIVO.md`
99. `docs/atlas_automation_operations/PACOTES_59_60_61_62_ARQUITETURA.md`
100. `docs/atlas_autonomous_enterprise/PACOTES_99_100_ARQUITETURA.md`
101. `docs/atlas_commercial_operations/PACOTES_75_76_77_78_ARQUITETURA.md`
102. `docs/atlas_connected_offline/CORRECAO_BACKUPS_FASE_44.md`
103. `docs/atlas_enterprise_operations/PACOTES_79_80_81_82_83_ARQUITETURA.md`
104. `docs/atlas_environmental_ai/PACOTES_56_57_58_ARQUITETURA.md`
105. `docs/atlas_executive_intelligence/PACOTES_89_90_91_92_93_ARQUITETURA.md`
106. `docs/atlas_financial_integrations/PACOTES_67_68_69_70_ARQUITETURA.md`
107. `docs/atlas_governance_operations/PACOTES_84_85_86_87_88_ARQUITETURA.md`
108. `docs/atlas_official_integrations/PACOTES_63_64_65_66_ARQUITETURA.md`
109. `docs/atlas_platform_resilience/PACOTES_94_95_96_97_98_ARQUITETURA.md`
110. `docs/atlas_predictive_ai_suite/PACOTES_53_54_55_ARQUITETURA.md`
111. `docs/atlas_rural_business/PACOTES_71_72_73_74_ARQUITETURA.md`
112. `docs/commercial/IMPORTACAO_DADOS.md`
113. `docs/commercial/ONBOARDING_CLIENTE.md`
114. `docs/commercial/ROTEIRO_DEMONSTRACAO.md`
115. `docs/integration/CICLO_10_DADOS_ANALYTICS.md`
116. `docs/integration/CICLO_11_SEGURANCA_CONFORMIDADE.md`
117. `docs/integration/CICLO_12_QUALIDADE_FLUTTER.md`
118. `docs/integration/CICLO_13_QUALIDADE_BACKEND.md`
119. `docs/integration/CICLO_14_DESEMPENHO_OBSERVABILIDADE.md`
120. `docs/integration/CICLO_15_INFRAESTRUTURA.md`
121. `docs/integration/CICLO_1_MATRIZ_TELAS_ENDPOINTS.md`
122. `docs/integration/CICLO_2_REBANHO_INTEGRADO.md`
123. `docs/integration/CICLO_3_MODULOS_ZOOTECNICOS.md`
124. `docs/integration/CICLO_4_OFFLINE_SINCRONIZACAO.md`
125. `docs/integration/CICLO_5_OPERACAO_DE_CAMPO.md`
126. `docs/integration/CICLO_6_INTELIGENCIA_ATLAS.md`
127. `docs/integration/CICLOS_7_A_9_PLATAFORMAS.md`
128. `docs/pilot/PILOT_RUNBOOK.md`
129. `docs/pilot/PILOT_SCORECARD.md`
130. `docs/publication/ANDROID_RELEASE.md`
131. `docs/publication/IOS_RELEASE.md`
132. `docs/publication/PRIVACIDADE_TERMOS_SUPORTE.md`
133. `docs/publication/WEB_RELEASE.md`
134. `docs/release/RELEASE_RUNBOOK.md`
135. `docs/release/ROLLBACK_RUNBOOK.md`
136. `docs/strategy/ARCHITECTURE_MODULAR_TARGET.md`
137. `docs/strategy/ATLAS_3_ROADMAP_5_ANOS.md`
138. `docs/strategy/MULTITENANT_SCALE_PLAN.md`
139. `docs/v1/ATLAS_V1_PASSOS_11_A_20.md`
140. `LEIA_ME_APLICACAO.txt`
141. `LEIA_ME_ATLAS_ANDROID_1.md`
142. `LEIA_ME_ATLAS_V1_PASSOS_1_A_10.md`
143. `LEIA_ME_BLOCOS_1_A_5.md`
144. `LEIA_ME_BLOCOS_6_A_10.md`
145. `LEIA_ME_CICLO_1_SPRINTS_131_A_135.md`
146. `LEIA_ME_CICLO_2_SPRINTS_136_A_140.md`
147. `LEIA_ME_CICLO_3_SPRINTS_141_A_145.md`
148. `LEIA_ME_CICLO_4_SPRINTS_146_A_150.md`
149. `LEIA_ME_CICLOS_10_A_12.md`
150. `LEIA_ME_CICLOS_13_A_15.md`
151. `LEIA_ME_CICLOS_16_A_18.md`
152. `LEIA_ME_CICLOS_19_E_20.md`
153. `LEIA_ME_CICLOS_5_E_6.md`
154. `LEIA_ME_CICLOS_7_A_9.md`
155. `LEIA_ME_CORRECAO_19_AVISOS_CURLY_BRACES.md`
156. `LEIA_ME_CORRECAO_7_AVISOS.md`
157. `LEIA_ME_CORRECAO_DASHBOARD.txt`
158. `LEIA_ME_FASE_1.txt`
159. `LEIA_ME_FASES_2_E_3.txt`
160. `LEIA_ME_FASES_4_E_5.md`
161. `LEIA_ME_SPRINTS_11_A_15.md`
162. `LEIA_ME_SPRINTS_16_A_20.md`
163. `LEIA_ME_SPRINTS_21_A_25.md`
164. `LEIA_ME_SPRINTS_51_A_60.md`
165. `LEIA_ME_SPRINTS_61_A_70.md`
166. `LEIA_ME_SPRINTS_71_A_80.md`
167. `PACOTES_26_A_30_MANIFESTO.json`
168. `pilot/CHECKLIST_ATLAS_1_0.md`
169. `PUBSPEC_DEPENDENCIES_CORRIGIDAS_SPRINTS_61_70.txt`
170. `VALIDACAO_24D_CORRECAO.txt`

---

## 9. APÊNDICE — conteúdo consolidado dos arquivos históricos

> Os conteúdos abaixo são preservados para consulta histórica. Eles não substituem o status atual das seções 2–6 deste Registro Mestre quando houver divergência.

### 9.1 — `ATLAS_ANDROID_1_IMPLEMENTADO.txt`

```text
ATLAS ANDROID 1.0 — PRIMEIRO DISPOSITIVO REAL

- URL de API configurável por --dart-define
- prioridade da URL de build sobre preferências antigas
- INTERNET habilitada no Android release
- rede local HTTP habilitada para o primeiro teste privado
- applicationId definido como br.com.projetoatlas.app
- scripts de validação, execução, build, instalação e aceite
- teste de normalização do endpoint Android
- versão 1.0.0+2

A aprovação final exige execução no celular real.
```

### 9.2 — `ATLAS_ANDROID_1_MANIFEST.json`

```text
{
  "milestone": "Atlas Android 1.0 - Primeiro Dispositivo Real",
  "version": "1.0.0+2",
  "application_id": "br.com.projetoatlas.app",
  "steps": 20,
  "apk_expected_path": "dist/android/atlas-android-1.0.0-release.apk",
  "production_ready": false,
  "requires_real_device_acceptance": true
}
```

### 9.3 — `ATLAS_ANDROID_1_PASSOS_11_A_20.txt`

```text
Atlas Android 1.0: scripts dos passos 11 a 20 consolidados, com ADB reverse para primeiro teste USB e build LAN para APK independente do cabo.
```

### 9.4 — `ATLAS_PUBSPEC_DEPENDENCIES_SPRINTS_51_60.txt`

```text
Adicione ao pubspec.yaml, mantendo as demais dependências existentes:

dependencies:
  path: ^1.9.1
  path_provider: ^2.1.5
  sqflite_common: ^2.5.6
  sqflite_common_ffi: ^2.3.6
  uuid: ^4.5.1
  flutter_secure_storage: ^9.2.4
  connectivity_plus: ^6.1.4
```

### 9.5 — `ATLAS_V1_READINESS_PASSOS_11_A_20.json`

```text
{
  "release": "Atlas V1",
  "steps": {
    "11": {
      "name": "Dashboards reais",
      "status": "implemented_with_audit"
    },
    "12": {
      "name": "IA consolidada",
      "status": "implemented_with_inventory"
    },
    "13": {
      "name": "Tratamento global de erros",
      "status": "implemented"
    },
    "14": {
      "name": "Loading/vazio/retry",
      "status": "implemented_standard"
    },
    "15": {
      "name": "Padronização visual",
      "status": "implemented_standard"
    },
    "16": {
      "name": "Testes automatizados",
      "status": "gate_created_requires_local_run"
    },
    "17": {
      "name": "Android E2E",
      "status": "requires_physical_device_validation"
    },
    "18": {
      "name": "Produção",
      "status": "technical_preparation_implemented"
    },
    "19": {
      "name": "APK/AAB release",
      "status": "script_ready_requires_release_signing_and_https"
    },
    "20": {
      "name": "Play Store",
      "status": "external_action_checklist_ready"
    }
  }
}
```

### 9.6 — `ATLAS_V1_READINESS_PASSOS_1_A_10.json`

```text
{
  "versao": "Atlas V1 - Consolidação passos 1 a 10",
  "telas_encontradas": 248,
  "classificacao": {
    "ADMIN_OU_OPERACIONAL": 59,
    "AVANCADO_POS_V1": 71,
    "REVISAR": 78,
    "V1_ESSENCIAL": 40
  },
  "duplicidades_nominais": {
    "atlascopilot": [
      "features/atlas_copilot/presentation/screens/atlas_copilot_screen.dart",
      "features/copilot/presentation/screens/atlas_copilot_screen.dart"
    ],
    "atlasenterpriseoperations": [
      "features/atlas_enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart",
      "features/enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart"
    ],
    "atlasexecutiveintelligence": [
      "features/atlas_executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart",
      "core/operational_intelligence/action_plan/atlas_executive_intelligence_screen.dart",
      "features/executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart"
    ],
    "atlasintelligence": [
      "features/atlas_intelligence/presentation/screens/atlas_intelligence_screen.dart",
      "features/dashboard/presentation/screens/atlas_intelligence_screen.dart"
    ],
    "atlaspredictiveai": [
      "features/atlas_predictive_ai_suite/presentation/screens/atlas_predictive_ai_screen.dart",
      "features/predictive_ai/presentation/screens/atlas_predictive_ai_screen.dart"
    ]
  },
  "passos": {
    "1": {
      "nome": "Responsividade Android",
      "status": "IMPLEMENTADO_NESTE_PACOTE",
      "evidencias": [
        "farm_detail_screen.dart: FarmDashboardHeader responsivo",
        "paddock_list_screen.dart: PaddockCard responsivo",
        "atlas_livestock_module_screen.dart: padding móvel"
      ]
    },
    "2": {
      "nome": "Contexto da fazenda",
      "status": "IMPLEMENTADO_NESTE_PACOTE",
      "evidencias": [
        "FarmListScreen seleciona a fazenda da sessão antes de abrir detalhes",
        "AtlasSessionController persiste activeFarm"
      ]
    },
    "3": {
      "nome": "Auditoria das 248 telas",
      "status": "IMPLEMENTADO_NESTE_PACOTE",
      "evidencias": [
        "ATLAS_V1_AUDITORIA_248_TELAS.csv",
        "classificação V1/Admin/Avançado/Revisar"
      ]
    },
    "4": {
      "nome": "Seis módulos operacionais centrais",
      "status": "CONSOLIDADO_SEM_RECRIAR",
      "evidencias": [
        "Rebanho usa HerdOverviewScreen",
        "Sanidade/Reprodução/Nutrição/Financeiro/Estoque usam AtlasLivestockModuleScreen oficial"
      ]
    },
    "5": {
      "nome": "Fazendas e manejo",
      "status": "CONSOLIDADO_COM_PENDENCIA_DE_BACKEND_PARA_PIQUETES",
      "evidencias": [
        "Fazendas usam FarmStorageService com API como autoridade quando autenticado",
        "Piquetes ainda persistem localmente"
      ]
    },
    "6": {
      "nome": "Persistência real",
      "status": "PARCIAL_E_EXPLICITA",
      "evidencias": [
        "Fazendas CRUD remoto + cache local",
        "Módulos centrais consultam backend",
        "Piquetes e partes legadas ainda usam SharedPreferences"
      ]
    },
    "7": {
      "nome": "Eliminar dados demonstrativos",
      "status": "IMPLEMENTADO_NO_FLUXO_CRITICO",
      "evidencias": [
        "Removida criação automática de Piquete 01/Piquete 02/42 animais"
      ]
    },
    "8": {
      "nome": "Autenticação real",
      "status": "ENDURECIDA",
      "evidencias": [
        "Restauração de sessão existente",
        "logout limpa activeFarm",
        "falha de restore limpa sessão/contexto"
      ]
    },
    "9": {
      "nome": "Permissões e multiempresa",
      "status": "ENDURECIDA",
      "evidencias": [
        "default-deny para sessão não-admin sem permissões",
        "fazenda só pode ser selecionada se autorizada"
      ]
    },
    "10": {
      "nome": "Offline e sincronização",
      "status": "ENDURECIDA",
      "evidencias": [
        "sync exige companyId, tenantId e deviceId",
        "fila/push/pull/conflitos existentes preservados"
      ]
    }
  },
  "pendencias_criticas_restantes": [
    "Criar contrato/endpoints oficiais de Piquetes no backend antes de considerar esse módulo persistido em produção.",
    "Migrar telas legadas que ainda usam SharedPreferences como autoridade para API/offline repository.",
    "Executar flutter analyze e flutter test no ambiente do usuário após substituição.",
    "Revalidar visualmente todas as telas V1_ESSENCIAL no Moto G75 5G."
  ]
}
```

### 9.7 — `backend/CHECKPOINT_ESTAVEL_OPENAPI.txt`

```text
CHECKPOINT ESTÁVEL — OPENAPI E ROTAS

- Rotas sanitárias duplicadas removidas de app/routers/livestock.py.
- create_health_protocol declarado uma única vez.
- list_health_protocols declarado uma única vez.
- apply_health_protocol declarado uma única vez.
- Verificador estático de rotas duplicadas adicionado.
- Gate de qualidade atualizado para executar a verificação de rotas.
- Warning de datetime.utcnow emitido por python-jose filtrado na suíte de testes.
- Warnings do OpenAPI causados pelo Atlas não devem permanecer.
```

### 9.8 — `backend/CONSOLIDACAO_FASES_1_A_5.md`

```text
# Consolidação Atlas — Fases 1 a 5

## Fase 1 — Imports
Testes com imports de routers removidos foram retirados da suíte ativa. O `main.py` permanece como fonte oficial dos routers.

## Fase 2 — Legado
Testes por sprint, fase e bloco foram movidos para `test_backups/legacy_sprint_phase_contracts`. Nenhum arquivo foi descartado.

## Fase 3 — Testes oficiais
A suíte ativa foi renomeada por domínio: autenticação, rebanho, IA, plataforma de dados, operações empresariais, SaaS, segurança, precisão e release.

## Fase 4 — Nomenclatura
Nomes de sprint foram removidos da suíte ativa e da documentação operacional. Migrations históricas não foram renomeadas.

## Fase 5 — Arquitetura definitiva
Foram formalizados os pacotes `core`, `models`, `repositories`, `services`, `routers`, `schemas` e `workers`, com verificador automático.
```

### 9.9 — `backend/CONSOLIDACAO_MODELS_CONFIRMADA.txt`

```text
ATLAS - CONSOLIDACAO DO PACOTE app.models

- app/models.py foi movido para app/models/legacy.py.
- app/models/__init__.py reexporta os modelos oficiais.
- O contrato `from app.models import Company, User, ...` foi preservado.
- 108 classes/funcoes de dominio foram identificadas.
- Todos os imports estaticos de app.models foram validados.
```

### 9.10 — `backend/CONSOLIDACAO_MODELS_SCHEMAS_CONFIRMADA.txt`

```text
ATLAS - CONSOLIDACAO MODELS E SCHEMAS

Fonte única de modelos: app/models/legacy.py, exportada por app/models/__init__.py
Fonte única de schemas: app/schemas/legacy.py, exportada por app/schemas/__init__.py
Os arquivos conflitantes app/models.py e app/schemas.py não fazem parte deste pacote.
```

### 9.11 — `backend/CORRECAO_CHECK_OPENAPI_CONFIRMADA.txt`

```text
ATLAS - CORREÇÃO DO CHECK OPENAPI

Alterações aplicadas:
1. check_openapi.py agora adiciona automaticamente a raiz do backend ao sys.path.
2. O script funciona por caminho direto:
   python scripts/quality/check_openapi.py
3. O script também funciona como módulo:
   python -m scripts.quality.check_openapi
4. Foram adicionados scripts/__init__.py e scripts/quality/__init__.py.
5. A validação continua falhando quando encontra operationId duplicado.
```

### 9.12 — `backend/CORRECAO_TESTES_LEGADOS_CONFIRMADA.txt`

```text
ATLAS - CORRECAO DOS TESTES LEGADOS

A pasta backend/tests desta entrega nao contem arquivos nomeados por sprint, fase ou bloco.
Os 34 contratos historicos estao arquivados em:
  backend/test_backups/legacy_sprint_phase_contracts/

Validacoes:
  python scripts/quality/archive_legacy_tests.py
  python scripts/quality/check_consolidated_architecture.py
  python -m pytest -q
```

### 9.13 — `backend/CORRECAO_WORKFLOW_DUPLICADO_CONFIRMADA.txt`

```text
CORRECAO CONFIRMADA: 2026-08-06

enterprise_operations_models.py:
- WorkflowDefinition -> enterprise_workflow_definitions
- WorkflowInstance -> enterprise_workflow_instances

security_compliance_models.py:
- PrivacyRequest -> compliance_privacy_requests

Este arquivo identifica a entrega correta.
```

### 9.14 — `backend/docs/ai/SPRINTS_61_A_70.md`

```text
# Sprints 61 a 70 — IA operacional e governança

Esta entrega cria contexto canônico versionado e com hash, recomendações auditáveis, agentes por área baseados em evidências oficiais, memória da fazenda, simulador empresarial, automações supervisionadas e catálogo de governança de modelos.

Regras principais:
- nenhuma recomendação é persistida sem evidências, confiança, versão e limitações;
- nenhuma automação crítica é executada sem aprovação;
- modelos só podem ser aprovados quando atendem às métricas mínimas;
- contexto e memória sempre respeitam company_id, tenant_id e farm_id.
```

### 9.15 — `backend/docs/ARCHITECTURE.md`

```text
# Arquitetura definitiva do Atlas

O backend é organizado por responsabilidades estáveis, não por números de sprint.

- `app/core`: configuração, autenticação, autorização, banco, middleware e infraestrutura transversal.
- `app/models`: destino gradual dos modelos separados por domínio.
- `app/repositories`: acesso persistente e consultas reutilizáveis.
- `app/services`: regras de negócio e orquestração.
- `app/routers`: contratos HTTP FastAPI.
- `app/schemas`: contratos de entrada e saída.
- `app/workers`: processamento assíncrono e tarefas agendadas.
- `tests`: testes ativos por domínio.
- `test_backups/legacy_sprint_phase_contracts`: testes históricos, fora da coleta do pytest.

As migrations mantêm seus nomes históricos porque fazem parte da cadeia imutável do banco.
```

### 9.16 — `backend/docs/archive/delivery_history/ai_SPRINTS_61_A_70.md`

```text
# Sprints 61 a 70 — IA operacional e governança

Esta entrega cria contexto canônico versionado e com hash, recomendações auditáveis, agentes por área baseados em evidências oficiais, memória da fazenda, simulador empresarial, automações supervisionadas e catálogo de governança de modelos.

Regras principais:
- nenhuma recomendação é persistida sem evidências, confiança, versão e limitações;
- nenhuma automação crítica é executada sem aprovação;
- modelos só podem ser aprovados quando atendem às métricas mínimas;
- contexto e memória sempre respeitam company_id, tenant_id e farm_id.
```

### 9.17 — `backend/docs/archive/delivery_history/data_platform_SPRINTS_101_A_110.md`

```text
# Sprints 101 a 110 — Plataforma de Dados e Resiliência

- 101: eventos de domínio, outbox, idempotência e dead-letter.
- 102: dimensões e fatos para warehouse incremental.
- 103: catálogo versionado de KPIs e observações com qualidade.
- 104: benchmark anonimizado com amostra mínima e percentis.
- 105: definições configuráveis de relatórios.
- 106: métricas incrementais em tempo real.
- 107: índices e consultas paginadas preparados pela migration.
- 108: cache com isolamento por empresa e expiração.
- 109: fila persistente de jobs, tentativas e backoff.
- 110: limites, idempotência, retentativas e recuperação controlada.

Integrações com Redis, Kafka/RabbitMQ, Celery/RQ e warehouse externo podem ser conectadas posteriormente sem alterar os contratos centrais.
```

### 9.18 — `backend/docs/archive/delivery_history/enterprise_SPRINTS_81_A_90.md`

```text
# Sprints 81 a 90

Implementação dos domínios de consultoria, equipes, ativos, compras, vendas, CRM, ecossistema/suporte, workflows e documentos. Todos os registros respeitam empresa, tenant e fazenda quando aplicável. Integrações externas, assinatura digital e emissão fiscal dependem de provedores homologados.
```

### 9.19 — `backend/docs/archive/delivery_history/LEIA_ME_BACKEND_COMPLETO_SPRINTS_26_A_30.md`

```text
# Projeto Atlas — Backend completo consolidado

Esta entrega contém a pasta `backend` completa, consolidada até os Sprints 26 a 30.

## Arquitetura corrigida
Os arquivos genéricos `sprint_models.py`, `sprints_16_20_models.py` e `sprints_21_25_models.py` foram substituídos por:
- `innovation_models.py`
- `enterprise_product_models.py`
- `operations_intelligence_models.py`
- `enterprise_growth_models.py`

## Sprints 26–30
- Financeiro Enterprise: `/api/v1/finance-enterprise`
- Estoque Enterprise: `/api/v1/inventory-enterprise`
- Ecossistema Atlas: `/api/v1/ecosystem`
- Inteligência Corporativa: `/api/v1/corporate-intelligence`
- Plataforma Global: `/api/v1/global-platform`

## Aplicação
Substitua a pasta `backend` inteira pela pasta desta entrega. Faça backup do banco antes.

'''powershell
cd "C:\caminho\para\Projetos Atlas\backend"
python -m pip install -r requirements.txt
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
'''

A migration nova é `20260806_0028`, dependente de `20260806_0027`.
```

### 9.20 — `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_101_A_110.md`

```text
# Sprints 101 a 110 — Plataforma de Dados e Resiliência

- 101: eventos de domínio, outbox, idempotência e dead-letter.
- 102: dimensões e fatos para warehouse incremental.
- 103: catálogo versionado de KPIs e observações com qualidade.
- 104: benchmark anonimizado com amostra mínima e percentis.
- 105: definições configuráveis de relatórios.
- 106: métricas incrementais em tempo real.
- 107: índices e consultas paginadas preparados pela migration.
- 108: cache com isolamento por empresa e expiração.
- 109: fila persistente de jobs, tentativas e backoff.
- 110: limites, idempotência, retentativas e recuperação controlada.

Integrações com Redis, Kafka/RabbitMQ, Celery/RQ e warehouse externo podem ser conectadas posteriormente sem alterar os contratos centrais.
```

### 9.21 — `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_111_A_120.md`

```text
# Atlas — Sprints 111 a 120

Execute `python -m alembic upgrade head`, `python scripts/security/check_security_compliance.py` e `python -m pytest -q`.
```

### 9.22 — `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_121_A_130.md`

```text
# Sprints 121 a 130 — Release, pilotos e Atlas 3.0

Implementa homologação, pilotos técnico e comercial, perfis Android/iOS, release web, treinamento, documentação, crescimento, revisão de capacidades, roadmap de cinco anos e avaliação de prontidão. Integrações com lojas, hospedagem e analytics externos dependem das credenciais oficiais.
```

### 9.23 — `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_31_A_40.md`

```text
# Aplicação — Sprints 31 a 40

Esta entrega contém a pasta `backend` completa, baseada na versão que já iniciou com sucesso.

## Substituição

1. Pare o Uvicorn.
2. Renomeie a pasta atual para backup.
3. Extraia o ZIP na raiz do Projeto Atlas.
4. Reaproveite a `.venv` anterior ou crie uma nova.

## Execução

'''powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_quality.db"
$env:ATLAS_JWT_SECRET="quality-gate-secret-with-at-least-32-characters"
python scripts/quality/run_quality_gate.py
'''

## Flutter

'''powershell
powershell -ExecutionPolicy Bypass -File backend/scripts/quality/run_flutter_quality.ps1
'''
```

### 9.24 — `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_41_A_50.md`

```text
# Projeto Atlas — Sprints 41 a 50

Entrega completa do backend consolidado, com validação operacional dos módulos oficiais de fazenda, lote, animal, pesagem, movimentação, reprodução, sanidade, nutrição, estoque e financeiro.

## Aplicação

Preserve seu `.env` e sua `.venv`. Substitua a pasta backend pela pasta deste pacote ou copie os arquivos completos mantendo os caminhos.

## Comandos

'''powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_core_validation.db"
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
'''

Abra `/docs` e consulte `GET /api/v1/core-validation/farms/{farm_id}`.

Nenhuma migration nova é necessária: a entrega utiliza apenas tabelas oficiais existentes.
```

### 9.25 — `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_81_A_90.md`

```text
# Atlas — Sprints 81 a 90

Execute `python -m alembic upgrade head`, `python scripts/enterprise/check_enterprise_operations.py`, `python -m pytest -q` e `python -m uvicorn app.main:app --reload`.
```

### 9.26 — `backend/docs/archive/delivery_history/LEIA_ME_SPRINTS_91_A_100.md`

```text
# Atlas — Sprints 91 a 100

1. Preserve `.env` e `.venv`.
2. Execute `python -m alembic upgrade head`.
3. Execute `python scripts/saas/check_saas_growth.py`.
4. Execute `python -m pytest -q`.
5. Inicie com `python -m uvicorn app.main:app --reload`.
```

### 9.27 — `backend/docs/archive/delivery_history/offline_SPRINTS_51_A_60.md`

```text
# Sprints 51 a 60 — Operação offline

Esta entrega estabelece o contrato oficial para banco local, fila de operações, push idempotente, pull incremental, conflitos, dispositivos, diagnósticos e confiabilidade em campo.

## Regras

1. Toda mutação offline recebe `operation_id` e `idempotency_key`.
2. Operações respeitam dependências: fazenda → lote → animal → evento.
3. O pull é paginado por cursor crescente e persiste `next_cursor` localmente.
4. Conflitos nunca são resolvidos silenciosamente.
5. Exclusões são lógicas.
6. Sessões offline respeitam validade e permissões armazenadas.
7. Dados sensíveis devem usar armazenamento seguro do sistema operacional.
8. Diagnósticos não devem transportar senhas, tokens ou dados clínicos completos.
```

### 9.28 — `backend/docs/archive/delivery_history/operational_SPRINTS_41_A_50.md`

```text
# Sprints 41 a 50 — Núcleo pecuário confiável

Esta entrega adiciona um validador somente leitura para os dez domínios operacionais oficiais:

1. fazendas;
2. lotes;
3. animais;
4. pesagens;
5. movimentações;
6. reprodução;
7. sanidade;
8. nutrição;
9. estoque;
10. financeiro.

## Endpoint

`GET /api/v1/core-validation/farms/{farm_id}`

A resposta inclui score por domínio, inconsistências detectadas e score consolidado. O endpoint respeita empresa, tenant, fazendas autorizadas e a permissão `platform.read`.

## Validações principais

- fazenda existente, nome e área válidos;
- lote acima da capacidade ou inativo com animais;
- animais sem brinco, sem lote, sem peso ou com peso negativo;
- peso atual divergente da última pesagem;
- mudança de lote sem destino ou para o mesmo lote;
- evento reprodutivo em animal macho;
- carências sanitárias ativas;
- quantidade ou custo nutricional negativo;
- estoque negativo e produtos abaixo do mínimo;
- lançamento financeiro com valor negativo.

## CLI

'''powershell
python scripts/operational/run_core_validation.py --company-id COMPANY_ID --farm-id FARM_ID --fail-on-issues
'''

## Testes

'''powershell
python -m pytest -q tests/test_core_livestock_validation.py
'''

O validador não altera dados. Ele foi criado para localizar inconsistências antes de operações de piloto, importações, sincronizações ou análises da IA.
```

### 9.29 — `backend/docs/archive/delivery_history/precision_SPRINTS_71_A_80.md`

```text
# Sprints 71 a 80 — Precision Hub

Implementação integrada ao cadastro oficial de animais, aos dispositivos `atlas_iot_devices_v2`, à telemetria oficial, ao Atlas Vision e aos ativos geográficos existentes.

## Capacidades
- adaptadores de fabricantes e rotação externa de segredos;
- RFID único por empresa e associação ao animal oficial;
- balança com validação de estabilidade e faixa plausível;
- GPS e geocercas com alertas;
- THI e alertas ambientais;
- nível/fluxo de água e alertas de cocho/bebedouro;
- pipeline de visão com revisão humana;
- GeoJSON para limites, piquetes, cercas e infraestrutura;
- cenas de sensoriamento remoto com índices e rastreabilidade.

Resultados de modelos externos nunca são inventados. Vision e sensoriamento remoto armazenam contratos, versões, confiança e revisão, enquanto inferência real depende de adaptador homologado.
```

### 9.30 — `backend/docs/archive/delivery_history/quality_SPRINTS_31_A_40.md`

```text
# Sprints 31 a 40 — Consolidação e qualidade

## Entregas implementadas

- verificador do grafo de migrations e head único;
- verificador de arquitetura e imports legados;
- validação do OpenAPI e `operationId` único;
- gate de qualidade centralizado;
- testes de headers, request ID, diagnóstico e OpenAPI;
- endpoint `/api/v1/quality/version`;
- endpoint `/api/v1/quality/diagnostics`;
- endpoint `/api/v1/quality/ready`;
- middleware de observabilidade formatado e métricas de duração;
- middleware de segurança com rate limit configurável e headers seguros;
- configuração de documentação habilitável por ambiente;
- workflow CI para backend e Flutter;
- script PowerShell completo para qualidade Flutter.

## Limite desta entrega

A pasta recebida contém o backend, mas não contém o código Flutter completo. Por isso, os Sprints 35 a 38 foram implementados como gate, convenções e CI executáveis sobre a raiz real do projeto. Correções específicas nas telas devem ser feitas sobre a pasta `lib` atual após a execução de `flutter analyze`.

## Comando único do backend

'''powershell
python scripts/quality/run_quality_gate.py
'''

## Comando único do Flutter

Na raiz do projeto:

'''powershell
powershell -ExecutionPolicy Bypass -File backend/scripts/quality/run_flutter_quality.ps1
'''
```

### 9.31 — `backend/docs/archive/delivery_history/release_SPRINTS_121_A_130.md`

```text
# Sprints 121 a 130 — Release, pilotos e Atlas 3.0

Implementa homologação, pilotos técnico e comercial, perfis Android/iOS, release web, treinamento, documentação, crescimento, revisão de capacidades, roadmap de cinco anos e avaliação de prontidão. Integrações com lojas, hospedagem e analytics externos dependem das credenciais oficiais.
```

### 9.32 — `backend/docs/archive/delivery_history/saas_SPRINTS_91_A_100.md`

```text
# Sprints 91 a 100

Implementa planos/licenças, assinatura, cobrança/faturas, portal do cliente, painel administrativo, feature flags, comunicação, onboarding, importação e exportação.

## Segurança
Credenciais de provedores não são persistidas nestas tabelas. Webhooks e pagamentos reais exigem validação criptográfica e credenciais oficiais.

## Importação
Jobs preservam mapeamento, prévia e relatório de erros. A aplicação efetiva dos dados deve ser transacional e idempotente por domínio.

## Exportação
Jobs aceitam CSV, XLSX, PDF e JSON. O arquivo final deve ser produzido por worker e armazenado em storage autorizado.
```

### 9.33 — `backend/docs/archive/delivery_history/security_SPRINTS_111_A_120.md`

```text
# Sprints 111 a 120

RBAC, segurança de API, auditoria encadeada, LGPD, backups, disponibilidade, internacionalização, regras regionais, certificações e continuidade operacional.
```

### 9.34 — `backend/docs/BACKEND_AUDIT.json`

```text
{
  "backend": "FastAPI + SQLAlchemy",
  "python_files": 25,
  "routers": 10,
  "tests": 7,
  "files": [
    {
      "path": "app/__init__.py",
      "lines": 1,
      "classes": [],
      "functions": [],
      "imports": []
    },
    {
      "path": "app/authz.py",
      "lines": 222,
      "classes": [
        "Principal"
      ],
      "functions": [
        "resolve_permissions",
        "get_principal",
        "require_permission",
        "require_farm_scope",
        "dependency"
      ],
      "imports": [
        "database",
        "dataclasses",
        "fastapi",
        "models",
        "security",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/bootstrap.py",
      "lines": 51,
      "classes": [],
      "functions": [
        "bootstrap"
      ],
      "imports": [
        "config",
        "models",
        "security",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/config.py",
      "lines": 45,
      "classes": [
        "Settings"
      ],
      "functions": [
        "get_settings",
        "cors_origins",
        "backup_dir"
      ],
      "imports": [
        "functools",
        "pathlib",
        "pydantic_settings"
      ]
    },
    {
      "path": "app/database.py",
      "lines": 39,
      "classes": [
        "Base"
      ],
      "functions": [
        "get_db"
      ],
      "imports": [
        "collections",
        "config",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/main.py",
      "lines": 67,
      "classes": [],
      "functions": [
        "lifespan",
        "root"
      ],
      "imports": [
        "bootstrap",
        "config",
        "contextlib",
        "database",
        "fastapi",
        "routers",
        "services"
      ]
    },
    {
      "path": "app/models.py",
      "lines": 204,
      "classes": [
        "Company",
        "User",
        "Membership",
        "Farm",
        "EntityState",
        "SyncChange",
        "ProcessedOperation",
        "AuditLog"
      ],
      "functions": [
        "utcnow",
        "new_id"
      ],
      "imports": [
        "__future__",
        "database",
        "datetime",
        "sqlalchemy",
        "uuid"
      ]
    },
    {
      "path": "app/routers/__init__.py",
      "lines": 1,
      "classes": [],
      "functions": [],
      "imports": []
    },
    {
      "path": "app/routers/animals.py",
      "lines": 711,
      "classes": [],
      "functions": [
        "_farm_for_principal",
        "_animal_for_principal",
        "_response",
        "_record_change",
        "list_animals",
        "_genealogy_node",
        "animal_genealogy",
        "animal_history",
        "animal_timeline",
        "get_animal",
        "create_animal",
        "update_animal",
        "delete_animal",
        "parent_of",
        "descendant_relation",
        "category",
        "title"
      ],
      "imports": [
        "authz",
        "database",
        "fastapi",
        "models",
        "schemas",
        "services",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/audit.py",
      "lines": 46,
      "classes": [],
      "functions": [
        "list_audit"
      ],
      "imports": [
        "authz",
        "database",
        "fastapi",
        "models",
        "schemas",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/auth.py",
      "lines": 160,
      "classes": [],
      "functions": [
        "_token_response",
        "login",
        "me",
        "switch_company"
      ],
      "imports": [
        "authz",
        "database",
        "fastapi",
        "models",
        "schemas",
        "security",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/backups.py",
      "lines": 61,
      "classes": [],
      "functions": [
        "_response",
        "list_backups",
        "run_backup"
      ],
      "imports": [
        "authz",
        "database",
        "datetime",
        "fastapi",
        "schemas",
        "services",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/companies.py",
      "lines": 262,
      "classes": [],
      "functions": [
        "_authorized_membership",
        "_details",
        "list_companies",
        "get_company",
        "create_company",
        "update_company"
      ],
      "imports": [
        "authz",
        "database",
        "fastapi",
        "models",
        "schemas",
        "services",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/farms.py",
      "lines": 185,
      "classes": [],
      "functions": [
        "_farm_for_principal",
        "list_farms",
        "get_farm",
        "create_farm",
        "update_farm",
        "delete_farm"
      ],
      "imports": [
        "authz",
        "database",
        "fastapi",
        "models",
        "schemas",
        "services",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/health.py",
      "lines": 17,
      "classes": [],
      "functions": [
        "health"
      ],
      "imports": [
        "database",
        "fastapi",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/members.py",
      "lines": 393,
      "classes": [],
      "functions": [
        "_validate_role",
        "_validate_overrides",
        "_validate_farms",
        "_member_response",
        "_get_membership",
        "_ensure_admin_remains",
        "permission_catalog",
        "list_members",
        "create_member",
        "update_member",
        "reset_member_password"
      ],
      "imports": [
        "authz",
        "database",
        "fastapi",
        "models",
        "schemas",
        "security",
        "services",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/sync.py",
      "lines": 215,
      "classes": [],
      "functions": [
        "push",
        "pull"
      ],
      "imports": [
        "authz",
        "database",
        "fastapi",
        "models",
        "schemas",
        "services",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/routers/system.py",
      "lines": 13,
      "classes": [],
      "functions": [
        "status",
        "system_metrics"
      ],
      "imports": [
        "authz",
        "database",
        "fastapi",
        "models",
        "services",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/schemas.py",
      "lines": 325,
      "classes": [
        "LoginRequest",
        "CompanySummary",
        "CompanyCreateRequest",
        "CompanyUpdateRequest",
        "CompanyDetailsResponse",
        "TokenResponse",
        "SwitchCompanyRequest",
        "FarmCreateRequest",
        "FarmUpdateRequest",
        "FarmResponse",
        "SyncPushRequest",
        "SyncPushResponse",
        "SyncChangeResponse",
        "AuditResponse",
        "BackupResponse",
        "MemberCreateRequest",
        "MemberUpdateRequest",
        "MemberPasswordResetRequest",
        "MemberResponse",
        "PermissionCatalogResponse",
        "AnimalCreateRequest",
        "AnimalUpdateRequest",
        "AnimalResponse",
        "AnimalHistoryResponse",
        "AnimalTimelineResponse",
        "AnimalGenealogyNodeResponse",
        "AnimalGenealogyResponse"
      ],
      "functions": [],
      "imports": [
        "datetime",
        "pydantic",
        "typing"
      ]
    },
    {
      "path": "app/security.py",
      "lines": 58,
      "classes": [],
      "functions": [
        "hash_password",
        "verify_password",
        "create_access_token",
        "decode_access_token"
      ],
      "imports": [
        "config",
        "datetime",
        "fastapi",
        "jose",
        "passlib"
      ]
    },
    {
      "path": "app/services/__init__.py",
      "lines": 1,
      "classes": [],
      "functions": [],
      "imports": []
    },
    {
      "path": "app/services/audit.py",
      "lines": 39,
      "classes": [],
      "functions": [
        "record_audit"
      ],
      "imports": [
        "authz",
        "models",
        "sqlalchemy"
      ]
    },
    {
      "path": "app/services/backup.py",
      "lines": 97,
      "classes": [
        "BackupService"
      ],
      "functions": [
        "__init__",
        "run",
        "list_backups",
        "cleanup",
        "_sqlite_path",
        "_pg_dump"
      ],
      "imports": [
        "__future__",
        "config",
        "datetime",
        "os",
        "pathlib",
        "shutil",
        "subprocess",
        "urllib"
      ]
    },
    {
      "path": "app/services/observability.py",
      "lines": 19,
      "classes": [
        "RuntimeMetrics"
      ],
      "functions": [
        "observability_middleware",
        "__init__",
        "record",
        "snapshot"
      ],
      "imports": [
        "collections",
        "json",
        "logging",
        "threading",
        "time",
        "uuid"
      ]
    },
    {
      "path": "app/services/security_middleware.py",
      "lines": 18,
      "classes": [
        "Limiter"
      ],
      "functions": [
        "security_middleware",
        "__init__",
        "allow"
      ],
      "imports": [
        "collections",
        "fastapi",
        "threading",
        "time"
      ]
    }
  ],
  "findings": [
    {
      "severity": "high",
      "message": "create_all ainda é usado no startup; migrações Alembic devem ser a fonte de verdade."
    },
    {
      "severity": "high",
      "message": "Existe segredo padrão de desenvolvimento; produção deve rejeitar segredos fracos."
    }
  ]
}
```

### 9.35 — `backend/docs/data_platform/SPRINTS_101_A_110.md`

```text
# Sprints 101 a 110 — Plataforma de Dados e Resiliência

- 101: eventos de domínio, outbox, idempotência e dead-letter.
- 102: dimensões e fatos para warehouse incremental.
- 103: catálogo versionado de KPIs e observações com qualidade.
- 104: benchmark anonimizado com amostra mínima e percentis.
- 105: definições configuráveis de relatórios.
- 106: métricas incrementais em tempo real.
- 107: índices e consultas paginadas preparados pela migration.
- 108: cache com isolamento por empresa e expiração.
- 109: fila persistente de jobs, tentativas e backoff.
- 110: limites, idempotência, retentativas e recuperação controlada.

Integrações com Redis, Kafka/RabbitMQ, Celery/RQ e warehouse externo podem ser conectadas posteriormente sem alterar os contratos centrais.
```

### 9.36 — `backend/docs/enterprise/SPRINTS_81_A_90.md`

```text
# Sprints 81 a 90

Implementação dos domínios de consultoria, equipes, ativos, compras, vendas, CRM, ecossistema/suporte, workflows e documentos. Todos os registros respeitam empresa, tenant e fazenda quando aplicável. Integrações externas, assinatura digital e emissão fiscal dependem de provedores homologados.
```

### 9.37 — `backend/docs/FASE_41_PACOTES_301_A_310.md`

```text
# Fase 41 — Backend Atlas executável

## Entregue
1. auditoria automatizada;
2. estrutura `core`, `db` e `repositories`;
3. validação segura de ambientes;
4. engine PostgreSQL com pool e health check;
5. Alembic e migração inicial;
6. utilitário de escopo multempresa;
7. repositório base e Unit of Work;
8. erros globais e request ID;
9. OpenAPI com Bearer JWT;
10. health, liveness e readiness.

## Comandos
'''powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
alembic upgrade head
pytest -q
uvicorn app.main:app --reload
'''
```

### 9.38 — `backend/docs/FASE_42_PACOTES_311_A_320.md`

```text
# Fase 42 — Autenticação e Usuários Reais

## Pacotes
- 311: Cadastro real de usuário;
- 312: Hash seguro de senhas;
- 313: Confirmação de e-mail;
- 314: Login real;
- 315: Renovação e revogação de sessão;
- 316: Recuperação real de senha;
- 317: Autenticação multifator;
- 318: Papéis e permissões reais;
- 319: Proteção das rotas;
- 320: Auditoria de segurança.

## Implementação
A fase acrescenta contas multempresa, confirmação de e-mail, política de senha,
bloqueio por tentativas, access token, refresh token rotativo, sessões ativas,
recuperação de senha, MFA TOTP, códigos de recuperação e eventos de segurança.

## E-mail
Em desenvolvimento e testes, o backend usa uma caixa de saída em memória.
Em homologação e produção, substitua `InMemoryMailer` por um provedor real.

## Segurança
O campo `secret_encrypted` está preparado para receber segredo protegido.
Antes de produção, conecte um gerenciador de chaves e criptografe o segredo MFA.
```

### 9.39 — `backend/docs/FASE_42_STATUS.json`

```text
{
  "phase": 42,
  "current_package": 320,
  "packages": {
    "311": {
      "name": "Cadastro Real de Usuário",
      "status": "integrado"
    },
    "312": {
      "name": "Hash Seguro de Senhas",
      "status": "integrado"
    },
    "313": {
      "name": "Confirmação de E-mail",
      "status": "integrado"
    },
    "314": {
      "name": "Login Real",
      "status": "integrado"
    },
    "315": {
      "name": "Renovação e Revogação de Sessão",
      "status": "integrado"
    },
    "316": {
      "name": "Recuperação Real de Senha",
      "status": "integrado"
    },
    "317": {
      "name": "Autenticação Multifator",
      "status": "integrado"
    },
    "318": {
      "name": "Papéis e Permissões Reais",
      "status": "integrado"
    },
    "319": {
      "name": "Proteção das Rotas",
      "status": "integrado"
    },
    "320": {
      "name": "Auditoria de Segurança",
      "status": "integrado"
    }
  }
}
```

### 9.40 — `backend/docs/FASE_43_PACOTES_321_A_330.md`

```text
# Fase 43 — APIs Pecuárias Reais

Esta fase preserva as APIs existentes de empresas e fazendas e adiciona
modelos relacionais, migração e endpoints executáveis para lotes, animais,
identificadores, movimentações, pesagens, reprodução, sanidade, nutrição,
estoque e custos.

## Integrações automáticas
- pesagem atualiza o peso corrente do animal;
- movimentação atualiza o lote e a situação;
- nutrição pode baixar estoque;
- nutrição pode gerar despesa financeira;
- estoque impede saldo negativo.

## Segurança
Todas as consultas são filtradas por empresa e por fazendas autorizadas.
```

### 9.41 — `backend/docs/FASE_43_STATUS.json`

```text
{
  "phase": 43,
  "current_package": 330,
  "packages": {
    "321": {
      "name": "API Real de Empresas",
      "status": "integrado"
    },
    "322": {
      "name": "API Real de Fazendas",
      "status": "integrado"
    },
    "323": {
      "name": "API Real de Lotes",
      "status": "integrado"
    },
    "324": {
      "name": "API Real de Animais",
      "status": "integrado"
    },
    "325": {
      "name": "Identificadores e Prevenção de Duplicidade",
      "status": "integrado"
    },
    "326": {
      "name": "Movimentações de Animais",
      "status": "integrado"
    },
    "327": {
      "name": "API Real de Pesagens",
      "status": "integrado"
    },
    "328": {
      "name": "API Real de Reprodução",
      "status": "integrado"
    },
    "329": {
      "name": "API Real de Sanidade",
      "status": "integrado"
    },
    "330": {
      "name": "API Real de Nutrição, Estoque e Custos",
      "status": "integrado"
    }
  }
}
```

### 9.42 — `backend/docs/offline/SPRINTS_51_A_60.md`

```text
# Sprints 51 a 60 — Operação offline

Esta entrega estabelece o contrato oficial para banco local, fila de operações, push idempotente, pull incremental, conflitos, dispositivos, diagnósticos e confiabilidade em campo.

## Regras

1. Toda mutação offline recebe `operation_id` e `idempotency_key`.
2. Operações respeitam dependências: fazenda → lote → animal → evento.
3. O pull é paginado por cursor crescente e persiste `next_cursor` localmente.
4. Conflitos nunca são resolvidos silenciosamente.
5. Exclusões são lógicas.
6. Sessões offline respeitam validade e permissões armazenadas.
7. Dados sensíveis devem usar armazenamento seguro do sistema operacional.
8. Diagnósticos não devem transportar senhas, tokens ou dados clínicos completos.
```

### 9.43 — `backend/docs/operational/SPRINTS_41_A_50.md`

```text
# Sprints 41 a 50 — Núcleo pecuário confiável

Esta entrega adiciona um validador somente leitura para os dez domínios operacionais oficiais:

1. fazendas;
2. lotes;
3. animais;
4. pesagens;
5. movimentações;
6. reprodução;
7. sanidade;
8. nutrição;
9. estoque;
10. financeiro.

## Endpoint

`GET /api/v1/core-validation/farms/{farm_id}`

A resposta inclui score por domínio, inconsistências detectadas e score consolidado. O endpoint respeita empresa, tenant, fazendas autorizadas e a permissão `platform.read`.

## Validações principais

- fazenda existente, nome e área válidos;
- lote acima da capacidade ou inativo com animais;
- animais sem brinco, sem lote, sem peso ou com peso negativo;
- peso atual divergente da última pesagem;
- mudança de lote sem destino ou para o mesmo lote;
- evento reprodutivo em animal macho;
- carências sanitárias ativas;
- quantidade ou custo nutricional negativo;
- estoque negativo e produtos abaixo do mínimo;
- lançamento financeiro com valor negativo.

## CLI

'''powershell
python scripts/operational/run_core_validation.py --company-id COMPANY_ID --farm-id FARM_ID --fail-on-issues
'''

## Testes

'''powershell
python -m pytest -q tests/test_core_livestock_validation.py
'''

O validador não altera dados. Ele foi criado para localizar inconsistências antes de operações de piloto, importações, sincronizações ou análises da IA.
```

### 9.44 — `backend/docs/PACOTE_301_AUDITORIA_BACKEND.md`

```text
# Pacote 301 — Auditoria do backend existente

## Resultado confirmado
- Stack: FastAPI + SQLAlchemy
- Arquivos Python em `app/`: 25
- Routers encontrados: 10
- Arquivos de teste encontrados: 7

## Achados prioritários
- **HIGH** — create_all ainda é usado no startup; migrações Alembic devem ser a fonte de verdade.
- **HIGH** — Existe segredo padrão de desenvolvimento; produção deve rejeitar segredos fracos.

## Decisão arquitetural
A Fase 41 preserva a API FastAPI existente e evolui sua estrutura sem reescrever rotas funcionais. O `create_all` fica permitido apenas em desenvolvimento/testes; homologação e produção passam a depender de migrações versionadas.
```

### 9.45 — `backend/docs/PACOTE_302_ARQUITETURA_SERVIDOR.md`

```text
# Pacote 302 — Arquitetura do servidor

A estrutura foi separada em `core`, `db`, `repositories`, `routers` e `services`, preservando compatibilidade com os imports existentes.
```

### 9.46 — `backend/docs/PACOTE_309_DOCUMENTACAO_API.md`

```text
# Documentação da API

- Swagger UI: `/docs`
- ReDoc: `/redoc`
- OpenAPI JSON: `/openapi.json`
- Prefixo: `/api/v1`
- Autenticação: Bearer JWT
```

### 9.47 — `backend/docs/PACOTE_311_CADASTRO_REAL.md`

```text
# Pacote 311
Cadastro real com empresa proprietária, vínculo owner e token de confirmação.
```

### 9.48 — `backend/docs/PACOTE_312_HASH_SENHAS.md`

```text
# Pacote 312
Bcrypt, política de força e tratamento de hash inválido.
```

### 9.49 — `backend/docs/PACOTE_313_CONFIRMACAO_EMAIL.md`

```text
# Pacote 313
Tokens opacos armazenados apenas como SHA-256, validade e uso único.
```

### 9.50 — `backend/docs/PACOTE_314_LOGIN_REAL.md`

```text
# Pacote 314
Login no banco, bloqueio por tentativas e eventos de segurança.
```

### 9.51 — `backend/docs/PACOTE_315_SESSOES.md`

```text
# Pacote 315
Refresh token rotativo, revogação, sessões e encerramento remoto.
```

### 9.52 — `backend/docs/PACOTE_316_RECUPERACAO_SENHA.md`

```text
# Pacote 316
Token temporário, redefinição, uso único e revogação das sessões.
```

### 9.53 — `backend/docs/PACOTE_317_MFA.md`

```text
# Pacote 317
TOTP, URI de provisionamento e códigos de recuperação.
```

### 9.54 — `backend/docs/PACOTE_318_RBAC.md`

```text
# Pacote 318
Papéis e permissões existentes foram preservados e integrados às sessões reais.
```

### 9.55 — `backend/docs/PACOTE_319_PROTECAO_ROTAS.md`

```text
# Pacote 319
Tokens tipados, tenant, empresa, papel e permissões continuam obrigatórios nas rotas protegidas.
```

### 9.56 — `backend/docs/PACOTE_320_AUDITORIA_SEGURANCA.md`

```text
# Pacote 320
Eventos de login, sessão, senha, MFA e cadastro são registrados.
```

### 9.57 — `backend/docs/precision/SPRINTS_71_A_80.md`

```text
# Sprints 71 a 80 — Precision Hub

Implementação integrada ao cadastro oficial de animais, aos dispositivos `atlas_iot_devices_v2`, à telemetria oficial, ao Atlas Vision e aos ativos geográficos existentes.

## Capacidades
- adaptadores de fabricantes e rotação externa de segredos;
- RFID único por empresa e associação ao animal oficial;
- balança com validação de estabilidade e faixa plausível;
- GPS e geocercas com alertas;
- THI e alertas ambientais;
- nível/fluxo de água e alertas de cocho/bebedouro;
- pipeline de visão com revisão humana;
- GeoJSON para limites, piquetes, cercas e infraestrutura;
- cenas de sensoriamento remoto com índices e rastreabilidade.

Resultados de modelos externos nunca são inventados. Vision e sensoriamento remoto armazenam contratos, versões, confiança e revisão, enquanto inferência real depende de adaptador homologado.
```

### 9.58 — `backend/docs/quality/API_CONVENTIONS.md`

```text
# Convenções oficiais da API Atlas

- `GET`: leitura, sem alteração de estado.
- `POST`: criação ou comando explícito.
- `PUT`: substituição idempotente.
- `PATCH`: alteração parcial.
- `DELETE`: exclusão lógica; `204` deve usar `Response` e não ter corpo.
- erros de validação: `422`.
- autenticação ausente ou inválida: `401`.
- permissão insuficiente: `403`.
- entidade inexistente no escopo: `404`.
- conflito de versão ou estado: `409`.
- paginação: `limit`, `offset` e total quando aplicável.
- toda requisição recebe `X-Request-ID`.
```

### 9.59 — `backend/docs/quality/FLUTTER_QUALITY_GUIDE.md`

```text
# Gate Flutter

O gate obrigatório executa, nesta ordem:

1. `flutter clean`
2. `flutter pub get`
3. `dart format --output=none --set-exit-if-changed lib test`
4. `flutter analyze`
5. `flutter test`

Contratos obrigatórios:

- usar `AtlasHttpClient.send()`;
- converter respostas com `asMap()` ou `asMapList()`;
- não aplicar `.toList()` dentro do widget criado pelo `map()`;
- não enviar `String?` para parâmetros `String` sem normalização;
- telas devem possuir estados de carregamento, erro, vazio e atualização.
```

### 9.60 — `backend/docs/quality/SPRINTS_31_A_40.md`

```text
# Sprints 31 a 40 — Consolidação e qualidade

## Entregas implementadas

- verificador do grafo de migrations e head único;
- verificador de arquitetura e imports legados;
- validação do OpenAPI e `operationId` único;
- gate de qualidade centralizado;
- testes de headers, request ID, diagnóstico e OpenAPI;
- endpoint `/api/v1/quality/version`;
- endpoint `/api/v1/quality/diagnostics`;
- endpoint `/api/v1/quality/ready`;
- middleware de observabilidade formatado e métricas de duração;
- middleware de segurança com rate limit configurável e headers seguros;
- configuração de documentação habilitável por ambiente;
- workflow CI para backend e Flutter;
- script PowerShell completo para qualidade Flutter.

## Limite desta entrega

A pasta recebida contém o backend, mas não contém o código Flutter completo. Por isso, os Sprints 35 a 38 foram implementados como gate, convenções e CI executáveis sobre a raiz real do projeto. Correções específicas nas telas devem ser feitas sobre a pasta `lib` atual após a execução de `flutter analyze`.

## Comando único do backend

'''powershell
python scripts/quality/run_quality_gate.py
'''

## Comando único do Flutter

Na raiz do projeto:

'''powershell
powershell -ExecutionPolicy Bypass -File backend/scripts/quality/run_flutter_quality.ps1
'''
```

### 9.61 — `backend/docs/release/SPRINTS_121_A_130.md`

```text
# Sprints 121 a 130 — Release, pilotos e Atlas 3.0

Implementa homologação, pilotos técnico e comercial, perfis Android/iOS, release web, treinamento, documentação, crescimento, revisão de capacidades, roadmap de cinco anos e avaliação de prontidão. Integrações com lojas, hospedagem e analytics externos dependem das credenciais oficiais.
```

### 9.62 — `backend/docs/saas/SPRINTS_91_A_100.md`

```text
# Sprints 91 a 100

Implementa planos/licenças, assinatura, cobrança/faturas, portal do cliente, painel administrativo, feature flags, comunicação, onboarding, importação e exportação.

## Segurança
Credenciais de provedores não são persistidas nestas tabelas. Webhooks e pagamentos reais exigem validação criptográfica e credenciais oficiais.

## Importação
Jobs preservam mapeamento, prévia e relatório de erros. A aplicação efetiva dos dados deve ser transacional e idempotente por domínio.

## Exportação
Jobs aceitam CSV, XLSX, PDF e JSON. O arquivo final deve ser produzido por worker e armazenado em storage autorizado.
```

### 9.63 — `backend/docs/security/SPRINTS_111_A_120.md`

```text
# Sprints 111 a 120

RBAC, segurança de API, auditoria encadeada, LGPD, backups, disponibilidade, internacionalização, regras regionais, certificações e continuidade operacional.
```

### 9.64 — `backend/docs/TEST_RESULT_PHASE_41.json`

```text
{
  "attempted": true,
  "passed": false,
  "stdout": "",
  "stderr": "ImportError while loading conftest '/mnt/data/atlas_phase_41_packages_301_310/pacote_310/Projetos Atlas/backend/tests/conftest.py'.\ntests/conftest.py:17: in <module>\n    from app.main import app\napp/main.py:5: in <module>\n    from .bootstrap import bootstrap\napp/bootstrap.py:6: in <module>\n    from .security import hash_password\napp/security.py:4: in <module>\n    from jose import JWTError, jwt\nE   ModuleNotFoundError: No module named 'jose'\n",
  "returncode": 4
}
```

### 9.65 — `backend/docs/TEST_RESULT_PHASE_42.json`

```text
{
  "phase": 42,
  "syntax_files_compiled": 55,
  "syntax_errors": [],
  "pytest_executed": false,
  "reason": "Dependências do backend não foram instaladas neste ambiente de geração."
}
```

### 9.66 — `backend/docs/TEST_RESULT_PHASE_43.json`

```text
{
  "phase": 43,
  "syntax_files_compiled": 59,
  "syntax_errors": [],
  "pytest_executed": false,
  "reason": "Dependências e PostgreSQL não estão instalados/configurados neste ambiente de geração."
}
```

### 9.67 — `backend/LEIA_ME_BACKEND_COMPLETO_SPRINTS_26_A_30.md`

```text
# Projeto Atlas — Backend completo consolidado

Esta entrega contém a pasta `backend` completa, consolidada até os Sprints 26 a 30.

## Arquitetura corrigida
Os arquivos genéricos `sprint_models.py`, `sprints_16_20_models.py` e `sprints_21_25_models.py` foram substituídos por:
- `innovation_models.py`
- `enterprise_product_models.py`
- `operations_intelligence_models.py`
- `enterprise_growth_models.py`

## Sprints 26–30
- Financeiro Enterprise: `/api/v1/finance-enterprise`
- Estoque Enterprise: `/api/v1/inventory-enterprise`
- Ecossistema Atlas: `/api/v1/ecosystem`
- Inteligência Corporativa: `/api/v1/corporate-intelligence`
- Plataforma Global: `/api/v1/global-platform`

## Aplicação
Substitua a pasta `backend` inteira pela pasta desta entrega. Faça backup do banco antes.

'''powershell
cd "C:\caminho\para\Projetos Atlas\backend"
python -m pip install -r requirements.txt
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
'''

A migration nova é `20260806_0028`, dependente de `20260806_0027`.
```

### 9.68 — `backend/LEIA_ME_CORRECAO_204.md`

```text
# Correção das rotas HTTP 204

Esta entrega corrige as rotas de exclusão lógica do núcleo pecuário que impediam o FastAPI de iniciar.

## Problema corrigido

O FastAPI não permite corpo de resposta em rotas com status `204 No Content`. As rotas abaixo declaravam `204`, mas a assinatura permitia inferência de modelo de resposta:

- `DELETE /api/v1/livestock/lots/{lot_id}`
- `DELETE /api/v1/livestock/animals/{animal_id}`

Agora ambas usam explicitamente:

'''python
response_class=Response
response_model=None
'''

e retornam:

'''python
Response(status_code=status.HTTP_204_NO_CONTENT)
'''

## Como substituir

1. Pare o servidor com `Ctrl + C`.
2. Renomeie a pasta atual `backend` para backup.
3. Extraia este ZIP diretamente na raiz do Projeto Atlas.
4. Entre na nova pasta `backend`.
5. Recrie ou ative a `.venv`.
6. Instale `requirements.txt`.
7. Inicie o servidor novamente.

'''powershell
cd "C:\Projetos\Projetos Atlas\backend"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_local.db"
python -m uvicorn app.main:app --reload
'''
```

### 9.69 — `backend/LEIA_ME_CORRECAO_CONTEXT_BUILDER.md`

```text
# Correção do contexto da IA

## Erro corrigido

O arquivo `app/ai/context_builder.py` importava a classe inexistente `Animal`.
A arquitetura oficial usa `LivestockAnimal`, da tabela `livestock_animals`.

A consulta do contexto da IA agora utiliza `LivestockAnimal.company_id` e
`LivestockAnimal.farm_id`.

## Banco de dados local

O arquivo `.env` atual aponta para PostgreSQL em `127.0.0.1:5432`.
O PostgreSQL precisa estar ativo antes de executar Alembic ou a API.

Para validar temporariamente com SQLite no PowerShell:

'''powershell
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_local.db"
python -m uvicorn app.main:app --reload
'''

Essas variáveis valem somente para a janela atual do terminal.

Para usar PostgreSQL, inicie o serviço ou o Docker Compose antes:

'''powershell
docker compose up -d postgres
python -m alembic upgrade head
python -m uvicorn app.main:app --reload
'''

## Validação

'''powershell
python -m compileall app
'''
```

### 9.70 — `backend/LEIA_ME_CORRECAO_DEPENDENCIES.md`

```text
# Correção da camada de dependências

Esta entrega corrige o erro:

'''text
ModuleNotFoundError: No module named 'app.dependencies'
'''

Foi criado o arquivo completo:

'''text
backend/app/dependencies.py
'''

Ele utiliza a fonte oficial de autenticação em `app.authz`:

- `get_current_context()` retorna `Principal`;
- `get_current_user()` retorna `principal.user` para compatibilidade.

## Aplicação

Substitua a pasta `backend` atual pela pasta completa desta entrega.
Preserve o arquivo `.env` atual, caso ele contenha configurações próprias.

## Teste com SQLite

'''powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_local.db"
python -m uvicorn app.main:app --reload
'''
```

### 9.71 — `backend/LEIA_ME_CORRECAO_MODELOS_PECUARIOS.md`

```text
# Correção de compatibilidade dos modelos pecuários

Esta pasta backend completa corrige os imports históricos que ainda esperavam
nomes como `LivestockLot` e `LivestockWeight`.

Os aliases foram centralizados em `app/models.py` e apontam para as mesmas
classes/tabelas oficiais:

- `LivestockLot = HerdLot`
- `LivestockWeight = WeightRecord`
- `LivestockHealthEvent = HealthEvent`
- `LivestockNutritionEvent = NutritionEvent`
- `LivestockReproductionEvent = ReproductionEvent`

Nenhuma tabela nova foi criada e nenhuma migration é necessária para esta
correção.

## Teste local com SQLite

'''powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_local.db"
python -m uvicorn app.main:app --reload
'''
```

### 9.72 — `backend/LEIA_ME_CORRECAO_TABELAS_DUPLICADAS.md`

```text
# Correção de tabelas SQLAlchemy duplicadas

Esta entrega corrige declarações duplicadas na mesma `MetaData`:

- `workflow_definitions` e `workflow_instances` permanecem como tabelas oficiais do motor de automação existente.
- O módulo Enterprise Operations passa a usar `enterprise_workflow_definitions` e `enterprise_workflow_instances`.
- `privacy_requests` permanece como tabela oficial do módulo de privacidade existente.
- O módulo Security & Compliance passa a usar `compliance_privacy_requests`.

As migrations 0032 e 0035 foram atualizadas de forma coerente. A cadeia mantém 36 revisões e head único `20260806_0036`.
```

### 9.73 — `backend/LEIA_ME_INSTALACAO_CORRIGIDA.txt`

```text
ATLAS - BACKEND COMPLETO CORRIGIDO

Este ZIP já contém a pasta backend diretamente na raiz.

COMO INSTALAR
1. Feche o servidor do backend, se estiver aberto.
2. Na pasta C:\Projetos\Projetos Atlas, mantenha backend_backup como segurança.
3. Extraia este ZIP diretamente em C:\Projetos\Projetos Atlas.
4. Confirme que existe:
   C:\Projetos\Projetos Atlas\backend\app
   C:\Projetos\Projetos Atlas\backend\alembic
   C:\Projetos\Projetos Atlas\backend\.env
5. Abra o PowerShell na pasta do projeto e execute:

   cd .\backend
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   python -m pip install --upgrade pip
   python -m pip install -r requirements.txt
   python -m alembic upgrade head
   python -m pytest -q
   python -m uvicorn app.main:app --reload

OBSERVACOES
- O .env da pasta backend_backup enviada foi preservado nesta entrega.
- A pasta .venv nao foi incluida. Ela deve ser recriada no seu computador.
- Caches e backups temporarios foram removidos.
```

### 9.74 — `backend/LEIA_ME_SPRINTS_101_A_110.md`

```text
# Sprints 101 a 110 — Plataforma de Dados e Resiliência

- 101: eventos de domínio, outbox, idempotência e dead-letter.
- 102: dimensões e fatos para warehouse incremental.
- 103: catálogo versionado de KPIs e observações com qualidade.
- 104: benchmark anonimizado com amostra mínima e percentis.
- 105: definições configuráveis de relatórios.
- 106: métricas incrementais em tempo real.
- 107: índices e consultas paginadas preparados pela migration.
- 108: cache com isolamento por empresa e expiração.
- 109: fila persistente de jobs, tentativas e backoff.
- 110: limites, idempotência, retentativas e recuperação controlada.

Integrações com Redis, Kafka/RabbitMQ, Celery/RQ e warehouse externo podem ser conectadas posteriormente sem alterar os contratos centrais.
```

### 9.75 — `backend/LEIA_ME_SPRINTS_111_A_120.md`

```text
# Atlas — Sprints 111 a 120

Execute `python -m alembic upgrade head`, `python scripts/security/check_security_compliance.py` e `python -m pytest -q`.
```

### 9.76 — `backend/LEIA_ME_SPRINTS_121_A_130.md`

```text
# Sprints 121 a 130 — Release, pilotos e Atlas 3.0

Implementa homologação, pilotos técnico e comercial, perfis Android/iOS, release web, treinamento, documentação, crescimento, revisão de capacidades, roadmap de cinco anos e avaliação de prontidão. Integrações com lojas, hospedagem e analytics externos dependem das credenciais oficiais.
```

### 9.77 — `backend/LEIA_ME_SPRINTS_31_A_40.md`

```text
# Aplicação — Sprints 31 a 40

Esta entrega contém a pasta `backend` completa, baseada na versão que já iniciou com sucesso.

## Substituição

1. Pare o Uvicorn.
2. Renomeie a pasta atual para backup.
3. Extraia o ZIP na raiz do Projeto Atlas.
4. Reaproveite a `.venv` anterior ou crie uma nova.

## Execução

'''powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_quality.db"
$env:ATLAS_JWT_SECRET="quality-gate-secret-with-at-least-32-characters"
python scripts/quality/run_quality_gate.py
'''

## Flutter

'''powershell
powershell -ExecutionPolicy Bypass -File backend/scripts/quality/run_flutter_quality.ps1
'''
```

### 9.78 — `backend/LEIA_ME_SPRINTS_41_A_50.md`

```text
# Projeto Atlas — Sprints 41 a 50

Entrega completa do backend consolidado, com validação operacional dos módulos oficiais de fazenda, lote, animal, pesagem, movimentação, reprodução, sanidade, nutrição, estoque e financeiro.

## Aplicação

Preserve seu `.env` e sua `.venv`. Substitua a pasta backend pela pasta deste pacote ou copie os arquivos completos mantendo os caminhos.

## Comandos

'''powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
$env:ATLAS_ENV="test"
$env:ATLAS_DATABASE_URL="sqlite:///./atlas_core_validation.db"
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
'''

Abra `/docs` e consulte `GET /api/v1/core-validation/farms/{farm_id}`.

Nenhuma migration nova é necessária: a entrega utiliza apenas tabelas oficiais existentes.
```

### 9.79 — `backend/LEIA_ME_SPRINTS_81_A_90.md`

```text
# Atlas — Sprints 81 a 90

Execute `python -m alembic upgrade head`, `python scripts/enterprise/check_enterprise_operations.py`, `python -m pytest -q` e `python -m uvicorn app.main:app --reload`.
```

### 9.80 — `backend/LEIA_ME_SPRINTS_91_A_100.md`

```text
# Atlas — Sprints 91 a 100

1. Preserve `.env` e `.venv`.
2. Execute `python -m alembic upgrade head`.
3. Execute `python scripts/saas/check_saas_growth.py`.
4. Execute `python -m pytest -q`.
5. Inicie com `python -m uvicorn app.main:app --reload`.
```

### 9.81 — `CHECKLIST_FINAL_PROJETO_ATLAS.md`

```text
# Checklist Final — Projeto Atlas Pacote 100

## Código
- [ ] `flutter analyze` sem erros.
- [ ] `flutter test` aprovado.
- [ ] Testes manuais dos módulos principais.
- [ ] Navegação e formulários conferidos.
- [ ] Erros e estados vazios revisados.

## Dados e backend
- [ ] `backend/.env` preservado e configurado.
- [ ] Banco de dados com backup.
- [ ] Migrações testadas.
- [ ] Permissões e autenticação revisadas.
- [ ] Logs e auditoria habilitados.

## Segurança
- [ ] Segredos fora do código.
- [ ] Controle de acesso por função.
- [ ] Proteção de dados pessoais.
- [ ] Plano de resposta a incidentes.
- [ ] Dependências atualizadas e revisadas.

## Produção
- [ ] Ambiente de homologação validado.
- [ ] Plano de publicação aprovado.
- [ ] Plano de rollback testado.
- [ ] Monitoramento e alertas configurados.
- [ ] Responsáveis pelo suporte definidos.

## Comandos
'''powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d windows
'''
```

### 9.82 — `CICLO_1_IMPLEMENTADO.txt`

```text
Ciclo 1 — Sprints 131 a 135 implementado sobre a versão Flutter enviada em 2026-08-06.
```

### 9.83 — `CICLO_2_IMPLEMENTADO.txt`

```text
CICLO 2 IMPLEMENTADO
Sprints 136 a 140
- Rebanho remoto por fazenda ativa
- Busca e filtros
- CRUD de lotes
- CRUD de animais
- Detalhes e linha do tempo
- Pesagens oficiais
- Movimentações oficiais
- RadioGroup moderno no seletor de fazenda
```

### 9.84 — `CICLO_3_IMPLEMENTADO.txt`

```text
CICLO 3 IMPLEMENTADO
Sprints 141 a 145
Reprodução, sanidade, nutrição, estoque e financeiro integrados à fazenda ativa.
```

### 9.85 — `CICLO_4_IMPLEMENTADO.txt`

```text
CICLO 4 IMPLEMENTADO
Sprints 146 a 150
Banco local, fila, pull, push e conflitos integrados.
```

### 9.86 — `CICLOS_10_A_12_IMPLEMENTADOS.txt`

```text
Ciclos 10, 11 e 12 implementados sobre a base consolidada dos Ciclos 7 a 9.
Inclui Dados e Analytics, Segurança e Conformidade, Qualidade Flutter, testes e gate unificado.
```

### 9.87 — `CICLOS_13_A_15_IMPLEMENTADOS.txt`

```text
Ciclos 13, 14 e 15 implementados sobre a base consolidada.
Correção use_build_context_synchronously aplicada.
```

### 9.88 — `CICLOS_16_A_18_IMPLEMENTADOS.txt`

```text
Ciclos 16, 17 e 18 implementados sobre o checkpoint dos ciclos 13 a 15.
```

### 9.89 — `CICLOS_19_E_20_IMPLEMENTADOS.txt`

```text
Ciclos 19 e 20 implementados.
Erro de sintaxe da Central do Piloto corrigido.
```

### 9.90 — `CICLOS_5_E_6_IMPLEMENTADOS.txt`

```text
Ciclos 5 e 6 implementados sobre o Ciclo 4.
```

### 9.91 — `CICLOS_7_A_9_IMPLEMENTADOS.txt`

```text
Ciclos 7, 8 e 9 implementados.
Import não utilizado do offline_sync_coordinator.dart removido.
```

### 9.92 — `CORRECAO_19_CURLY_BRACES_CONFIRMADA.txt`

```text
CORREÇÃO DOS AVISOS CURLY BRACES

Os arquivos apontados pelo flutter analyze foram corrigidos para usar blocos explícitos em estruturas if.
Nenhuma regra de negócio foi alterada.
```

### 9.93 — `CORRECAO_ADB_AUTOMATICO_CONFIRMADA.txt`

```text
ATLAS ANDROID 1.0 - CORRECAO ADB AUTOMATICO

O Atlas agora procura o adb.exe automaticamente em:
- PATH
- ANDROID_SDK_ROOT
- ANDROID_HOME
- android/local.properties
- %LOCALAPPDATA%/Android/Sdk/platform-tools/adb.exe

Scripts atualizados:
- scripts/android/atlas_android_common.ps1
- scripts/android/03_check_android_device.ps1
- scripts/android/07_install_android_apk.ps1
```

### 9.94 — `CORRECAO_FINAL_ENUM_44_45_46_LEIA_ME.txt`

```text
CORREÇÃO FINAL VERIFICADA — PACOTES 44, 45 E 46

A captura mostrava que o arquivo instalado ainda não possuía corretamente
commercialization45 no enum AnimalHubSection.

Nesta entrega, o enum foi reconstruído integralmente e validado.

Valores finais dos módulos 44 a 46:
- purchases44
- commercialization45
- logistics46

Também foram validadas:
- as três opções no switch da Central do Animal;
- os três botões da sexta linha;
- a presença única de cada valor no enum.

IMPORTANTE
----------
Não copie somente alguns arquivos do ZIP anterior.

Opção mais segura:
1. Preserve backend/.env.
2. Exclua a pasta antiga do projeto.
3. Extraia este ZIP completo no mesmo local.
4. Abra novamente a pasta no VS Code.
5. Feche e reabra o VS Code para reiniciar o Dart Analyzer.

Comandos:
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d windows

Também foi fornecido separadamente o arquivo completo:
animal_detail_screen_CORRIGIDO_COMPLETO.dart

Caso prefira corrigir apenas esse arquivo, substitua integralmente:
lib/features/animal/presentation/screens/animal_detail_screen.dart
```

### 9.95 — `CORRECAO_NAVEGACAO_DUAS_LINHAS_LEIA_ME.txt`

```text
CORREÇÃO — NAVEGAÇÃO EM DUAS LINHAS

Alteração implementada
----------------------
A barra horizontal com rolagem foi substituída por duas linhas fixas.

Linha 1
-------
- Resumo
- Timeline
- Zootecnia
- Manejo
- Genealogia
- Fotos

Linha 2
-------
- Documentos
- Sanidade+
- Reprodução+
- Pesagens+
- Nutrição
- Executivo

Benefícios
----------
- todos os módulos ficam visíveis ao mesmo tempo;
- elimina rolagem horizontal;
- reduz cliques;
- melhora o uso em notebook e desktop;
- botões com a mesma largura;
- módulo selecionado em verde com ícone e texto brancos;
- demais módulos em fundo branco com ícone verde.

Arquivo completo alterado
-------------------------
lib/features/animal/presentation/screens/animal_detail_screen.dart

Validação
---------
Preserve backend/.env.

Execute:

flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d windows

Teste
-----
1. Abra a Central do Animal.
2. Confirme a existência das duas linhas.
3. Abra cada um dos 12 módulos.
4. Confirme o destaque verde da opção selecionada.
```

### 9.96 — `CORRECAO_NAVEGACAO_MODULOS_LEIA_ME.txt`

```text
CORREÇÃO — NAVEGAÇÃO DOS MÓDULOS DA CENTRAL DO ANIMAL

Problema corrigido
------------------
A quantidade de módulos ultrapassava a largura disponível da janela. Embora
a barra permitisse rolagem horizontal, o último botão ficava parcialmente
cortado e não havia indicação clara de como chegar aos módulos seguintes.

Correção implementada
---------------------
1. Setas permanentes nas extremidades da barra:
   - seta esquerda: módulos anteriores;
   - seta direita: próximos módulos.

2. Barra de rolagem horizontal visível.

3. Rolagem com mouse, touchpad e setas.

4. A opção selecionada é centralizada automaticamente.

5. Todos os módulos permanecem acessíveis:
   - Resumo;
   - Timeline;
   - Zootecnia;
   - Manejo;
   - Genealogia;
   - Fotos;
   - Documentos;
   - Sanidade+;
   - Reprodução+;
   - Pesagens+;
   - Nutrição;
   - Executivo.

6. O último botão não fica mais reduzido a um pequeno círculo.

Arquivo completo corrigido
--------------------------
lib/features/animal/presentation/screens/animal_detail_screen.dart

Validação
---------
Preserve backend/.env e execute:

flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d windows

Teste
-----
1. Abra a Central do Animal.
2. Use a seta direita depois de Reprodução+.
3. Confirme que aparecem Pesagens+, Nutrição e Executivo.
4. Abra cada um dos três módulos.
5. Use a seta esquerda para retornar aos módulos iniciais.
```

### 9.97 — `docs/android/ATLAS_ANDROID_1_PASSOS_11_A_20.md`

```text
# Atlas Android 1.0 — passos 11 a 20

## 11. Iniciar o backend
Em outro terminal execute `scripts/android/02_start_backend_lan.ps1` e mantenha-o aberto.

## 12. Validar backend
Execute `scripts/android/04_test_backend_from_pc.ps1`.

## 13. Criar túnel USB
Execute `scripts/android/09_prepare_first_android_run.ps1`. O ADB reverse permite que o celular acesse o backend pelo USB sem depender do firewall ou do Wi-Fi no primeiro teste.

## 14. Rodar no Moto G75 5G
Execute `scripts/android/05_run_on_android.ps1`. Por padrão usa o túnel USB.

## 15. Teste funcional inicial
Faça login, selecione a fazenda e abra Rebanho. Corrija apenas bloqueios reais antes do APK.

## 16–17. Gerar APK
Para um APK que continue funcionando sem USB, computador e celular devem estar na mesma rede. Execute `scripts/android/06_build_android_apk.ps1 -Mode release`; o script grava o IPv4 atual do computador no build.

## 18. Instalar
Execute `scripts/android/07_install_android_apk.ps1 -Mode release`.

## 19–20. Smoke test e aceite
Execute `scripts/android/08_android_smoke_test.ps1` e responda cada verificação no aparelho.

> Enquanto o backend estiver hospedado no computador, o computador precisa permanecer ligado e acessível pela rede para o APK release operar sem o cabo USB. Hospedagem permanente vem depois do primeiro marco Android.
```

### 9.98 — `docs/android/ATLAS_ANDROID_1_PRIMEIRO_DISPOSITIVO.md`

```text
# Atlas Android 1.0 — Primeiro dispositivo real

Este marco substitui temporariamente todos os ciclos de expansão. Nenhuma funcionalidade nova deve ser criada até o APK ser instalado e aprovado em um celular real.

## Os 20 passos

### Etapa A — congelar e validar

1. Substituir o projeto pela entrega completa deste marco.
2. Reaproveitar apenas `backend/.env` e `backend/.venv` da versão anterior.
3. Executar `flutter pub get`.
4. Executar `dart format`, `flutter analyze` e `flutter test`.
5. Executar o gate consolidado do backend e confirmar que ele inicia.

Comando:

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\01_validate_project.ps1
'''

### Etapa B — preparar o Android

6. No celular, abrir **Configurações > Sobre o telefone**.
7. Tocar sete vezes em **Número da versão** para habilitar o modo desenvolvedor.
8. Ativar **Depuração USB** nas opções do desenvolvedor.
9. Conectar o celular por um cabo USB de dados e aceitar a autorização RSA.
10. Confirmar o aparelho em `adb devices` e `flutter devices`.

Comando:

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\03_check_android_device.ps1
'''

### Etapa C — conectar o celular ao backend

11. Conectar computador e celular à mesma rede Wi-Fi.
12. Abrir o backend em `0.0.0.0:8000`, não em `127.0.0.1`.
13. Anotar o IPv4 local detectado pelo script.
14. Autorizar Python/porta 8000 no Firewall do Windows quando solicitado.
15. Executar o Flutter com `ATLAS_API_BASE_URL=http://IP_DO_PC:8000/api/v1`.

Terminal do backend:

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\02_start_backend_lan.ps1
'''

Outro terminal:

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\04_test_backend_from_pc.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\android\05_run_on_android.ps1
'''

### Etapa D — APK instalável e aceite

16. Testar abertura, login, empresa, fazenda e Rebanho no celular.
17. Gerar o APK privado do primeiro dispositivo.
18. Instalar o APK com ADB.
19. Fechar e reabrir o aplicativo e simular indisponibilidade do backend.
20. Executar o checklist de fumaça e aprovar o marco.

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\06_build_android_apk.ps1 -Mode release
powershell -ExecutionPolicy Bypass -File .\scripts\android\07_install_android_apk.ps1 -Mode release
powershell -ExecutionPolicy Bypass -File .\scripts\android\08_android_smoke_test.ps1
'''

## Onde estará o APK

'''text
dist/android/atlas-android-1.0.0-release.apk
'''

## Observações importantes

- O APK deste marco é privado e usa a assinatura de desenvolvimento. Não deve ser enviado à Play Store.
- A comunicação HTTP local foi permitida para o primeiro teste na mesma rede. Produção deve usar HTTPS.
- `127.0.0.1` no celular aponta para o próprio celular. Por isso o aplicativo recebe o IPv4 do computador por `--dart-define`.
- Caso uma URL antiga tenha sido salva nas preferências, a URL passada em `--dart-define=ATLAS_API_BASE_URL=...` tem prioridade.
- O backend deve continuar aberto durante o uso do aplicativo, salvo quando estiver testando o tratamento offline.
```

### 9.99 — `docs/atlas_automation_operations/PACOTES_59_60_61_62_ARQUITETURA.md`

```text
# Pacotes 59 a 62 — Arquitetura de Automação

## Módulos
- Drone Enterprise;
- IoT Enterprise;
- Automação de Manejos;
- Workflow Operacional.

## Entrega atual
- interface integrada;
- CRUD e histórico;
- persistência local;
- score, cobertura e alertas;
- fundamentos para dispositivos, processos e aprovações;
- testes da engine analítica.

## Integrações futuras
- SDKs de drones;
- MQTT e gateways IoT;
- telemetria;
- filas offline;
- assinatura e aprovação remota;
- motor de workflow no backend;
- auditoria Enterprise;
- WebSocket para atualizações em tempo real.
```

### 9.100 — `docs/atlas_autonomous_enterprise/PACOTES_99_100_ARQUITETURA.md`

```text
# Pacotes 99 e 100 — Autonomia e Finalização Enterprise

## Pacote 99 — Orquestrador Atlas AI
- fila de decisões;
- regras e políticas;
- aprovação humana;
- execução e acompanhamento;
- memória e aprendizado;
- confiança, risco e prioridade;
- impacto financeiro;
- trilha de auditoria.

## Pacote 100 — Centro de Finalização Enterprise
- checklist de produção;
- qualidade e testes;
- segurança e conformidade;
- publicação e rollback;
- pós-lançamento e suporte;
- evidências e responsáveis;
- bloqueios de liberação;
- acompanhamento de implantação.

## Entrega atual
- modelos;
- analytics;
- persistência local;
- CRUD completo;
- filtros;
- indicadores;
- score;
- recomendações;
- testes;
- navegação integrada;
- histórico consolidado.

## Limites
O Pacote 100 não significa que o aplicativo está automaticamente pronto para
produção. A liberação real exige execução de `flutter analyze`, testes,
validação manual, configuração de backend, banco, autenticação, segurança,
monitoramento, backups, políticas de privacidade e publicação adequada.
```

### 9.101 — `docs/atlas_commercial_operations/PACOTES_75_76_77_78_ARQUITETURA.md`

```text
# Pacotes 75 a 78 — Operações Comerciais

## Módulos
- Leilão Digital;
- Logística Pecuária;
- Certificação de Origem;
- CRM Pecuário.

## Entrega atual
- CRUD completo;
- contrapartes e identificadores;
- valores e custos;
- quantidade e distância;
- progresso, vencimentos e alertas;
- score, cobertura e recomendações;
- persistência local;
- testes da engine analítica;
- navegação integrada à Central do Animal.

## Organização dos scripts históricos
Todos os arquivos da raiz cujo nome começa com `PACOTE` e contém
`LEIA_ME`, independentemente da numeração ou sufixo, foram agrupados em:

`HISTORICO_UNICO_PACOTES_ATLAS.txt`

Isso inclui variações como:
- PACOTE_24E1_LEIA_ME;
- PACOTE_24E2_LEIA_ME;
- PACOTE_24E3B_LEIA_ME;
- PACOTE_25_1_LEIA_ME;
- PACOTE_25_9_1_LEIA_ME;
- PACOTE_41_LEIA_ME;
- e demais arquivos equivalentes.

## Limites
A entrega não executa leilão, transporte, certificação ou contato comercial
externo automaticamente. Operações reais exigem parceiros, documentos,
autorizações, pagamentos, integrações e validação profissional.
```

### 9.102 — `docs/atlas_connected_offline/CORRECAO_BACKUPS_FASE_44.md`

```text
# Correção da Fase 44 — Métodos de backup

Foram restaurados no `AtlasEnterpriseApiClient`:

- `backups()`, usando `GET /backups`;
- `runBackup()`, usando `POST /backups/run`.

A correção elimina os erros exibidos em
`atlas_enterprise_24d_screen.dart`.
```

### 9.103 — `docs/atlas_enterprise_operations/PACOTES_79_80_81_82_83_ARQUITETURA.md`

```text
# Pacotes 79 a 83 — Operações Enterprise

## Módulos
- Compras Enterprise;
- Portal do Fornecedor;
- Estoque Inteligente;
- Manutenção de Ativos;
- Serviços de Campo.

## Entrega atual
- CRUD completo;
- contrapartes e identificadores;
- valores e custos;
- quantidades e níveis operacionais;
- progresso, vencimentos e alertas;
- score, cobertura e recomendações;
- persistência local;
- testes da engine analítica;
- navegação integrada à Central do Animal.

## Organização dos scripts históricos
A raiz permanece organizada com um único arquivo:

`HISTORICO_UNICO_PACOTES_ATLAS.txt`

Nenhum arquivo separado no padrão `PACOTE_*_LEIA_ME` é mantido.

## Limites
A entrega não executa compras, homologações, inventários físicos, ordens de
manutenção ou serviços externos automaticamente. Operações reais exigem
processos, permissões, dados confiáveis, integrações e validação profissional.
```

### 9.104 — `docs/atlas_environmental_ai/PACOTES_56_57_58_ARQUITETURA.md`

```text
# Pacotes 56, 57 e 58 — Arquitetura Ambiental

## Módulos
- IA Climática;
- IA de Pastagens;
- Monitoramento por Satélite.

## Princípios
- análises explicáveis;
- score, risco e confiança;
- entrada manual compatível com operação offline;
- integração futura com meteorologia e Sentinel;
- confirmação dos alertas em campo.

## Integrações futuras
- API meteorológica;
- Sentinel Hub ou serviço equivalente;
- catálogo de cenas;
- armazenamento de imagens e metadados;
- séries temporais por piquete;
- alertas automáticos por limiar.
```

### 9.105 — `docs/atlas_executive_intelligence/PACOTES_89_90_91_92_93_ARQUITETURA.md`

```text
# Pacotes 89 a 93 — Inteligência Executiva

## Módulos
- CRM Enterprise;
- Central Financeira;
- Business Intelligence;
- Central Estratégica Atlas AI;
- Enterprise Command Center.

## Entrega atual
- CRUD completo;
- responsáveis e identificadores;
- valores, impactos e quantidades;
- notas, progresso, prazos e alertas;
- cobertura, score e recomendações;
- persistência local;
- testes da engine analítica;
- navegação integrada à Central do Animal;
- histórico consolidado em arquivo único.

## Organização
O histórico permanece em:

`HISTORICO_UNICO_PACOTES_ATLAS.txt`

Nenhum arquivo separado no padrão `PACOTE_*_LEIA_ME` é mantido.

## Limites
Os módulos apoiam decisões, mas não substituem análise financeira, contábil,
estratégica ou executiva. Indicadores dependem de dados confiáveis e validação
dos responsáveis.
```

### 9.106 — `docs/atlas_financial_integrations/PACOTES_67_68_69_70_ARQUITETURA.md`

```text
# Pacotes 67 a 70 — Integrações Financeiras e Fiscais

## Módulos
- Receita Federal;
- Banco do Brasil;
- Pagamentos Pix;
- NF-e Rural.

## Entrega atual
- central preparatória;
- CRUD completo;
- identificadores e documentos;
- contrapartes;
- valores brutos, tarifas e líquidos;
- vencimentos, progresso e alertas;
- score, cobertura e recomendações;
- persistência local;
- testes da engine analítica.

## Limite da entrega
Nenhum módulo realiza transmissão, pagamento, cobrança ou autorização real.
Essas operações exigem APIs homologadas, certificados, credenciais,
consentimento, regras vigentes, proteção de dados e revisão humana.

## Evolução futura
- conectores bancários oficiais;
- OAuth/mTLS e certificados;
- webhooks e idempotência;
- conciliação automática;
- emissão e armazenamento de XML;
- filas seguras e reprocessamento;
- auditoria no backend;
- segregação de funções e dupla aprovação.
```

### 9.107 — `docs/atlas_governance_operations/PACOTES_84_85_86_87_88_ARQUITETURA.md`

```text
# Pacotes 84 a 88 — Governança e Desenvolvimento

## Módulos
- Gestão da Qualidade;
- Compliance Enterprise;
- Portfólio de Projetos;
- Gestão de Equipes;
- Academia Atlas.

## Entrega atual
- CRUD completo;
- responsáveis e identificadores;
- valores, custos e benefícios;
- quantidades, notas e indicadores;
- progresso, vencimentos e alertas;
- score, cobertura e recomendações;
- persistência local;
- testes da engine analítica;
- navegação integrada à Central do Animal.

## Organização dos scripts históricos
A raiz permanece organizada com um único arquivo:

`HISTORICO_UNICO_PACOTES_ATLAS.txt`

Nenhum arquivo separado no padrão `PACOTE_*_LEIA_ME` é mantido.

## Limites
A entrega não substitui auditorias, decisões jurídicas, trabalhistas,
certificações ou aprovações corporativas. A operação real exige responsáveis,
políticas, evidências, controles e validação profissional.
```

### 9.108 — `docs/atlas_official_integrations/PACOTES_63_64_65_66_ARQUITETURA.md`

```text
# Pacotes 63 a 66 — Integrações Oficiais

## Módulos
- SISBOV Enterprise;
- GTA Digital;
- Integração MAPA;
- eSocial Rural.

## Entrega atual
- central de preparação e conformidade;
- CRUD completo;
- protocolos e identificações externas;
- origem, destino, responsáveis e quantidade;
- progresso, alertas e vencimentos;
- score, cobertura e recomendações;
- persistência local;
- testes da engine analítica.

## Limite da entrega
Nenhum módulo transmite automaticamente para sistemas oficiais. A transmissão
real exige integração homologada, credenciais, autorização, proteção de dados,
regras vigentes e validação humana.

## Evolução futura
- conectores oficiais;
- assinatura e autenticação;
- filas idempotentes;
- retorno de protocolos;
- tratamento de rejeições;
- auditoria no backend;
- sincronização e reprocessamento seguro.
```

### 9.109 — `docs/atlas_platform_resilience/PACOTES_94_95_96_97_98_ARQUITETURA.md`

```text
# Pacotes 94 a 98 — Plataforma e Resiliência

## Módulos
- Governança de Dados;
- Integration Hub;
- Cibersegurança Atlas;
- Observabilidade Enterprise;
- Gêmeo Digital da Fazenda.

## Entrega atual
- CRUD completo;
- responsáveis e identificadores;
- valores, impactos e quantidades;
- notas, progresso, prazos e alertas;
- cobertura, score e recomendações;
- persistência local;
- testes da engine analítica;
- navegação integrada à Central do Animal;
- histórico consolidado em arquivo único.

## Organização
O histórico permanece em:

`HISTORICO_UNICO_PACOTES_ATLAS.txt`

Nenhum arquivo separado no padrão `PACOTE_*_LEIA_ME` é mantido.

## Limites
Os módulos entregam estrutura funcional e preparatória. Integrações, segurança,
telemetria, observabilidade e gêmeos digitais reais exigem infraestrutura,
credenciais, conectores, servidores e validação técnica especializada.
```

### 9.110 — `docs/atlas_predictive_ai_suite/PACOTES_53_54_55_ARQUITETURA.md`

```text
# Pacotes 53, 54 e 55 — Arquitetura Preditiva

## Módulos
- IA Nutricional;
- IA Econômica;
- IA de Comercialização.

## Princípios
- resultados explicáveis;
- premissas visíveis;
- score e nível de risco;
- confiança limitada pela completude dos dados;
- persistência local;
- testes unitários da engine.

## Limites
As projeções não são garantias de desempenho, lucro ou preço. Devem ser
validadas com dados reais, cotações atuais, avaliação profissional e
condições específicas da propriedade.
```

### 9.111 — `docs/atlas_rural_business/PACOTES_71_72_73_74_ARQUITETURA.md`

```text
# Pacotes 71 a 74 — Negócios Rurais

## Módulos
- Crédito Rural;
- Seguro Rural;
- Contratos Digitais;
- Marketplace Pecuário.

## Entrega atual
- CRUD completo;
- contrapartes e identificadores;
- valores principais e custos;
- quantidade, prazo e progresso;
- vencimentos e alertas;
- score, cobertura e recomendações;
- persistência local;
- testes da engine analítica;
- navegação integrada à Central do Animal.

## Limites
A entrega não contrata crédito, não emite apólices, não assina contratos
juridicamente e não processa pagamentos de marketplace. Operações reais
dependem de instituições, seguradoras, prestadores, identidade, consentimento,
validação jurídica, APIs e regras vigentes.

## Organização dos scripts históricos
Os arquivos PACOTE_XX_LEIA_ME da raiz foram consolidados em:
`HISTORICO_PACOTES_ESSENCIAL.txt`.

A documentação técnica detalhada continua preservada em `docs/`.
```

### 9.112 — `docs/commercial/IMPORTACAO_DADOS.md`

```text
# Importação de dados

Utilizar templates versionados. Validar identificadores, duplicidades, datas, unidades, fazenda e tenant antes de importar. Gerar relatório de erros e nunca substituir dados sem confirmação.
```

### 9.113 — `docs/commercial/ONBOARDING_CLIENTE.md`

```text
# Onboarding do cliente

1. Cadastrar empresa e fazenda. 2. Definir responsáveis e permissões. 3. Importar animais com validação. 4. Configurar módulos. 5. Treinar equipe. 6. Operação assistida por sete dias. 7. Aceite formal.
```

### 9.114 — `docs/commercial/ROTEIRO_DEMONSTRACAO.md`

```text
# Roteiro de demonstração

Demonstrar problema real, fluxo completo, operação offline, sincronização, recomendação auditável, relatório e impacto mensurável. Não usar dados pessoais reais sem autorização.
```

### 9.115 — `docs/integration/CICLO_10_DADOS_ANALYTICS.md`

```text
# Ciclo 10 — Dados e analytics

Integra eventos, KPIs, relatórios, benchmark anonimizado e métricas em tempo real aos endpoints oficiais `/analytics` e `/data-platform`.
```

### 9.116 — `docs/integration/CICLO_11_SEGURANCA_CONFORMIDADE.md`

```text
# Ciclo 11 — Segurança e conformidade

Centraliza RBAC, incidentes, auditoria imutável, LGPD, backups, certificações e continuidade operacional usando `/security-compliance`.
```

### 9.117 — `docs/integration/CICLO_12_QUALIDADE_FLUTTER.md`

```text
# Ciclo 12 — Qualidade Flutter

Formaliza testes de modelos, services, widgets, navegação e integração e um gate unificado de qualidade.
```

### 9.118 — `docs/integration/CICLO_13_QUALIDADE_BACKEND.md`

```text
# Ciclo 13 — Qualidade do backend

Sprints 191 a 195: cobertura por domínio, migrations, contratos, concorrência e resiliência.
Foram adicionados validadores de contratos de testes e um gate único que preserva OpenAPI, rotas, tabelas e pytest.
```

### 9.119 — `docs/integration/CICLO_14_DESEMPENHO_OBSERVABILIDADE.md`

```text
# Ciclo 14 — Desempenho e observabilidade

Sprints 196 a 200: orçamento estático de routers/services, limites operacionais, cache/filas e observabilidade com Prometheus e Grafana.
A medição real de latência deve ser executada em homologação com carga representativa.
```

### 9.120 — `docs/integration/CICLO_15_INFRAESTRUTURA.md`

```text
# Ciclo 15 — Infraestrutura

Sprints 201 a 205: Docker local, homologação, PostgreSQL, Redis/workers e object storage compatível com S3.
Credenciais dos arquivos de exemplo devem ser substituídas antes de qualquer uso compartilhado.
```

### 9.121 — `docs/integration/CICLO_1_MATRIZ_TELAS_ENDPOINTS.md`

```text
# Ciclo 1 — Inventário oficial de integração

- Telas Flutter identificadas: **235**
- Endpoints backend identificados estaticamente: **460**

## Contratos consolidados nesta entrega

- Autenticação: `/api/v1/auth/login`, `/api/v1/auth/me`, `/api/v1/auth/refresh`, `/api/v1/auth/logout`.
- Empresa ativa: `/api/v1/auth/switch-company`.
- Fazendas autorizadas: `GET /api/v1/farms`.
- Contexto enviado pelo Flutter: `Authorization`, `X-Request-ID`, `X-Atlas-Company-Id`, `X-Atlas-Tenant-Id`, `X-Atlas-Farm-Id`.

## Telas (amostra completa por arquivo)

- `AnimalDetailScreen` — `lib/features/animal/presentation/screens/animal_detail_screen.dart`
- `AnimalDocumentFormScreen` — `lib/features/animal_document/presentation/screens/animal_document_form_screen.dart`
- `AnimalDocumentListScreen` — `lib/features/animal_document/presentation/screens/animal_document_list_screen.dart`
- `AnimalEventFormScreen` — `lib/features/animal_event/presentation/screens/animal_event_form_screen.dart`
- `AnimalExecutivePanelScreen` — `lib/features/animal_executive_panel/presentation/screens/animal_executive_panel_screen.dart`
- `AnimalFormScreen` — `lib/features/animal/presentation/screens/animal_form_screen.dart`
- `AnimalGenealogyScreen` — `lib/features/animal_genealogy/presentation/screens/animal_genealogy_screen.dart`
- `AnimalHealthEnterpriseScreen` — `lib/features/animal_health_enterprise/presentation/screens/animal_health_enterprise_screen.dart`
- `AnimalHealthFormScreen` — `lib/features/animal_health/presentation/screens/animal_health_form_screen.dart`
- `AnimalHealthListScreen` — `lib/features/animal_health/presentation/screens/animal_health_list_screen.dart`
- `AnimalIntelligence360Screen` — `lib/features/animal_intelligence_360/presentation/screens/animal_intelligence_360_screen.dart`
- `AnimalListScreen` — `lib/features/animal/presentation/screens/animal_list_screen.dart`
- `AnimalMovementFormScreen` — `lib/features/animal_movement/presentation/screens/animal_movement_form_screen.dart`
- `AnimalMovementListScreen` — `lib/features/animal_movement/presentation/screens/animal_movement_list_screen.dart`
- `AnimalNutritionEnterpriseScreen` — `lib/features/animal_nutrition_enterprise/presentation/screens/animal_nutrition_enterprise_screen.dart`
- `AnimalOperationsCenterScreen` — `lib/features/animal_operations_center/presentation/screens/animal_operations_center_screen.dart`
- `AnimalPhotoComparisonScreen` — `lib/features/animal_photo/presentation/screens/animal_photo_gallery_screen.dart`
- `AnimalPhotoFormScreen` — `lib/features/animal_photo/presentation/screens/animal_photo_form_screen.dart`
- `AnimalPhotoGalleryScreen` — `lib/features/animal_photo/presentation/screens/animal_photo_gallery_screen.dart`
- `AnimalReproductionEnterpriseScreen` — `lib/features/animal_reproduction_enterprise/presentation/screens/animal_reproduction_enterprise_screen.dart`
- `AnimalReproductionFormScreen` — `lib/features/animal_reproduction/presentation/screens/animal_reproduction_form_screen.dart`
- `AnimalReproductionListScreen` — `lib/features/animal_reproduction/presentation/screens/animal_reproduction_list_screen.dart`
- `AnimalTimelineScreen` — `lib/features/animal_event/presentation/screens/animal_timeline_screen.dart`
- `AnimalWeightFormScreen` — `lib/features/animal_weight/presentation/screens/animal_weight_form_screen.dart`
- `AnimalWeightIntelligenceScreen` — `lib/features/animal_weight_intelligence/presentation/screens/animal_weight_intelligence_screen.dart`
- `AnimalWeightListScreen` — `lib/features/animal_weight/presentation/screens/animal_weight_list_screen.dart`
- `AnimalZootechnicalDashboardScreen` — `lib/features/animal_zootechnical/presentation/screens/animal_zootechnical_dashboard_screen.dart`
- `AtlasActionAttentionScreen` — `lib/core/operational_intelligence/action_plan/atlas_action_attention_screen.dart`
- `AtlasActionPlanScreen` — `lib/features/action_plan/presentation/screens/atlas_action_plan_screen.dart`
- `AtlasAdvancedAiScreen` — `lib/features/atlas_advanced_ai/presentation/screens/atlas_advanced_ai_screen.dart`
- `AtlasAdvancedDashboardScreen` — `lib/features/atlas_advanced/presentation/screens/atlas_advanced_dashboard_screen.dart`
- `AtlasAgricultureScreen` — `lib/core/operational_intelligence/action_plan/atlas_agriculture_screen.dart`
- `AtlasAiConversationScreen` — `lib/features/atlas_ai_2/presentation/screens/atlas_ai_conversation_screen.dart`
- `AtlasAiEnterpriseScreen` — `lib/features/atlas_ai_enterprise/presentation/screens/atlas_ai_enterprise_screen.dart`
- `AtlasAiOperationActionsScreen` — `lib/features/atlas_ai/presentation/screens/atlas_ai_operation_actions_screen.dart`
- `AtlasAiScreen` — `lib/features/atlas_ai/presentation/screens/atlas_ai_screen.dart`
- `AtlasAssetMaintenanceScreen` — `lib/core/operational_intelligence/action_plan/atlas_asset_maintenance_screen.dart`
- `AtlasAuthSyncScreen` — `lib/features/atlas_auth_sync_enterprise/presentation/screens/atlas_auth_sync_screen.dart`
- `AtlasAutomationOperationsScreen` — `lib/features/atlas_automation_operations/presentation/screens/atlas_automation_operations_screen.dart`
- `AtlasAutomationStrategyScreen` — `lib/features/automation_strategy/presentation/screens/atlas_automation_strategy_screen.dart`
- `AtlasAutonomousConsultantScreen` — `lib/features/autonomous_consultant/presentation/screens/atlas_autonomous_consultant_screen.dart`
- `AtlasAutonomousEnterpriseScreen` — `lib/features/atlas_autonomous_enterprise/presentation/screens/atlas_autonomous_enterprise_screen.dart`
- `AtlasBackendFoundationScreen` — `lib/features/atlas_backend_foundation/presentation/screens/atlas_backend_foundation_screen.dart`
- `AtlasBenefitsRealizationScreen` — `lib/features/benefits_realization/presentation/screens/atlas_benefits_realization_screen.dart`
- `AtlasBiAnalyticsScreen` — `lib/features/atlas_bi_analytics/presentation/screens/atlas_bi_analytics_screen.dart`
- `AtlasBiBenchmarkScreen` — `lib/features/atlas_bi/presentation/screens/atlas_bi_benchmark_screen.dart`
- `AtlasBiDashboardScreen` — `lib/features/analytics/presentation/screens/atlas_bi_dashboard_screen.dart`
- `AtlasBiForecastScreen` — `lib/features/atlas_bi/presentation/screens/atlas_bi_forecast_screen.dart`
- `AtlasBiHubScreen` — `lib/features/atlas_bi/presentation/screens/atlas_bi_hub_screen.dart`
- `AtlasBiManagementDashboardScreen` — `lib/features/atlas_bi/presentation/screens/atlas_bi_management_dashboard_screen.dart`
- `AtlasBiScreen` — `lib/features/atlas_bi/presentation/screens/atlas_bi_screen.dart`
- `AtlasBusinessDashboardScreen` — `lib/features/atlas_business/presentation/screens/atlas_business_dashboard_screen.dart`
- `AtlasClimateEnterpriseScreen` — `lib/features/atlas_climate_enterprise/presentation/screens/atlas_climate_enterprise_screen.dart`
- `AtlasClimateScreen` — `lib/core/operational_intelligence/action_plan/atlas_climate_screen.dart`
- `AtlasCloudSecurityScreen` — `lib/features/atlas_cloud_security_enterprise/presentation/screens/atlas_cloud_security_screen.dart`
- `AtlasCommandCenterActionPlanScreen` — `lib/core/operational_intelligence/action_plan/atlas_command_center_action_plan_screen.dart`
- `AtlasCommandCenterDetailsScreen` — `lib/core/operational_intelligence/presentation/screens/atlas_command_center_details_screen.dart`
- `AtlasCommandCenterScreen` — `lib/features/command_center/presentation/screens/atlas_command_center_screen.dart`
- `AtlasCommercialDashboardScreen` — `lib/features/commercial_platform/presentation/screens/atlas_commercial_dashboard_screen.dart`
- `AtlasCommercialEnterpriseScreen` — `lib/features/atlas_commercial_enterprise/presentation/screens/atlas_commercial_enterprise_screen.dart`
- `AtlasCommercialOperationsScreen` — `lib/features/atlas_commercial_operations/presentation/screens/atlas_commercial_operations_screen.dart`
- `AtlasCommercialScreen` — `lib/core/operational_intelligence/action_plan/atlas_commercial_screen.dart`
- `AtlasComparativeDiagnosticScreen` — `lib/features/diagnostics/presentation/screens/atlas_comparative_diagnostic_screen.dart`
- `AtlasConsultancyWorkflowScreen` — `lib/features/consultancy_workflow/presentation/screens/atlas_consultancy_workflow_screen.dart`
- `AtlasContinuousImprovementScreen` — `lib/features/continuous_improvement/presentation/screens/atlas_continuous_improvement_screen.dart`
- `AtlasCopilotConversationViewerScreen` — `lib/features/copilot/presentation/screens/atlas_copilot_conversation_viewer_screen.dart`
- `AtlasCopilotFeedbackAnalyticsScreen` — `lib/features/copilot/presentation/screens/atlas_copilot_feedback_analytics_screen.dart`
- `AtlasCopilotHistoryScreen` — `lib/features/copilot/presentation/screens/atlas_copilot_history_screen.dart`
- `AtlasCopilotImprovementScreen` — `lib/features/copilot/presentation/screens/atlas_copilot_improvement_screen.dart`
- `AtlasCopilotScreen` — `lib/features/atlas_copilot/presentation/screens/atlas_copilot_screen.dart`
- `AtlasCopilotScreen` — `lib/features/copilot/presentation/screens/atlas_copilot_screen.dart`
- `AtlasDataGovernanceScreen` — `lib/features/data_governance/presentation/screens/atlas_data_governance_screen.dart`
- `AtlasDecisionEngineScreen` — `lib/features/decision_engine/presentation/screens/atlas_decision_engine_screen.dart`
- `AtlasDecisionEngineV2Screen` — `lib/features/decision_engine_v2/presentation/screens/atlas_decision_engine_v2_screen.dart`
- `AtlasDecisionIntelligenceLabScreen` — `lib/features/decision_intelligence_lab/presentation/screens/atlas_decision_intelligence_lab_screen.dart`
- `AtlasDecisionTrackingScreen` — `lib/features/decision_tracking/presentation/screens/atlas_decision_tracking_screen.dart`
- `AtlasDiagnosticScreen` — `lib/features/diagnostics/presentation/screens/atlas_diagnostic_screen.dart`
- `AtlasDigitalTwinScreen` — `lib/features/digital_twin/presentation/screens/atlas_digital_twin_screen.dart`
- `AtlasEconomicIntelligenceScreen` — `lib/core/operational_intelligence/action_plan/atlas_economic_intelligence_screen.dart`
- `AtlasEconomicScenarioScreen` — `lib/core/operational_intelligence/action_plan/atlas_economic_scenario_screen.dart`
- `AtlasEcosystemScreen` — `lib/features/atlas_sustainability_ecosystem/presentation/screens/atlas_ecosystem_screen.dart`
- `AtlasEnterprise24AScreen` — `lib/features/enterprise_platform/presentation/screens/atlas_enterprise_24a_screen.dart`
- `AtlasEnterprise24BScreen` — `lib/features/enterprise_platform/presentation/screens/atlas_enterprise_24b_screen.dart`
- `AtlasEnterprise24CScreen` — `lib/features/enterprise_platform/presentation/screens/atlas_enterprise_24c_screen.dart`
- `AtlasEnterprise24DScreen` — `lib/features/enterprise_platform/presentation/screens/atlas_enterprise_24d_screen.dart`
- `AtlasEnterprise50Screen` — `lib/features/atlas_enterprise_50/presentation/screens/atlas_enterprise_50_screen.dart`
- `AtlasEnterpriseOperationsScreen` — `lib/features/atlas_enterprise_operations/presentation/screens/atlas_enterprise_operations_screen.dart`
- `AtlasEnterprisePlatformScreen` — `lib/features/enterprise_platform/presentation/screens/atlas_enterprise_platform_screen.dart`
- `AtlasEnvironmentalAiScreen` — `lib/features/atlas_environmental_ai/presentation/screens/atlas_environmental_ai_screen.dart`
- `AtlasEsgScreen` — `lib/core/operational_intelligence/action_plan/atlas_esg_screen.dart`
- `AtlasEventAnalyticsScreen` — `lib/core/event_center/atlas_event_analytics_screen.dart`
- `AtlasEventCenterScreen` — `lib/core/event_center/atlas_event_center_screen.dart`
- `AtlasEventDetailScreen` — `lib/core/event_center/atlas_event_detail_screen.dart`
- `AtlasExecutionAuditScreen` — `lib/core/operational_intelligence/action_plan/atlas_execution_audit_screen.dart`
- `AtlasExecutionEngineScreen` — `lib/features/strategic_execution_engine/presentation/screens/atlas_execution_engine_screen.dart`
- `AtlasExecutionMeetingScreen` — `lib/core/operational_intelligence/action_plan/atlas_execution_meeting_screen.dart`
- `AtlasExecutionWeeklyReviewScreen` — `lib/core/operational_intelligence/action_plan/atlas_execution_weekly_review_screen.dart`
- `AtlasExecutive360Screen` — `lib/core/operational_intelligence/action_plan/atlas_executive_360_screen.dart`
- `AtlasExecutiveAiAdvisorScreen` — `lib/features/executive_ai_advisor/presentation/screens/atlas_executive_ai_advisor_screen.dart`
- `AtlasExecutiveAiScreen` — `lib/features/atlas_ai_2/presentation/screens/atlas_executive_ai_screen.dart`
- `AtlasExecutiveAlertsScreen` — `lib/features/executive_alerts/presentation/screens/atlas_executive_alerts_screen.dart`
- `AtlasExecutiveBrainHistoricalIntelligenceScreen` — `lib/features/executive_brain/presentation/screens/atlas_executive_brain_historical_intelligence_screen.dart`
- `AtlasExecutiveBrainHistoryScreen` — `lib/features/executive_brain/presentation/screens/atlas_executive_brain_history_screen.dart`
- `AtlasExecutiveBrainScreen` — `lib/features/executive_brain/presentation/screens/atlas_executive_brain_screen.dart`
- `AtlasExecutiveCoreScreen` — `lib/features/executive_core/presentation/screens/atlas_executive_core_screen.dart`
- `AtlasExecutiveGoalHistoryScreen` — `lib/features/executive_goals/presentation/screens/atlas_executive_goal_history_screen.dart`
- `AtlasExecutiveGoalsScreen` — `lib/features/executive_goals/presentation/screens/atlas_executive_goals_screen.dart`
- `AtlasExecutiveIntelligenceScreen` — `lib/core/operational_intelligence/action_plan/atlas_executive_intelligence_screen.dart`
- `AtlasExecutiveIntelligenceScreen` — `lib/features/atlas_executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart`
- `AtlasExecutiveIntelligenceScreen` — `lib/features/executive_intelligence/presentation/screens/atlas_executive_intelligence_screen.dart`
- `AtlasExecutiveKpiHistoryScreen` — `lib/features/executive_kpis/presentation/screens/atlas_executive_kpi_history_screen.dart`
- `AtlasExecutiveKpisScreen` — `lib/features/executive_kpis/presentation/screens/atlas_executive_kpis_screen.dart`
- `AtlasExecutivePlatformScreen` — `lib/features/atlas_executive_platform/presentation/screens/atlas_executive_platform_screen.dart`
- `AtlasFarmAuditScreen` — `lib/features/farm_audit/presentation/screens/atlas_farm_audit_screen.dart`
- `AtlasFarmIntelligenceScreen` — `lib/features/farm/presentation/screens/atlas_farm_intelligence_screen.dart`
- `AtlasFinanceEnterpriseScreen` — `lib/features/atlas_finance_enterprise/presentation/screens/atlas_finance_enterprise_screen.dart`
- `AtlasFinancialIntegrationsScreen` — `lib/features/atlas_financial_integrations/presentation/screens/atlas_financial_integrations_screen.dart`
- `AtlasFinancialManagementScreen` — `lib/core/operational_intelligence/action_plan/atlas_financial_management_screen.dart`
- `AtlasFoundationCenterScreen` — `lib/core/foundation/atlas_foundation_center_screen.dart`
- `AtlasGeospatialScreen` — `lib/features/atlas_geospatial_platform/presentation/screens/atlas_geospatial_screen.dart`
- `AtlasGlobalPlatformScreen` — `lib/features/atlas_global_platform/presentation/screens/atlas_global_platform_screen.dart`
- `AtlasGovernanceOperationsScreen` — `lib/features/atlas_governance_operations/presentation/screens/atlas_governance_operations_screen.dart`
- `AtlasGovernancePeopleScreen` — `lib/features/atlas_governance_people_enterprise/presentation/screens/atlas_governance_people_screen.dart`
- `AtlasGovernanceResilienceScreen` — `lib/features/governance_resilience/presentation/screens/atlas_governance_resilience_screen.dart`
- `AtlasHealthIntelligenceScreen` — `lib/core/operational_intelligence/action_plan/atlas_health_intelligence_screen.dart`
- `AtlasHealthStrategyScreen` — `lib/core/operational_intelligence/action_plan/atlas_health_strategy_screen.dart`
- `AtlasIntegrationCenterScreen` — `lib/features/integration_hub/presentation/screens/atlas_integration_center_screen.dart`
- `AtlasIntegrationCoreScreen` — `lib/core/integration/atlas_integration_core_screen.dart`
- `AtlasIntegrationEcosystemScreen` — `lib/features/integration_ecosystem/presentation/screens/atlas_integration_ecosystem_screen.dart`
- `AtlasIntelligenceReportsScreen` — `lib/features/atlas_intelligence_reports_experience/presentation/screens/atlas_intelligence_reports_screen.dart`
- `AtlasIntelligenceScreen` — `lib/features/atlas_intelligence/presentation/screens/atlas_intelligence_screen.dart`
- `AtlasIntelligenceScreen` — `lib/features/dashboard/presentation/screens/atlas_intelligence_screen.dart`
- `AtlasInventoryManagementScreen` — `lib/core/operational_intelligence/action_plan/atlas_inventory_management_screen.dart`
- `AtlasInvestmentCapitalScreen` — `lib/features/investment_capital_allocation/presentation/screens/atlas_investment_capital_screen.dart`
- `AtlasIotEnterpriseScreen` — `lib/features/iot_enterprise/presentation/screens/atlas_iot_enterprise_screen.dart`
- `AtlasIotScreen` — `lib/features/atlas_iot_platform/presentation/screens/atlas_iot_screen.dart`
- `AtlasKnowledgeLearningScreen` — `lib/features/knowledge_learning/presentation/screens/atlas_knowledge_learning_screen.dart`
- `AtlasLandIntelligenceScreen` — `lib/features/atlas_land_intelligence/presentation/screens/atlas_land_intelligence_screen.dart`
- `AtlasLivestockIntegrationScreen` — `lib/features/atlas_livestock_integration/presentation/screens/atlas_livestock_integration_screen.dart`
- `AtlasMeetingDecisionMonitoringScreen` — `lib/core/operational_intelligence/action_plan/atlas_meeting_decision_monitoring_screen.dart`
- `AtlasMissionControlScreen` — `lib/features/mission_control/presentation/screens/atlas_mission_control_screen.dart`
- `AtlasMlPlatformScreen` — `lib/features/ml_platform/presentation/screens/atlas_ml_platform_screen.dart`
- `AtlasNutritionIntelligenceScreen` — `lib/core/operational_intelligence/action_plan/atlas_nutrition_intelligence_screen.dart`
- `AtlasNutritionStrategyScreen` — `lib/core/operational_intelligence/action_plan/atlas_nutrition_strategy_screen.dart`
- `AtlasOfficialIntegrationsScreen` — `lib/features/atlas_official_integrations/presentation/screens/atlas_official_integrations_screen.dart`
- `AtlasOfflineFieldScreen` — `lib/features/offline_field/presentation/screens/atlas_offline_field_screen.dart`
- `AtlasOperationalMemoryScreen` — `lib/core/operational_memory/atlas_operational_memory_screen.dart`
- `AtlasOperationsCenterScreen` — `lib/features/farm_operations/presentation/screens/atlas_operations_center_screen.dart`
- `AtlasOperationsEnterpriseScreen` — `lib/features/atlas_operations_enterprise/presentation/screens/atlas_operations_enterprise_screen.dart`
- `AtlasOperationsIntelligenceScreen` — `lib/features/dashboard/presentation/screens/atlas_operations_intelligence_screen.dart`
- `AtlasOptimizationResultScreen` — `lib/features/optimization_engine/presentation/screens/atlas_optimization_result_screen.dart`
- `AtlasOptimizationScreen` — `lib/features/optimization_engine/presentation/screens/atlas_optimization_screen.dart`
- `AtlasOsScreen` — `lib/features/atlas_os/presentation/screens/atlas_os_screen.dart`
- `AtlasPastureManagementScreen` — `lib/core/operational_intelligence/action_plan/atlas_pasture_management_screen.dart`
- `AtlasPastureStrategyScreen` — `lib/core/operational_intelligence/action_plan/atlas_pasture_strategy_screen.dart`
- `AtlasPeopleManagementScreen` — `lib/core/operational_intelligence/action_plan/atlas_people_management_screen.dart`
- `AtlasPerformanceCenterScreen` — `lib/features/performance_center/presentation/screens/atlas_performance_center_screen.dart`
- `AtlasPerformanceDashboardScreen` — `lib/features/performance_intelligence/presentation/screens/atlas_performance_dashboard_screen.dart`
- `AtlasPlatformDashboardScreen` — `lib/features/platform_v1/presentation/screens/atlas_platform_dashboard_screen.dart`
- `AtlasPlatformResilienceScreen` — `lib/features/atlas_platform_resilience/presentation/screens/atlas_platform_resilience_screen.dart`
- `AtlasPortfolioManagementScreen` — `lib/features/portfolio_management/presentation/screens/atlas_portfolio_management_screen.dart`
- `AtlasPrecisionLivestockScreen` — `lib/features/atlas_precision_livestock/presentation/screens/atlas_precision_livestock_screen.dart`
- `AtlasPredictiveAiScreen` — `lib/features/atlas_predictive_ai_suite/presentation/screens/atlas_predictive_ai_screen.dart`
- `AtlasPredictiveAiScreen` — `lib/features/predictive_ai/presentation/screens/atlas_predictive_ai_screen.dart`
- `AtlasPredictiveAnalyticsScreen` — `lib/features/predictive_analytics/presentation/screens/atlas_predictive_analytics_screen.dart`
- `AtlasPredictiveScreen` — `lib/features/predictive/presentation/screens/atlas_predictive_screen.dart`
- `AtlasQualityCenterScreen` — `lib/features/quality_center/presentation/screens/atlas_quality_center_screen.dart`
- `AtlasQualityReleaseScreen` — `lib/features/atlas_quality_release/presentation/screens/atlas_quality_release_screen.dart`
- `AtlasRealtimeCenterScreen` — `lib/features/realtime/presentation/screens/atlas_realtime_center_screen.dart`
- `AtlasRecommendationIntelligenceScreen` — `lib/features/recommendation_intelligence/presentation/screens/atlas_recommendation_intelligence_screen.dart`
- `AtlasReleaseCandidateScreen` — `lib/core/release_candidate/atlas_release_candidate_screen.dart`
- `AtlasReleaseEngineeringScreen` — `lib/features/release_engineering/presentation/screens/atlas_release_engineering_screen.dart`
- `AtlasReproductiveAiScreen` — `lib/features/atlas_reproductive_ai/presentation/screens/atlas_reproductive_ai_screen.dart`
- `AtlasReproductiveIntelligenceScreen` — `lib/core/operational_intelligence/action_plan/atlas_reproductive_intelligence_screen.dart`
- `AtlasReproductivePremiumScreen` — `lib/features/atlas_reproductive_premium/presentation/screens/atlas_reproductive_premium_screen.dart`
- `AtlasReproductiveStrategyScreen` — `lib/core/operational_intelligence/action_plan/atlas_reproductive_strategy_screen.dart`
- `AtlasResultsIntelligenceScreen` — `lib/core/operational_intelligence/action_plan/atlas_results_intelligence_screen.dart`
- `AtlasRuralBusinessScreen` — `lib/features/atlas_rural_business/presentation/screens/atlas_rural_business_screen.dart`
- `AtlasSaasPlatformScreen` — `lib/features/atlas_saas_platform/presentation/screens/atlas_saas_platform_screen.dart`
- `AtlasScenarioResultScreen` — `lib/features/scenario_simulator/presentation/screens/atlas_scenario_result_screen.dart`
- `AtlasScenarioSimulatorScreen` — `lib/features/scenario_simulator/presentation/screens/atlas_scenario_simulator_screen.dart`
- `AtlasSecurityPrivacyContinuityScreen` — `lib/features/security_privacy_continuity/presentation/screens/atlas_security_privacy_continuity_screen.dart`
- `AtlasSprints1620DashboardScreen` — `lib/features/atlas_sprints_16_20/presentation/screens/atlas_sprints_16_20_dashboard_screen.dart`
- `AtlasSprints2125DashboardScreen` — `lib/features/atlas_sprints_21_25/presentation/screens/atlas_sprints_21_25_dashboard_screen.dart`
- `AtlasSprintsDashboardScreen` — `lib/features/atlas_sprints_11_15/presentation/screens/atlas_sprints_dashboard_screen.dart`
- `AtlasStrategicAlignmentScreen` — `lib/features/strategic_alignment/presentation/screens/atlas_strategic_alignment_screen.dart`
- `AtlasStrategicCapacityScreen` — `lib/features/strategic_capacity/presentation/screens/atlas_strategic_capacity_screen.dart`
- `AtlasStrategicScenarioPlanningScreen` — `lib/features/strategic_scenario_planning/presentation/screens/atlas_strategic_scenario_planning_screen.dart`
- `AtlasStrategyCenterScreen` — `lib/features/strategy_center/presentation/screens/atlas_strategy_center_screen.dart`
- `AtlasStrategyExecutionScreen` — `lib/features/strategy_execution/presentation/screens/atlas_strategy_execution_screen.dart`
- `AtlasStrategyPerformanceScreen` — `lib/core/operational_intelligence/action_plan/atlas_strategy_performance_screen.dart`
- `AtlasSupplyChainScreen` — `lib/features/atlas_supply_chain/presentation/screens/atlas_supply_chain_screen.dart`
- `AtlasSupplyLogisticsScreen` — `lib/features/atlas_supply_logistics_enterprise/presentation/screens/atlas_supply_logistics_screen.dart`
- `AtlasSustainabilityEnterpriseScreen` — `lib/features/atlas_sustainability_enterprise/presentation/screens/atlas_sustainability_enterprise_screen.dart`
- `AtlasSyncDashboardScreen` — `lib/features/sync_platform/presentation/screens/atlas_sync_dashboard_screen.dart`
- `AtlasSystemCenterScreen` — `lib/core/system_center/atlas_system_center_screen.dart`
- `AtlasTeamManagementScreen` — `lib/core/operational_intelligence/action_plan/atlas_team_management_screen.dart`
- `AtlasUnifiedWorkflowScreen` — `lib/features/unified_workflow/presentation/screens/atlas_unified_workflow_screen.dart`
- `AtlasValueGovernanceScreen` — `lib/features/value_governance/presentation/screens/atlas_value_governance_screen.dart`
- `AtlasVeterinaryAiScreen` — `lib/features/atlas_veterinary_ai/presentation/screens/atlas_veterinary_ai_screen.dart`
- `AtlasWorkflowScreen` — `lib/features/workflow_engine/presentation/screens/atlas_workflow_screen.dart`
- `CompanySelectionScreen` — `lib/features/authentication/presentation/screens/company_selection_screen.dart`
- `DashboardScreen` — `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `DecisionScenarioSimulatorScreen` — `lib/features/dashboard/presentation/screens/decision_scenario_simulator_screen.dart`
- `ExecutiveDashboardScreen` — `lib/features/dashboard/presentation/screens/executive_dashboard_screen.dart`
- `ExecutiveDecisionCenterScreen` — `lib/features/dashboard/presentation/screens/executive_decision_center_screen.dart`
- `FarmAgendaFormScreen` — `lib/features/farm_agenda/presentation/screens/farm_agenda_form_screen.dart`
- `FarmAgendaListScreen` — `lib/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart`
- `FarmDetailScreen` — `lib/features/farm/presentation/screens/farm_detail_screen.dart`
- `FarmFinanceFormScreen` — `lib/features/farm_finance/presentation/screens/farm_finance_form_screen.dart`
- `FarmFinanceListScreen` — `lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart`
- `FarmFormScreen` — `lib/features/farm/presentation/screens/farm_form_screen.dart`
- `FarmInventoryFormScreen` — `lib/features/farm_inventory/presentation/screens/farm_inventory_form_screen.dart`
- `FarmInventoryListScreen` — `lib/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart`
- `FarmListScreen` — `lib/features/farm/presentation/screens/farm_list_screen.dart`
- `FinanceOverviewScreen` — `lib/features/farm_finance/presentation/screens/finance_overview_screen.dart`
- `HealthOverviewScreen` — `lib/features/animal_health/presentation/screens/health_overview_screen.dart`
- `HerdGroupFormScreen` — `lib/features/herd/presentation/screens/herd_group_form_screen.dart`
- `HerdListScreen` — `lib/features/herd/presentation/screens/herd_list_screen.dart`
- `HerdOverviewScreen` — `lib/features/herd/presentation/screens/herd_overview_screen.dart`
- `IndicatorsScreen` — `lib/features/indicators/presentation/screens/indicators_screen.dart`
- `InventoryOverviewScreen` — `lib/features/farm_inventory/presentation/screens/inventory_overview_screen.dart`
- `LoginScreen` — `lib/features/authentication/presentation/screens/login_screen.dart`
- `NutritionOverviewScreen` — `lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart`
- `PaddockFormScreen` — `lib/features/paddock/presentation/screens/paddock_form_screen.dart`
- `PaddockListScreen` — `lib/features/paddock/presentation/screens/paddock_list_screen.dart`
- `PasswordRecoveryScreen` — `lib/features/authentication/presentation/screens/password_recovery_screen.dart`
- `RegisterScreen` — `lib/features/authentication/presentation/screens/register_screen.dart`
- `ReportActionListScreen` — `lib/features/reports/presentation/screens/report_action_list_screen.dart`
- `ReportsScreen` — `lib/features/reports/presentation/screens/reports_screen.dart`
- `ReproductionOverviewScreen` — `lib/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart`
- `TechnicalDashboardScreen` — `lib/features/technical_dashboard/presentation/screens/technical_dashboard_screen.dart`
- `WelcomeScreen` — `lib/features/authentication/presentation/screens/welcome_screen.dart`
- `_FailureScreen` — `lib/core/session/atlas_session_gate.dart`
- `_LoadingScreen` — `lib/core/session/atlas_session_gate.dart`

## Endpoints detectados

- `DELETE /api/v1/animals/{animal_id}` — `backend/app/routers/animals.py`
- `DELETE /api/v1/auth/mfa` — `backend/app/routers/auth.py`
- `DELETE /api/v1/auth/sessions/{session_id}` — `backend/app/routers/auth.py`
- `DELETE /api/v1/farms/{farm_id}` — `backend/app/routers/farms.py`
- `GET /api/v1/advanced/farms/{farm_id}/advanced-dashboard` — `backend/app/routers/advanced.py`
- `GET /api/v1/advanced/farms/{farm_id}/agriculture/dashboard` — `backend/app/routers/advanced.py`
- `GET /api/v1/advanced/farms/{farm_id}/genetics/ranking` — `backend/app/routers/advanced.py`
- `GET /api/v1/advanced/farms/{farm_id}/genetics/{animal_id}/pedigree` — `backend/app/routers/advanced.py`
- `GET /api/v1/advanced/farms/{farm_id}/geo-assets` — `backend/app/routers/advanced.py`
- `GET /api/v1/advanced/farms/{farm_id}/pasture/dashboard` — `backend/app/routers/advanced.py`
- `GET /api/v1/ai/conversations` — `backend/app/routers/ai.py`
- `GET /api/v1/analytics/benchmarks` — `backend/app/routers/analytics.py`
- `GET /api/v1/analytics/dashboard` — `backend/app/routers/analytics.py`
- `GET /api/v1/analytics/facts` — `backend/app/routers/analytics.py`
- `GET /api/v1/analytics/farm-score/{farm_id}` — `backend/app/routers/analytics.py`
- `GET /api/v1/analytics/goals` — `backend/app/routers/analytics.py`
- `GET /api/v1/analytics/kpis` — `backend/app/routers/analytics.py`
- `GET /api/v1/animals` — `backend/app/routers/animals.py`
- `GET /api/v1/animals/{animal_id}` — `backend/app/routers/animals.py`
- `GET /api/v1/atlas-ai/dashboard` — `backend/app/routers/atlas_ai_enterprise.py`
- `GET /api/v1/atlas-ai/memories` — `backend/app/routers/atlas_ai_enterprise.py`
- `GET /api/v1/atlas-ai/plans` — `backend/app/routers/atlas_ai_enterprise.py`
- `GET /api/v1/atlas-ai/recommendations` — `backend/app/routers/atlas_ai_enterprise.py`
- `GET /api/v1/atlas-ai/sessions` — `backend/app/routers/atlas_ai_enterprise.py`
- `GET /api/v1/atlas-ai/sessions/{session_id}/messages` — `backend/app/routers/atlas_ai_enterprise.py`
- `GET /api/v1/atlas-brain/readiness` — `backend/app/routers/atlas_brain.py`
- `GET /api/v1/atlas-vision/readiness` — `backend/app/routers/atlas_vision.py`
- `GET /api/v1/audit` — `backend/app/routers/audit.py`
- `GET /api/v1/auth/me` — `backend/app/routers/auth.py`
- `GET /api/v1/auth/security-events` — `backend/app/routers/auth.py`
- `GET /api/v1/auth/sessions` — `backend/app/routers/auth.py`
- `GET /api/v1/automation/calendar` — `backend/app/routers/automation.py`
- `GET /api/v1/automation/dashboard` — `backend/app/routers/automation.py`
- `GET /api/v1/automation/objectives` — `backend/app/routers/automation.py`
- `GET /api/v1/automation/rules` — `backend/app/routers/automation.py`
- `GET /api/v1/automation/workflows` — `backend/app/routers/automation.py`
- `GET /api/v1/backups` — `backend/app/routers/backups.py`
- `GET /api/v1/billing/readiness` — `backend/app/routers/billing.py`
- `GET /api/v1/business/bi/dashboard` — `backend/app/routers/business.py`
- `GET /api/v1/business/commercial-documents` — `backend/app/routers/business.py`
- `GET /api/v1/business/commercial/dashboard` — `backend/app/routers/business.py`
- `GET /api/v1/business/consulting/dashboard` — `backend/app/routers/business.py`
- `GET /api/v1/business/consulting/visits` — `backend/app/routers/business.py`
- `GET /api/v1/business/dashboard` — `backend/app/routers/business.py`
- `GET /api/v1/business/enterprise/readiness` — `backend/app/routers/business.py`
- `GET /api/v1/business/parties` — `backend/app/routers/business.py`
- `GET /api/v1/business/product/readiness` — `backend/app/routers/business.py`
- `GET /api/v1/cloud-operations/readiness` — `backend/app/routers/cloud_operations.py`
- `GET /api/v1/commercial/customers` — `backend/app/routers/commercial.py`
- `GET /api/v1/commercial/dashboard` — `backend/app/routers/commercial.py`
- `GET /api/v1/commercial/invoices` — `backend/app/routers/commercial.py`
- `GET /api/v1/commercial/opportunities` — `backend/app/routers/commercial.py`
- `GET /api/v1/commercial/plans` — `backend/app/routers/commercial.py`
- `GET /api/v1/commercial/proposals` — `backend/app/routers/commercial.py`
- `GET /api/v1/commercial/subscriptions` — `backend/app/routers/commercial.py`
- `GET /api/v1/companies` — `backend/app/routers/companies.py`
- `GET /api/v1/companies/{company_id}` — `backend/app/routers/companies.py`
- `GET /api/v1/core-validation/farms/{farm_id}` — `backend/app/routers/core_livestock_validation.py`
- `GET /api/v1/corporate-intelligence/executive-board` — `backend/app/routers/corporate_intelligence.py`
- `GET /api/v1/data-platform/cache/{key}` — `backend/app/routers/data_platform.py`
- `GET /api/v1/data-platform/dashboard` — `backend/app/routers/data_platform.py`
- `GET /api/v1/data-platform/realtime/metrics` — `backend/app/routers/data_platform.py`
- `GET /api/v1/ecosystem/dashboard` — `backend/app/routers/ecosystem.py`
- `GET /api/v1/ecosystem/partners` — `backend/app/routers/ecosystem.py`
- `GET /api/v1/enterprise-analytics/readiness` — `backend/app/routers/enterprise_analytics.py`
- `GET /api/v1/enterprise-operations/dashboard` — `backend/app/routers/enterprise_operations.py`
- `GET /api/v1/enterprise-release/readiness` — `backend/app/routers/enterprise_release.py`
- `GET /api/v1/farm-operations/farms/{farm_id}/dashboard` — `backend/app/routers/farm_operations.py`
- `GET /api/v1/farms` — `backend/app/routers/farms.py`
- `GET /api/v1/farms/{farm_id}` — `backend/app/routers/farms.py`
- `GET /api/v1/finance-enterprise/farms/{farm_id}/dashboard` — `backend/app/routers/finance_enterprise.py`
- `GET /api/v1/global-platform/readiness` — `backend/app/routers/global_platform.py`
- `GET /api/v1/governance/catalog/assets` — `backend/app/routers/governance.py`
- `GET /api/v1/governance/compliance/controls` — `backend/app/routers/governance.py`
- `GET /api/v1/governance/compliance/score` — `backend/app/routers/governance.py`
- `GET /api/v1/governance/dashboard` — `backend/app/routers/governance.py`
- `GET /api/v1/governance/health/summary` — `backend/app/routers/governance.py`
- `GET /api/v1/governance/incidents` — `backend/app/routers/governance.py`
- `GET /api/v1/governance/policies` — `backend/app/routers/governance.py`
- `GET /api/v1/governance/quality/runs` — `backend/app/routers/governance.py`
- `GET /api/v1/health` — `backend/app/routers/health.py`
- `GET /api/v1/health-intelligence/farms/{farm_id}/dashboard` — `backend/app/routers/health_intelligence.py`
- `GET /api/v1/health/live` — `backend/app/routers/health.py`
- `GET /api/v1/health/ready` — `backend/app/routers/health.py`
- `GET /api/v1/integrations/connections` — `backend/app/routers/integrations.py`
- `GET /api/v1/integrations/dashboard` — `backend/app/routers/integrations.py`
- `GET /api/v1/integrations/partners/applications` — `backend/app/routers/integrations.py`
- `GET /api/v1/integrations/providers` — `backend/app/routers/integrations.py`
- `GET /api/v1/integrations/sync-jobs` — `backend/app/routers/integrations.py`
- `GET /api/v1/integrations/usage/summary` — `backend/app/routers/integrations.py`
- `GET /api/v1/integrations/webhooks` — `backend/app/routers/integrations.py`
- `GET /api/v1/integrations/webhooks/deliveries` — `backend/app/routers/integrations.py`
- `GET /api/v1/inventory-enterprise/farms/{farm_id}/dashboard` — `backend/app/routers/inventory_enterprise.py`
- `GET /api/v1/iot-platform/readiness` — `backend/app/routers/iot_platform.py`
- `GET /api/v1/iot/dashboard` — `backend/app/routers/iot.py`
- `GET /api/v1/iot/devices` — `backend/app/routers/iot.py`
- `GET /api/v1/iot/devices/{device_id}/commands` — `backend/app/routers/iot.py`
- `GET /api/v1/iot/gateways` — `backend/app/routers/iot.py`
- `GET /api/v1/iot/telemetry` — `backend/app/routers/iot.py`
- `GET /api/v1/livestock/animals` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/animals/{animal_id}` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/animals/{animal_id}/movements` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/animals/{animal_id}/reproduction` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/animals/{animal_id}/weights` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/dashboard` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/finance` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/finance/cash-flow` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/finance/summary` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/finance/v2` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/health` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/health/alerts` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/health/protocols` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/inventory/alerts` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/inventory/products` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/inventory/products/{product_id}/movements` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/lots` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/nutrition` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/nutrition/ingredients` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/nutrition/performance` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/nutrition/plans` — `backend/app/routers/livestock.py`
- `GET /api/v1/livestock/reproduction/summary` — `backend/app/routers/livestock.py`
- `GET /api/v1/machine-learning-registry/readiness` — `backend/app/routers/machine_learning_registry.py`
- `GET /api/v1/members` — `backend/app/routers/members.py`
- `GET /api/v1/members/catalog` — `backend/app/routers/members.py`
- `GET /api/v1/ml/dashboard` — `backend/app/routers/ml.py`
- `GET /api/v1/ml/datasets` — `backend/app/routers/ml.py`
- `GET /api/v1/ml/deployments` — `backend/app/routers/ml.py`
- `GET /api/v1/ml/deployments/{deployment_id}/drift` — `backend/app/routers/ml.py`
- `GET /api/v1/ml/features` — `backend/app/routers/ml.py`
- `GET /api/v1/ml/models` — `backend/app/routers/ml.py`
- `GET /api/v1/ml/predictions` — `backend/app/routers/ml.py`
- `GET /api/v1/ml/training-runs` — `backend/app/routers/ml.py`
- `GET /api/v1/nutrition-intelligence/farms/{farm_id}/dashboard` — `backend/app/routers/nutrition_intelligence.py`
- `GET /api/v1/offline/conflicts` — `backend/app/routers/offline_sync.py`
- `GET /api/v1/offline/pull-page` — `backend/app/routers/offline_sync.py`
- `GET /api/v1/offline/status` — `backend/app/routers/offline_sync.py`
- `GET /api/v1/operations/alerts` — `backend/app/routers/operations.py`
- `GET /api/v1/operations/exports/{dataset}.csv` — `backend/app/routers/operations.py`
- `GET /api/v1/operations/indicators` — `backend/app/routers/operations.py`
- `GET /api/v1/operations/reports/executive` — `backend/app/routers/operations.py`
- `GET /api/v1/operations/tasks` — `backend/app/routers/operations.py`
- `GET /api/v1/operations/timeline` — `backend/app/routers/operations.py`
- `GET /api/v1/platform/ai/context/farms/{farm_id}` — `backend/app/routers/platform.py`
- `GET /api/v1/platform/ai/recommendations/farms/{farm_id}` — `backend/app/routers/platform.py`
- `GET /api/v1/platform/dashboard/company` — `backend/app/routers/platform.py`
- `GET /api/v1/platform/dashboard/farms/{farm_id}` — `backend/app/routers/platform.py`
- `GET /api/v1/platform/production/readiness` — `backend/app/routers/platform.py`
- `GET /api/v1/platform/security/permission-matrix` — `backend/app/routers/platform.py`
- `GET /api/v1/platform/security/readiness/farms/{farm_id}` — `backend/app/routers/platform.py`
- `GET /api/v1/precision-hub/farms/{farm_id}/dashboard` — `backend/app/routers/precision_hub.py`
- `GET /api/v1/precision-livestock/farms/{farm_id}/dashboard` — `backend/app/routers/precision_livestock.py`
- `GET /api/v1/public-api/readiness` — `backend/app/routers/public_api.py`
- `GET /api/v1/quality/diagnostics` — `backend/app/routers/quality.py`
- `GET /api/v1/quality/ready` — `backend/app/routers/quality.py`
- `GET /api/v1/quality/version` — `backend/app/routers/quality.py`
- `GET /api/v1/realtime/events` — `backend/app/routers/realtime.py`
- `GET /api/v1/realtime/metrics` — `backend/app/routers/realtime.py`
- `GET /api/v1/realtime/notifications` — `backend/app/routers/realtime.py`
- `GET /api/v1/release-engineering/builds` — `backend/app/routers/release_engineering.py`
- `GET /api/v1/release-engineering/change-approvals` — `backend/app/routers/release_engineering.py`
- `GET /api/v1/release-engineering/dashboard` — `backend/app/routers/release_engineering.py`
- `GET /api/v1/release-engineering/deployments` — `backend/app/routers/release_engineering.py`
- `GET /api/v1/release-engineering/environments` — `backend/app/routers/release_engineering.py`
- `GET /api/v1/release-engineering/feature-flags` — `backend/app/routers/release_engineering.py`
- `GET /api/v1/release-engineering/pipelines` — `backend/app/routers/release_engineering.py`
- `GET /api/v1/release-engineering/readiness` — `backend/app/routers/release_engineering.py`
- `GET /api/v1/release-growth/dashboard` — `backend/app/routers/release_growth.py`
- `GET /api/v1/reproduction-advanced/farms/{farm_id}/dashboard` — `backend/app/routers/reproduction_advanced.py`
- `GET /api/v1/reproduction-advanced/farms/{farm_id}/protocols` — `backend/app/routers/reproduction_advanced.py`
- `GET /api/v1/saas-growth/admin/dashboard` — `backend/app/routers/saas_growth.py`
- `GET /api/v1/saas-growth/client-portal` — `backend/app/routers/saas_growth.py`
- `GET /api/v1/saas-growth/feature-flags/effective` — `backend/app/routers/saas_growth.py`
- `GET /api/v1/security-compliance/audit/verify` — `backend/app/routers/security_compliance.py`
- `GET /api/v1/security-compliance/dashboard` — `backend/app/routers/security_compliance.py`
- `GET /api/v1/security-enterprise/access-reviews` — `backend/app/routers/security_enterprise.py`
- `GET /api/v1/security-enterprise/continuity/plans` — `backend/app/routers/security_enterprise.py`
- `GET /api/v1/security-enterprise/dashboard` — `backend/app/routers/security_enterprise.py`
- `GET /api/v1/security-enterprise/policies` — `backend/app/routers/security_enterprise.py`
- `GET /api/v1/security-enterprise/privacy/consents` — `backend/app/routers/security_enterprise.py`
- `GET /api/v1/security-enterprise/privacy/requests` — `backend/app/routers/security_enterprise.py`
- `GET /api/v1/security-enterprise/risks` — `backend/app/routers/security_enterprise.py`
- `GET /api/v1/sprints-16-20/analytics/kpis` — `backend/app/routers/enterprise_product.py`
- `GET /api/v1/sprints-16-20/dashboard` — `backend/app/routers/enterprise_product.py`
- `GET /api/v1/sprints-16-20/enterprise/readiness` — `backend/app/routers/enterprise_product.py`
- `GET /api/v1/sprints-16-20/public-api/openapi-contract` — `backend/app/routers/enterprise_product.py`
- `GET /api/v1/sprints/brain/farms/{farm_id}/context` — `backend/app/routers/innovation_platform.py`
- `GET /api/v1/sprints/cloud/readiness` — `backend/app/routers/innovation_platform.py`
- `GET /api/v1/sprints/dashboard` — `backend/app/routers/innovation_platform.py`
- `GET /api/v1/sprints/iot/farms/{farm_id}/dashboard` — `backend/app/routers/innovation_platform.py`
- `GET /api/v1/sprints/vision/farms/{farm_id}/analyses` — `backend/app/routers/innovation_platform.py`
- `GET /api/v1/sprints/web/dashboard` — `backend/app/routers/innovation_platform.py`
- `GET /api/v1/sync/pull` — `backend/app/routers/sync.py`
- `GET /api/v1/system/metrics` — `backend/app/routers/system.py`
- `GET /api/v1/system/status` — `backend/app/routers/system.py`
- `GET /api/v1/web-platform/readiness` — `backend/app/routers/web_platform.py`
- `PATCH /api/v1/analytics/goals/{goal_id}` — `backend/app/routers/analytics.py`
- `PATCH /api/v1/animals/{animal_id}` — `backend/app/routers/animals.py`
- `PATCH /api/v1/business/consulting/actions/{action_id}/complete` — `backend/app/routers/business.py`
- `PATCH /api/v1/commercial/contracts/{contract_id}/sign` — `backend/app/routers/commercial.py`
- `PATCH /api/v1/commercial/invoices/{invoice_id}/pay` — `backend/app/routers/commercial.py`
- `PATCH /api/v1/commercial/opportunities/{opportunity_id}` — `backend/app/routers/commercial.py`
- `PATCH /api/v1/commercial/proposals/{proposal_id}/status` — `backend/app/routers/commercial.py`
- `PATCH /api/v1/companies/{company_id}` — `backend/app/routers/companies.py`
- `PATCH /api/v1/farm-operations/work-orders/{work_order_id}/complete` — `backend/app/routers/farm_operations.py`
- `PATCH /api/v1/farms/{farm_id}` — `backend/app/routers/farms.py`
- `PATCH /api/v1/integrations/sync-jobs/{job_id}/complete` — `backend/app/routers/integrations.py`
- `PATCH /api/v1/livestock/animals/{animal_id}` — `backend/app/routers/livestock.py`
- `PATCH /api/v1/livestock/finance/{entry_id}/settle` — `backend/app/routers/livestock.py`
- `PATCH /api/v1/livestock/lots/{lot_id}` — `backend/app/routers/livestock.py`
- `PATCH /api/v1/members/{membership_id}` — `backend/app/routers/members.py`
- `PATCH /api/v1/ml/training-runs/{run_id}/complete` — `backend/app/routers/ml.py`
- `PATCH /api/v1/operations/tasks/{task_id}` — `backend/app/routers/operations.py`
- `PATCH /api/v1/realtime/notifications/{notification_id}/read` — `backend/app/routers/realtime.py`
- `PATCH /api/v1/release-engineering/builds/{build_id}/complete` — `backend/app/routers/release_engineering.py`
- `PATCH /api/v1/release-engineering/change-approvals/{approval_id}/decision` — `backend/app/routers/release_engineering.py`
- `PATCH /api/v1/release-engineering/deployments/{deployment_id}/complete` — `backend/app/routers/release_engineering.py`
- `PATCH /api/v1/release-engineering/readiness-checks/{check_id}/complete` — `backend/app/routers/release_engineering.py`
- `PATCH /api/v1/security-enterprise/access-reviews/{review_id}/complete` — `backend/app/routers/security_enterprise.py`
- `PATCH /api/v1/security-enterprise/continuity/exercises/{exercise_id}/complete` — `backend/app/routers/security_enterprise.py`
- `PATCH /api/v1/sprints-16-20/ml/models/{model_id}/approve` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/advanced/farms/{farm_id}/agriculture` — `backend/app/routers/advanced.py`
- `POST /api/v1/advanced/farms/{farm_id}/ai/forecast` — `backend/app/routers/advanced.py`
- `POST /api/v1/advanced/farms/{farm_id}/genetics/mating-simulator` — `backend/app/routers/advanced.py`
- `POST /api/v1/advanced/farms/{farm_id}/geo-assets` — `backend/app/routers/advanced.py`
- `POST /api/v1/advanced/farms/{farm_id}/geo/import` — `backend/app/routers/advanced.py`
- `POST /api/v1/advanced/farms/{farm_id}/pasture` — `backend/app/routers/advanced.py`
- `POST /api/v1/ai-operational/automations/{automation_id}/approve` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai-operational/farms/{farm_id}/automations` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai-operational/farms/{farm_id}/context` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai-operational/farms/{farm_id}/memory` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai-operational/farms/{farm_id}/recommendations` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai-operational/farms/{farm_id}/simulate` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai-operational/governance/models` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai-operational/governance/models/{model_id}/approve` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai-operational/recommendations/{recommendation_id}/decision` — `backend/app/routers/ai_operational.py`
- `POST /api/v1/ai/conversations` — `backend/app/routers/ai.py`
- `POST /api/v1/ai/executive` — `backend/app/routers/ai.py`
- `POST /api/v1/analytics/benchmarks/{metric_key}` — `backend/app/routers/analytics.py`
- `POST /api/v1/analytics/farm-score/{farm_id}` — `backend/app/routers/analytics.py`
- `POST /api/v1/analytics/goals` — `backend/app/routers/analytics.py`
- `POST /api/v1/analytics/goals/recalculate` — `backend/app/routers/analytics.py`
- `POST /api/v1/analytics/kpis` — `backend/app/routers/analytics.py`
- `POST /api/v1/analytics/warehouse/refresh` — `backend/app/routers/analytics.py`
- `POST /api/v1/animals` — `backend/app/routers/animals.py`
- `POST /api/v1/atlas-ai/chat` — `backend/app/routers/atlas_ai_enterprise.py`
- `POST /api/v1/atlas-ai/memories` — `backend/app/routers/atlas_ai_enterprise.py`
- `POST /api/v1/atlas-ai/plans` — `backend/app/routers/atlas_ai_enterprise.py`
- `POST /api/v1/atlas-ai/sessions` — `backend/app/routers/atlas_ai_enterprise.py`
- `POST /api/v1/auth/confirm-email` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/login` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/logout` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/mfa/challenge` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/mfa/setup` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/mfa/verify` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/password/confirm` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/password/request` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/refresh` — `backend/app/routers/auth.py`
- `POST /api/v1/auth/switch-company` — `backend/app/routers/auth.py`
- `POST /api/v1/automation/calendar` — `backend/app/routers/automation.py`
- `POST /api/v1/automation/events/execute` — `backend/app/routers/automation.py`
- `POST /api/v1/automation/executive-digests` — `backend/app/routers/automation.py`
- `POST /api/v1/automation/objectives` — `backend/app/routers/automation.py`
- `POST /api/v1/automation/rules` — `backend/app/routers/automation.py`
- `POST /api/v1/automation/workflows` — `backend/app/routers/automation.py`
- `POST /api/v1/automation/workflows/{workflow_id}/start` — `backend/app/routers/automation.py`
- `POST /api/v1/backups/run` — `backend/app/routers/backups.py`
- `POST /api/v1/business/api-keys` — `backend/app/routers/business.py`
- `POST /api/v1/business/bi/snapshots` — `backend/app/routers/business.py`
- `POST /api/v1/business/commercial-documents` — `backend/app/routers/business.py`
- `POST /api/v1/business/consulting/actions` — `backend/app/routers/business.py`
- `POST /api/v1/business/consulting/visits` — `backend/app/routers/business.py`
- `POST /api/v1/business/parties` — `backend/app/routers/business.py`
- `POST /api/v1/business/subscriptions` — `backend/app/routers/business.py`
- `POST /api/v1/business/webhooks` — `backend/app/routers/business.py`
- `POST /api/v1/business/workflows` — `backend/app/routers/business.py`
- `POST /api/v1/business/workflows/start` — `backend/app/routers/business.py`
- `POST /api/v1/business/workflows/{instance_id}/decision` — `backend/app/routers/business.py`
- `POST /api/v1/commercial/contracts` — `backend/app/routers/commercial.py`
- `POST /api/v1/commercial/customers` — `backend/app/routers/commercial.py`
- `POST /api/v1/commercial/invoices` — `backend/app/routers/commercial.py`
- `POST /api/v1/commercial/notifications/due` — `backend/app/routers/commercial.py`
- `POST /api/v1/commercial/opportunities` — `backend/app/routers/commercial.py`
- `POST /api/v1/commercial/plans` — `backend/app/routers/commercial.py`
- `POST /api/v1/commercial/proposals` — `backend/app/routers/commercial.py`
- `POST /api/v1/commercial/subscriptions` — `backend/app/routers/commercial.py`
- `POST /api/v1/companies` — `backend/app/routers/companies.py`
- `POST /api/v1/corporate-intelligence/plans` — `backend/app/routers/corporate_intelligence.py`
- `POST /api/v1/corporate-intelligence/scenarios` — `backend/app/routers/corporate_intelligence.py`
- `POST /api/v1/data-platform/benchmarks/cohorts` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/benchmarks/generate` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/cache` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/events` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/events/publish` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/jobs` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/jobs/claim` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/kpis/definitions` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/kpis/observations` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/realtime/metrics` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/reports` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/warehouse/dimensions` — `backend/app/routers/data_platform.py`
- `POST /api/v1/data-platform/warehouse/facts` — `backend/app/routers/data_platform.py`
- `POST /api/v1/ecosystem/partners` — `backend/app/routers/ecosystem.py`
- `POST /api/v1/ecosystem/support` — `backend/app/routers/ecosystem.py`
- `POST /api/v1/enterprise-operations/assets/usage` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/consulting/visits` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/crm/leads` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/documents` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/purchases` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/sales` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/support/tickets` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/teams` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/workflows/definitions` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/enterprise-operations/workflows/{definition_id}/start` — `backend/app/routers/enterprise_operations.py`
- `POST /api/v1/farm-operations/farms/{farm_id}/assets` — `backend/app/routers/farm_operations.py`
- `POST /api/v1/farm-operations/farms/{farm_id}/work-orders` — `backend/app/routers/farm_operations.py`
- `POST /api/v1/farms` — `backend/app/routers/farms.py`
- `POST /api/v1/finance-enterprise/farms/{farm_id}/budgets` — `backend/app/routers/finance_enterprise.py`
- `POST /api/v1/global-platform/certifications` — `backend/app/routers/global_platform.py`
- `POST /api/v1/global-platform/training` — `backend/app/routers/global_platform.py`
- `POST /api/v1/governance/catalog/assets` — `backend/app/routers/governance.py`
- `POST /api/v1/governance/compliance/controls` — `backend/app/routers/governance.py`
- `POST /api/v1/governance/compliance/controls/{control_id}/assess` — `backend/app/routers/governance.py`
- `POST /api/v1/governance/health/snapshots` — `backend/app/routers/governance.py`
- `POST /api/v1/governance/incidents` — `backend/app/routers/governance.py`
- `POST /api/v1/governance/policies` — `backend/app/routers/governance.py`
- `POST /api/v1/governance/quality/assets/{asset_id}/run` — `backend/app/routers/governance.py`
- `POST /api/v1/governance/quality/rules` — `backend/app/routers/governance.py`
- `POST /api/v1/health-intelligence/farms/{farm_id}/medicines` — `backend/app/routers/health_intelligence.py`
- `POST /api/v1/health-intelligence/farms/{farm_id}/occurrences` — `backend/app/routers/health_intelligence.py`
- `POST /api/v1/integrations/connections` — `backend/app/routers/integrations.py`
- `POST /api/v1/integrations/partners/applications` — `backend/app/routers/integrations.py`
- `POST /api/v1/integrations/providers` — `backend/app/routers/integrations.py`
- `POST /api/v1/integrations/sync-jobs` — `backend/app/routers/integrations.py`
- `POST /api/v1/integrations/usage` — `backend/app/routers/integrations.py`
- `POST /api/v1/integrations/webhooks` — `backend/app/routers/integrations.py`
- `POST /api/v1/integrations/webhooks/events` — `backend/app/routers/integrations.py`
- `POST /api/v1/inventory-enterprise/farms/{farm_id}/counts` — `backend/app/routers/inventory_enterprise.py`
- `POST /api/v1/iot/devices` — `backend/app/routers/iot.py`
- `POST /api/v1/iot/gateways` — `backend/app/routers/iot.py`
- `POST /api/v1/iot/telemetry/ingest` — `backend/app/routers/iot.py`
- `POST /api/v1/livestock/animals` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/animals/{animal_id}/movements` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/animals/{animal_id}/reproduction` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/animals/{animal_id}/weights` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/finance` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/finance/v2` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/health` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/health/protocols` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/health/protocols/{protocol_id}/apply` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/inventory/products` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/inventory/products/v2` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/inventory/products/{product_id}/movements` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/inventory/products/{product_id}/movements/v2` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/lots` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/nutrition` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/nutrition/ingredients` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/nutrition/lots/{lot_id}/consumption` — `backend/app/routers/livestock.py`
- `POST /api/v1/livestock/nutrition/plans` — `backend/app/routers/livestock.py`
- `POST /api/v1/members` — `backend/app/routers/members.py`
- `POST /api/v1/members/{membership_id}/reset-password` — `backend/app/routers/members.py`
- `POST /api/v1/ml/datasets` — `backend/app/routers/ml.py`
- `POST /api/v1/ml/deployments` — `backend/app/routers/ml.py`
- `POST /api/v1/ml/deployments/{deployment_id}/drift` — `backend/app/routers/ml.py`
- `POST /api/v1/ml/features` — `backend/app/routers/ml.py`
- `POST /api/v1/ml/models` — `backend/app/routers/ml.py`
- `POST /api/v1/ml/predictions/{prediction_id}/feedback` — `backend/app/routers/ml.py`
- `POST /api/v1/ml/training-runs` — `backend/app/routers/ml.py`
- `POST /api/v1/nutrition-intelligence/farms/{farm_id}/simulations` — `backend/app/routers/nutrition_intelligence.py`
- `POST /api/v1/offline/conflicts/{conflict_id}/resolve` — `backend/app/routers/offline_sync.py`
- `POST /api/v1/offline/devices/register` — `backend/app/routers/offline_sync.py`
- `POST /api/v1/offline/diagnostics` — `backend/app/routers/offline_sync.py`
- `POST /api/v1/offline/push-batch` — `backend/app/routers/offline_sync.py`
- `POST /api/v1/operations/alerts/generate` — `backend/app/routers/operations.py`
- `POST /api/v1/operations/alerts/{alert_id}/task` — `backend/app/routers/operations.py`
- `POST /api/v1/operations/conflicts/{entity_type}/{entity_id}/resolve` — `backend/app/routers/operations.py`
- `POST /api/v1/operations/indicators/generate` — `backend/app/routers/operations.py`
- `POST /api/v1/operations/tasks` — `backend/app/routers/operations.py`
- `POST /api/v1/platform/ai/recommendations/{recommendation_id}/decision` — `backend/app/routers/platform.py`
- `POST /api/v1/platform/automations/farms/{farm_id}/bootstrap` — `backend/app/routers/platform.py`
- `POST /api/v1/platform/automations/farms/{farm_id}/evaluate` — `backend/app/routers/platform.py`
- `POST /api/v1/precision-hub/adapters` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-hub/devices/{device_id}/telemetry` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-hub/farms/{farm_id}/devices` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-hub/farms/{farm_id}/geo-assets` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-hub/farms/{farm_id}/geofences` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-hub/farms/{farm_id}/remote-sensing/scenes` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-hub/farms/{farm_id}/rfid-bindings` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-hub/farms/{farm_id}/vision` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-hub/vision/{analysis_id}/review` — `backend/app/routers/precision_hub.py`
- `POST /api/v1/precision-livestock/farms/{farm_id}/assessments` — `backend/app/routers/precision_livestock.py`
- `POST /api/v1/realtime/notifications` — `backend/app/routers/realtime.py`
- `POST /api/v1/realtime/publish` — `backend/app/routers/realtime.py`
- `POST /api/v1/realtime/subscriptions` — `backend/app/routers/realtime.py`
- `POST /api/v1/release-engineering/builds` — `backend/app/routers/release_engineering.py`
- `POST /api/v1/release-engineering/change-approvals` — `backend/app/routers/release_engineering.py`
- `POST /api/v1/release-engineering/deployments` — `backend/app/routers/release_engineering.py`
- `POST /api/v1/release-engineering/environments` — `backend/app/routers/release_engineering.py`
- `POST /api/v1/release-engineering/feature-flags` — `backend/app/routers/release_engineering.py`
- `POST /api/v1/release-engineering/metrics` — `backend/app/routers/release_engineering.py`
- `POST /api/v1/release-engineering/pipelines` — `backend/app/routers/release_engineering.py`
- `POST /api/v1/release-engineering/readiness-checks` — `backend/app/routers/release_engineering.py`
- `POST /api/v1/release-growth/capability-reviews` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/documentation` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/environments` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/growth-experiments` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/learning-paths` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/mobile-profiles` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/pilots` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/readiness` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/roadmaps` — `backend/app/routers/release_growth.py`
- `POST /api/v1/release-growth/web-releases` — `backend/app/routers/release_growth.py`
- `POST /api/v1/reproduction-advanced/farms/{farm_id}/protocols` — `backend/app/routers/reproduction_advanced.py`
- `POST /api/v1/reproduction-advanced/farms/{farm_id}/seasons` — `backend/app/routers/reproduction_advanced.py`
- `POST /api/v1/saas-growth/communications/deliveries` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/saas-growth/communications/templates` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/saas-growth/exports` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/saas-growth/feature-flags` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/saas-growth/imports` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/saas-growth/invoices` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/saas-growth/onboarding` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/saas-growth/plans` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/saas-growth/subscriptions` — `backend/app/routers/saas_growth.py`
- `POST /api/v1/security-compliance/audit` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/availability-targets` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/backups` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/certifications` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/continuity-plans` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/incidents` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/privacy/requests` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/regional-policies` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/roles` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-compliance/translations` — `backend/app/routers/security_compliance.py`
- `POST /api/v1/security-enterprise/access-reviews` — `backend/app/routers/security_enterprise.py`
- `POST /api/v1/security-enterprise/continuity/exercises` — `backend/app/routers/security_enterprise.py`
- `POST /api/v1/security-enterprise/continuity/plans` — `backend/app/routers/security_enterprise.py`
- `POST /api/v1/security-enterprise/policies` — `backend/app/routers/security_enterprise.py`
- `POST /api/v1/security-enterprise/posture/snapshots` — `backend/app/routers/security_enterprise.py`
- `POST /api/v1/security-enterprise/privacy/consents` — `backend/app/routers/security_enterprise.py`
- `POST /api/v1/security-enterprise/privacy/requests` — `backend/app/routers/security_enterprise.py`
- `POST /api/v1/security-enterprise/risks` — `backend/app/routers/security_enterprise.py`
- `POST /api/v1/sprints-16-20/analytics/datasets` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/sprints-16-20/analytics/facts` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/sprints-16-20/billing/subscriptions` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/sprints-16-20/billing/webhooks/{provider}` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/sprints-16-20/enterprise/releases` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/sprints-16-20/ml/models` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/sprints-16-20/ml/models/{model_id}/predict` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/sprints-16-20/public-api/apps` — `backend/app/routers/enterprise_product.py`
- `POST /api/v1/sprints/brain/farms/{farm_id}/agents/{agent}` — `backend/app/routers/innovation_platform.py`
- `POST /api/v1/sprints/brain/farms/{farm_id}/memory` — `backend/app/routers/innovation_platform.py`
- `POST /api/v1/sprints/brain/farms/{farm_id}/simulate` — `backend/app/routers/innovation_platform.py`
- `POST /api/v1/sprints/brain/farms/{farm_id}/weekly-plan` — `backend/app/routers/innovation_platform.py`
- `POST /api/v1/sprints/cloud/jobs` — `backend/app/routers/innovation_platform.py`
- `POST /api/v1/sprints/iot/devices/{device_id}/telemetry` — `backend/app/routers/innovation_platform.py`
- `POST /api/v1/sprints/iot/farms/{farm_id}/devices` — `backend/app/routers/innovation_platform.py`
- `POST /api/v1/sprints/vision/farms/{farm_id}/analyze` — `backend/app/routers/innovation_platform.py`
- `POST /api/v1/sync/push` — `backend/app/routers/sync.py`
- `PUT /api/v1/advanced/farms/{farm_id}/genetics` — `backend/app/routers/advanced.py`
- `PUT /api/v1/global-platform/localization` — `backend/app/routers/global_platform.py`
- `PUT /api/v1/sprints/web/workspace` — `backend/app/routers/innovation_platform.py`
```

### 9.122 — `docs/integration/CICLO_2_REBANHO_INTEGRADO.md`

```text
# Ciclo 2 — Rebanho integrado

O Ciclo 2 conecta a área **Rebanho** diretamente aos endpoints oficiais do backend.

## Sprint 136 — Lista de animais
- carregamento por fazenda ativa e por lote;
- busca por brinco, SISBOV, nome, raça e categoria;
- filtros por lote, situação e sexo;
- estados de carregamento, erro e vazio.

## Sprint 137 — Cadastro e edição
- criação de lote por `POST /api/v1/livestock/lots`;
- edição de lote por `PATCH /api/v1/livestock/lots/{lot_id}`;
- criação de animal por `POST /api/v1/livestock/animals`;
- edição de animal por `PATCH /api/v1/livestock/animals/{animal_id}`;
- exclusão autorizada pelo endpoint oficial.

## Sprint 138 — Detalhes e linha do tempo
A lista abre o `AnimalDetailScreen`, que mantém genealogia, documentos, fotos, sanidade, reprodução, linha do tempo e painéis especializados já existentes.

## Sprint 139 — Pesagens
O atalho de pesagens abre `AnimalWeightListScreen`, conectado a:
- `GET /api/v1/livestock/animals/{animal_id}/weights`;
- `POST /api/v1/livestock/animals/{animal_id}/weights`.

## Sprint 140 — Movimentações e lotes
O atalho de movimentações abre `AnimalMovementListScreen`, conectado a:
- `GET /api/v1/livestock/animals/{animal_id}/movements`;
- `POST /api/v1/livestock/animals/{animal_id}/movements`.

A troca de lote atualiza o cadastro oficial e preserva o histórico imutável.
```

### 9.123 — `docs/integration/CICLO_3_MODULOS_ZOOTECNICOS.md`

```text
# Ciclo 3 — Módulos zootécnicos integrados

## Escopo

- Sprint 141: Reprodução por fazenda ativa.
- Sprint 142: Sanidade por fazenda ativa.
- Sprint 143: Nutrição por fazenda ativa.
- Sprint 144: Estoque por fazenda ativa.
- Sprint 145: Financeiro por fazenda ativa.

## Contratos oficiais

| Módulo | Endpoints principais |
|---|---|
| Reprodução | `GET /api/v1/livestock/reproduction/summary` |
| Sanidade | `GET /api/v1/livestock/health`, `/health/protocols`, `/health/alerts` |
| Nutrição | `GET /api/v1/livestock/nutrition/performance`, `/ingredients`, `/plans` |
| Estoque | `GET /api/v1/livestock/inventory/products`, `/inventory/alerts` |
| Financeiro | `GET /api/v1/livestock/finance/summary`, `/finance/v2` |

Todas as consultas usam o `farm_id` da fazenda ativa e os headers de empresa, tenant e fazenda fornecidos pelo `AtlasHttpClient`.

## Estados obrigatórios

Cada módulo possui carregamento, erro com nova tentativa, vazio, dados carregados, busca e atualização manual/por gesto.
```

### 9.124 — `docs/integration/CICLO_4_OFFLINE_SINCRONIZACAO.md`

```text
# Ciclo 4 — Offline e sincronização

## Escopo

O Ciclo 4 consolida os Sprints 146 a 150:

- banco local com isolamento por empresa e fazenda;
- fila idempotente com retentativa e backoff;
- pull incremental por cursor;
- push em lotes de até 200 operações;
- conflitos explícitos com decisão humana.

## Contratos utilizados

- `POST /api/v1/offline/devices/register`
- `POST /api/v1/offline/push-batch`
- `GET /api/v1/offline/pull-page`
- `GET /api/v1/offline/conflicts`
- `POST /api/v1/offline/conflicts/{id}/resolve`
- `POST /api/v1/offline/diagnostics`
- `GET /api/v1/offline/status`

## Regras de segurança

Tokens não são armazenados no SQLite. A fila local mantém apenas o contexto necessário da operação. O cache usa escopo de empresa, tenant e fazenda e nunca deve ser consultado fora desse escopo.

## Estratégia de falha

Operações transitórias voltam para `retry` com backoff exponencial. Rejeições permanentes ficam em `failed`. Divergências de versão ficam em `conflict` e exigem resolução humana.
```

### 9.125 — `docs/integration/CICLO_5_OPERACAO_DE_CAMPO.md`

```text
# Ciclo 5 — Operação de campo

Sprints 151 a 155: formulários rápidos, operações em massa, RFID/QR, capturas e diagnóstico local.

Todas as gravações passam pela fila offline oficial, com escopo de empresa, tenant e fazenda.
```

### 9.126 — `docs/integration/CICLO_6_INTELIGENCIA_ATLAS.md`

```text
# Ciclo 6 — Inteligência Atlas

Sprints 156 a 160: painel executivo, recomendações auditáveis, agentes, simulador e automações supervisionadas.

A interface utiliza os endpoints `/ai-operational` já existentes no backend consolidado.
```

### 9.127 — `docs/integration/CICLOS_7_A_9_PLATAFORMAS.md`

```text
# Ciclos 7 a 9 — Projeto Atlas

## Ciclo 7 — IoT, mapas e visão
Precision Hub integrado à fazenda ativa: dispositivos, RFID, geocercas, visão, geoativos e sensoriamento remoto.

## Ciclo 8 — Consultoria e empresa
Operações Enterprise: visitas técnicas, equipes, ativos, compras, vendas, CRM, suporte, workflows e documentos.

## Ciclo 9 — SaaS e administração
Portal e administração SaaS: planos, assinaturas, faturamento, feature flags, comunicação, onboarding, importação e exportação.

Todos os módulos utilizam `AtlasHttpClient`, contexto autenticado e permissões `platform.read` e `platform.manage`.
```

### 9.128 — `docs/pilot/PILOT_RUNBOOK.md`

```text
# Runbook do piloto

## Seleção
Fazenda com patrocinador, equipe disponível, conectividade conhecida e dados mínimos.
## Preparação
Backup, saneamento, importação, usuários e dispositivos.
## Operação assistida
Reunião diária curta, registro de incidentes e nenhuma automação crítica sem aprovação.
## Medição
Baseline, metas, adoção, qualidade dos dados, tempo economizado e resultados zootécnicos/financeiros.
## Encerramento
Aceite, lições aprendidas, correções priorizadas e decisão de expansão.
```

### 9.129 — `docs/pilot/PILOT_SCORECARD.md`

```text
# Scorecard do piloto

- Identificação do rebanho
- Sincronização e qualidade dos dados
- Usuários treinados e ativos
- Tempo por operação
- Aderência aos protocolos
- Incidentes e tempo de resolução
- Benefício econômico estimado e realizado
```

### 9.130 — `docs/publication/ANDROID_RELEASE.md`

```text
# Publicação Android

1. Validar `flutter analyze` e `flutter test`.
2. Configurar assinatura fora do repositório.
3. Gerar `flutter build appbundle --release`.
4. Testar em faixa interna da Play Console.
5. Confirmar política de privacidade, classificação indicativa e suporte.
6. Liberar produção somente após aprovação humana.
```

### 9.131 — `docs/publication/IOS_RELEASE.md`

```text
# Publicação iOS

1. Validar certificados e perfis no ambiente Apple autorizado.
2. Executar testes em dispositivos reais.
3. Gerar archive pelo Xcode.
4. Publicar primeiro no TestFlight.
5. Confirmar privacidade, permissões e dados de suporte.
6. Liberar a App Store após aceite do gate de release.
```

### 9.132 — `docs/publication/PRIVACIDADE_TERMOS_SUPORTE.md`

```text
# Privacidade, termos e suporte

A publicação exige política de privacidade, termos de uso, canal de contato, procedimento LGPD, identificação do controlador, política de retenção e processo de incidentes. Esses documentos devem passar por revisão jurídica antes da produção.
```

### 9.133 — `docs/publication/WEB_RELEASE.md`

```text
# Publicação Web

1. Executar `flutter build web --release`.
2. Validar headers de segurança e cache.
3. Configurar HTTPS, domínio, monitoramento e rollback.
4. Validar autenticação, responsividade e acessibilidade.
5. Publicar primeiro em homologação.
```

### 9.134 — `docs/release/RELEASE_RUNBOOK.md`

```text
# Runbook de release

1. Executar gate completo.
2. Criar backup e testar restauração.
3. Registrar versão, migrations e responsáveis.
4. Aprovação humana no ambiente staging.
5. Implantar gradualmente.
6. Validar healthcheck, OpenAPI, login, sync e métricas.
7. Manter artefato anterior disponível para rollback.
```

### 9.135 — `docs/release/ROLLBACK_RUNBOOK.md`

```text
# Runbook de rollback

Rollback nunca é silencioso. Confirmar backup, congelar mudanças, restaurar artefato anterior, avaliar compatibilidade de migrations, executar smoke tests e registrar incidente.
```

### 9.136 — `docs/strategy/ARCHITECTURE_MODULAR_TARGET.md`

```text
# Arquitetura modular alvo

Cada domínio deve possuir contratos, modelos, serviços, interface, testes e observabilidade próprios. Dependências entre domínios devem ocorrer por contratos explícitos. O isolamento por empresa, tenant e fazenda é obrigatório.
```

### 9.137 — `docs/strategy/ATLAS_3_ROADMAP_5_ANOS.md`

```text
# Atlas 3.0 — Roadmap de cinco anos

## Ano 1 — Produto confiável
Concluir publicação, observabilidade, piloto e operação assistida.

## Ano 2 — Escala nacional
Padronizar onboarding, parceiros, suporte e infraestrutura multi-tenant.

## Ano 3 — Ecossistema
Abrir integrações supervisionadas para laboratórios, equipamentos e consultores.

## Ano 4 — Inteligência setorial
Ampliar benchmarks anonimizados e modelos auditáveis por sistema produtivo.

## Ano 5 — Expansão internacional
Localização, conformidade regional, parceiros e novas cadeias pecuárias.
```

### 9.138 — `docs/strategy/MULTITENANT_SCALE_PLAN.md`

```text
# Plano de escala multi-tenant

- validar índices e consultas por tenant;
- aplicar limites e quotas por plano;
- isolar filas, cache e armazenamento;
- medir custo por tenant;
- testar concorrência e recuperação;
- impedir vazamento entre organizações em todos os gates.
```

### 9.139 — `docs/v1/ATLAS_V1_PASSOS_11_A_20.md`

```text
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
```

### 9.140 — `LEIA_ME_APLICACAO.txt`

```text
CORREÇÃO DO DASHBOARD — SPRINTS 21 A 25

1. Substitua integralmente o arquivo:
lib/features/atlas_sprints_21_25/presentation/screens/atlas_sprints_21_25_dashboard_screen.dart

2. Confirme que os routers antigos foram removidos, pois o main.py novo não os utiliza:
backend/app/routers/sprints_11_15.py
backend/app/routers/sprints_16_20.py

3. Execute:
flutter clean
flutter pub get
flutter analyze
flutter run -d windows

A correção move o .toList() para o resultado do map(), garantindo que children receba List<Widget>.
```

### 9.141 — `LEIA_ME_ATLAS_ANDROID_1.md`

```text
# Atlas Android 1.0

Objetivo único desta entrega: instalar e aprovar o Projeto Atlas em um celular Android real.

Guia completo:

'''text
docs/android/ATLAS_ANDROID_1_PRIMEIRO_DISPOSITIVO.md
'''

Comando inicial:

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\01_validate_project.ps1
'''

Não inicie novos ciclos antes de concluir o checklist do primeiro dispositivo.
```

### 9.142 — `LEIA_ME_ATLAS_V1_PASSOS_1_A_10.md`

```text
# Projeto Atlas — Consolidação V1 — Passos 1 a 10

## Objetivo
Fechar a primeira rodada de estabilização sem criar funcionalidades novas.

## Resultado
- **248 telas** inventariadas.
- Classificação: {'ADMIN_OU_OPERACIONAL': 59, 'AVANCADO_POS_V1': 71, 'REVISAR': 78, 'V1_ESSENCIAL': 40}.
- Fazenda ativa passa a ser selecionada antes de entrar no detalhe da propriedade.
- Cabeçalho principal da fazenda foi refeito para telas estreitas.
- Cards de piquetes foram adaptados para celular.
- Dados demonstrativos automáticos de `Piquete 01`, `Piquete 02` e `42 animais` foram removidos.
- Permissões não administrativas sem lista explícita agora usam **default deny**.
- Logout/restauração inválida limpam também o contexto de fazenda.
- Sincronização offline bloqueia execução sem empresa, tenant ou dispositivo.

## Estado dos 10 passos

### 1. Responsividade Android
**Status:** IMPLEMENTADO_NESTE_PACOTE

- farm_detail_screen.dart: FarmDashboardHeader responsivo
- paddock_list_screen.dart: PaddockCard responsivo
- atlas_livestock_module_screen.dart: padding móvel

### 2. Contexto da fazenda
**Status:** IMPLEMENTADO_NESTE_PACOTE

- FarmListScreen seleciona a fazenda da sessão antes de abrir detalhes
- AtlasSessionController persiste activeFarm

### 3. Auditoria das 248 telas
**Status:** IMPLEMENTADO_NESTE_PACOTE

- ATLAS_V1_AUDITORIA_248_TELAS.csv
- classificação V1/Admin/Avançado/Revisar

### 4. Seis módulos operacionais centrais
**Status:** CONSOLIDADO_SEM_RECRIAR

- Rebanho usa HerdOverviewScreen
- Sanidade/Reprodução/Nutrição/Financeiro/Estoque usam AtlasLivestockModuleScreen oficial

### 5. Fazendas e manejo
**Status:** CONSOLIDADO_COM_PENDENCIA_DE_BACKEND_PARA_PIQUETES

- Fazendas usam FarmStorageService com API como autoridade quando autenticado
- Piquetes ainda persistem localmente

### 6. Persistência real
**Status:** PARCIAL_E_EXPLICITA

- Fazendas CRUD remoto + cache local
- Módulos centrais consultam backend
- Piquetes e partes legadas ainda usam SharedPreferences

### 7. Eliminar dados demonstrativos
**Status:** IMPLEMENTADO_NO_FLUXO_CRITICO

- Removida criação automática de Piquete 01/Piquete 02/42 animais

### 8. Autenticação real
**Status:** ENDURECIDA

- Restauração de sessão existente
- logout limpa activeFarm
- falha de restore limpa sessão/contexto

### 9. Permissões e multiempresa
**Status:** ENDURECIDA

- default-deny para sessão não-admin sem permissões
- fazenda só pode ser selecionada se autorizada

### 10. Offline e sincronização
**Status:** ENDURECIDA

- sync exige companyId, tenantId e deviceId
- fila/push/pull/conflitos existentes preservados

## Pendências que não foram mascaradas
- Criar contrato/endpoints oficiais de Piquetes no backend antes de considerar esse módulo persistido em produção.
- Migrar telas legadas que ainda usam SharedPreferences como autoridade para API/offline repository.
- Executar flutter analyze e flutter test no ambiente do usuário após substituição.
- Revalidar visualmente todas as telas V1_ESSENCIAL no Moto G75 5G.


## Validação no Windows
'''powershell
dart format lib
flutter analyze
flutter test
'''

## Validação no Android
Com backend ativo e o Moto G75 5G conectado:
'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\09_prepare_first_android_run.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\android\05_run_on_android.ps1
'''
```

### 9.143 — `LEIA_ME_BLOCOS_1_A_5.md`

```text
# ATLAS — BLOCOS 1 A 5

Entrega integrada dos passos 51 a 100: IA, georreferenciamento, pastagens, agricultura integrada e genética.

## Arquivos novos
- backend/app/advanced_models.py
- backend/app/routers/advanced.py
- backend/alembic/versions/20260806_0023_advanced_blocks_1_5.py
- backend/tests/test_advanced_blocks_1_5_contract.py
- lib/features/atlas_advanced/domain/models/atlas_advanced_data.dart
- lib/features/atlas_advanced/data/services/atlas_advanced_service.dart
- lib/features/atlas_advanced/presentation/screens/atlas_advanced_dashboard_screen.dart

## Arquivo substituído
- backend/app/main.py

## Aplicação
1. Copie os arquivos mantendo os caminhos.
2. Execute no backend: `python -m alembic upgrade head`.
3. Execute: `python -m pytest -q` e `python -m uvicorn app.main:app --reload`.
4. No Flutter: `flutter clean`, `flutter pub get`, `flutter analyze`, `flutter run -d windows`.

## Observações
- KML, KMZ e shapefile são aceitos por conversão para GeoJSON; o backend não finge interpretar binários sem biblioteca geoespacial.
- IA climática recebe dados climáticos no payload até que um provedor oficial seja configurado.
- DEP e registros genealógicos podem ser importados manualmente ou por futura integração com associações oficiais.
```

### 9.144 — `LEIA_ME_BLOCOS_6_A_10.md`

```text
# ATLAS — BLOCOS 6 A 10

Esta entrega implementa os passos 101 a 150: comercialização, consultoria, plataforma Enterprise, BI e produto comercial.

## Aplicação
1. Faça backup do projeto e banco.
2. Substitua todos os arquivos mantendo os caminhos.
3. No backend: `python -m alembic upgrade head`, `python -m pytest -q`, `python -m uvicorn app.main:app --reload`.
4. No Flutter: `flutter clean`, `flutter pub get`, `flutter analyze`, `flutter run -d windows`.

## Migration
`20260806_0024`, dependente de `20260806_0023`.

## Limites honestos
Nota fiscal, assinatura digital, gateways de pagamento, envio real de webhooks, publicação nas lojas e Power BI exigem credenciais, homologação e provedores externos. Esta entrega cria contratos, persistência, segurança e estados operacionais para essas integrações, sem simular serviços externos.
```

### 9.145 — `LEIA_ME_CICLO_1_SPRINTS_131_A_135.md`

```text
# Ciclo 1 — Sprints 131 a 135

Implementações:

1. Inventário automático de telas Flutter e endpoints FastAPI.
2. Cliente HTTP com request ID, contexto de empresa, tenant e fazenda, renovação de token e validação de JSON.
3. Login remoto, MFA, restauração de sessão e logout centralizado.
4. Seleção de empresa e fazenda ativa com persistência segura.
5. Shell de navegação oficial com módulos filtrados por permissão.

## Validação

'''powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d windows
'''

Backend:

'''powershell
cd backend
.\.venv\Scripts\Activate.ps1
python scripts\quality\check_openapi.py
python -m pytest -q
python -m uvicorn app.main:app --reload
'''
```

### 9.146 — `LEIA_ME_CICLO_2_SPRINTS_136_A_140.md`

```text
# Projeto Atlas — Ciclo 2

Esta entrega deve substituir integralmente o projeto do Ciclo 1.

## Validação
'''powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d windows
'''

O backend permanece no checkpoint consolidado. Valide com o gate já existente em `backend/scripts/quality`.
```

### 9.147 — `LEIA_ME_CICLO_3_SPRINTS_141_A_145.md`

```text
# Projeto Atlas — Ciclo 3

Esta entrega integra os cinco módulos zootécnicos centrais ao backend oficial e ao contexto ativo da sessão.

## Validação

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\quality_cycle3.ps1
'''
```

### 9.148 — `LEIA_ME_CICLO_4_SPRINTS_146_A_150.md`

```text
# Ciclo 4 — Sprints 146 a 150

Esta entrega implementa a camada offline oficial do Flutter e integra a Central Offline à navegação principal.

Validação recomendada:

'''powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
powershell -ExecutionPolicy Bypass -File .\scripts\quality_cycle4.ps1
'''
```

### 9.149 — `LEIA_ME_CICLOS_10_A_12.md`

```text
# Ciclos 10 a 12

Execute `powershell -ExecutionPolicy Bypass -File .\scripts\quality_cycles10_12.ps1`.

A entrega preserva o backend e todos os módulos anteriores.
```

### 9.150 — `LEIA_ME_CICLOS_13_A_15.md`

```text
# Ciclos 13 a 15

Esta entrega corrige o uso de `BuildContext` após lacuna assíncrona e adiciona qualidade do backend, desempenho/observabilidade e infraestrutura.

Execute:

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\quality_cycles13_15.ps1
'''
```

### 9.151 — `LEIA_ME_CICLOS_16_A_18.md`

```text
# Ciclos 16 a 18

Implementados CI/CD supervisionado, gestão de releases e rollback, preparação comercial e programa de piloto real. Execute `powershell -ExecutionPolicy Bypass -File .\scripts\quality_cycles16_18.ps1`.
```

### 9.152 — `LEIA_ME_CICLOS_19_E_20.md`

```text
# Ciclos 19 e 20

O Ciclo 19 formaliza publicação Android, iOS e Web, documentos legais e suporte de produção. O Ciclo 20 formaliza a arquitetura modular alvo, escala multi-tenant, expansão de mercado e roadmap de cinco anos.

Nenhuma publicação é automática: os workflows exigem confirmação e os artefatos devem ser revisados antes da liberação.
```

### 9.153 — `LEIA_ME_CICLOS_5_E_6.md`

```text
# Ciclos 5 e 6

A entrega adiciona a operação de campo offline-first e a Central de Inteligência Atlas sem criar backend paralelo.
```

### 9.154 — `LEIA_ME_CICLOS_7_A_9.md`

```text
# Ciclos 7 a 9

'''powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d windows
'''

Gate completo:

'''powershell
powershell -ExecutionPolicy Bypass -File .\scripts\quality_cycles7_9.ps1
'''
```

### 9.155 — `LEIA_ME_CORRECAO_19_AVISOS_CURLY_BRACES.md`

```text
# Correção dos avisos `curly_braces_in_flow_control_structures`

Esta entrega preserva integralmente o Ciclo 2 e corrige os avisos exibidos pelo `flutter analyze`.

As estruturas condicionais apontadas passaram a usar blocos explícitos:

'''dart
if (condicao) {
  executarAcao();
}
'''

Nenhuma regra de negócio, endpoint, modelo ou fluxo de navegação foi removido.

## Validação

'''powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d windows
'''
```

### 9.156 — `LEIA_ME_CORRECAO_7_AVISOS.md`

```text
# Atlas V1 — correção dos 7 avisos do Dart Analyzer

Esta entrega parte diretamente de `ATLAS_V1_PASSOS_1_A_10_LIB_COMPLETA.zip`.

Foram corrigidos os avisos `curly_braces_in_flow_control_structures` nos arquivos:

- `atlas_action_plan_screen.dart`
- `enterprise_module_widgets.dart`
- `animal_health_list_screen.dart`
- `atlas_livestock_module_screen.dart`
- `technical_atlas_score.dart`

A correção adiciona blocos `{ }` aos `if` de fluxo de controle. Não altera regras de negócio,
endpoints, modelos, persistência ou navegação.

## Validação

Na raiz do Projeto Atlas:

'''powershell
dart format lib
flutter analyze
flutter test
'''

O objetivo é que a aba **Problemas** deixe de exibir esses sete avisos.
```

### 9.157 — `LEIA_ME_CORRECAO_DASHBOARD.txt`

```text
CORREÇÃO — ATLAS SPRINTS 16 A 20 DASHBOARD

Substitua integralmente:
lib/features/atlas_sprints_16_20/presentation/screens/atlas_sprints_16_20_dashboard_screen.dart

Depois execute:
flutter clean
flutter pub get
flutter analyze
flutter run -d windows

A correção moveu o .toList() para o resultado do map(), tipou o map como Widget e reorganizou toda a construção dos cards.
```

### 9.158 — `LEIA_ME_FASE_1.txt`

```text
PROJETO ATLAS — FASE 1

Implementa os passos 1 a 10: reprodução oficial, eventos padronizados, linha do tempo, status automático, calendário, indicadores, sanidade oficial, tipos sanitários, protocolos em massa e carências de medicamentos.

1. Faça backup.
2. Substitua/crie todos os arquivos do pacote mantendo os caminhos.
3. Backend:
   cd backend
   python -m pip install -r requirements.txt
   python -m alembic upgrade head
   python -m pytest -q
   python -m uvicorn app.main:app --reload
4. Flutter:
   flutter clean
   flutter pub get
   flutter analyze
   flutter run -d windows

Observação: a migration 20260806_0020 depende da 20260806_0019 entregue na consolidação de animais e lotes.
```

### 9.159 — `LEIA_ME_FASES_2_E_3.txt`

```text
ATLAS — FASES 2 E 3
====================

Este pacote parte da Fase 1 e implementa, respectivamente:

FASE 2
11. Alertas sanitários (base preparada pelos campos next_date, status, quarentena e carências da Fase 1).
12. Baixa de medicamentos no estoque pela infraestrutura transacional de movimentações.
13. Nutrição vinculada ao lote oficial.
14. Cadastro oficial de ingredientes.
15. Planos/formulação de dieta com composição bromatológica e custo.
16. Consumo real versus planejado.
17. Indicadores de ganho, conversão e custo por kg ganho.
18. Estoque oficial com entradas, saídas, perdas, ajustes e transferências.
19. Rastreabilidade por usuário, documento, lote do produto, saldo e referência.
20. Alertas de estoque mínimo e validade.

FASE 3
21. Categorias e centro de custo no lançamento oficial.
22. Todo lançamento vinculado a farm_id.
23. Custos opcionais por animal e lote.
24. Custos automáticos de nutrição; infraestrutura para sanidade.
25. Contas a pagar/receber com status, vencimento e liquidação.
26. Fluxo de caixa projetado.
27. Centros de custo.
28. Custos consolidados por lote.
29. Margem, custo operacional, equilíbrio, ROI e custo por animal.
30. Endpoint de resumo pronto para alimentar o Dashboard Executivo/Atlas Brain.

APLICAÇÃO
1. Faça backup do projeto e banco.
2. Copie os arquivos completos deste pacote, mantendo os caminhos.
3. Backend:
   cd backend
   python -m pip install -r requirements.txt
   python -m alembic upgrade head
   python -m pytest -q
   python -m uvicorn app.main:app --reload
4. Flutter:
   flutter clean
   flutter pub get
   flutter analyze
   flutter run -d windows

Migrations: 20260806_0021 e 20260806_0022.
Não execute 0022 sem 0021; o Alembic fará a ordem automaticamente.
```

### 9.160 — `LEIA_ME_FASES_4_E_5.md`

```text
# ATLAS — Fases 4 e 5

## Arquivos completos
Copie todos os arquivos preservando os caminhos. Esta entrega não cria tabelas novas, portanto não há migration adicional.

## Fase 4
31. Dashboard do rebanho consolidado no endpoint `/platform/dashboard/farms/{farm_id}`.
32. Indicadores reprodutivos oficiais agregados.
33. Indicadores sanitários oficiais agregados.
34. Indicadores nutricionais oficiais agregados.
35. Indicadores financeiros oficiais agregados.
36. Dashboard multifazenda em `/platform/dashboard/company`.
37. Atlas Brain revisado por recomendações determinísticas baseadas no snapshot oficial.
38. Contexto único da IA em `/platform/ai/context/farms/{farm_id}` com proveniência e limitações.
39. Recomendações explicáveis com evidências, confiança, impacto, prazo e decisão auditável.
40. Automações padrão, simulação segura e execução auditada.

## Fase 5
41. Permissões pecuárias incluídas no RBAC e distribuídas por papel.
42. Consultas da plataforma filtram `company_id` e validam fazendas permitidas.
43. Readiness verifica exclusão lógica dos registros operacionais.
44. Decisões e execuções da plataforma são registradas em `audit_logs`.
45. A plataforma usa a infraestrutura existente de `entity_states`, `sync_changes` e idempotência.
46. Readiness verifica integridade de versões; conflitos continuam tratados pelo `/sync/push`.
47. Smoke E2E em `backend/scripts/run_e2e_phase5.py`.
48. Tela Flutter executiva centralizada criada para auditoria visual e usabilidade.
49. Ambiente de homologação criado em `deploy/homologacao`.
50. Checklist de produção disponível em `/platform/production/readiness` para orientar o piloto.

## Aplicação
1. Faça backup do projeto e banco.
2. Substitua os arquivos completos deste pacote.
3. Backend:
   `cd backend`
   `python -m pip install -r requirements.txt`
   `python -m alembic upgrade head`
   `python -m pytest -q`
   `python -m uvicorn app.main:app --reload`
4. Flutter:
   `flutter clean`
   `flutter pub get`
   `flutter analyze`
   `flutter run -d windows`

## E2E
No PowerShell:
`$env:ATLAS_BASE_URL="http://127.0.0.1:8000/api/v1"`
`$env:ATLAS_ACCESS_TOKEN="SEU_TOKEN"`
`$env:ATLAS_FARM_ID="ID_DA_FAZENDA"`
`python backend/scripts/run_e2e_phase5.py`

## Observação
A tela `AtlasPlatformDashboardScreen` foi criada completa, mas deve ser ligada ao ponto de navegação que você escolher, passando `farmId` e `farmName`. Não substituí uma rota visual existente sem saber qual delas você deseja tornar oficial.
```

### 9.161 — `LEIA_ME_SPRINTS_11_A_15.md`

```text
# ATLAS — Sprints 11 a 15

Entrega integrada dos passos 151 a 200.

## Aplicação
Copie os arquivos mantendo os caminhos.

## Backend
'''powershell
cd backend
python -m pip install -r requirements.txt
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
'''

## Flutter
'''powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d windows
'''

## Limites reais
Vision usa contratos e entradas validadas; modelos de visão externos exigem provedor e treinamento. IoT possui cadastro e ingestão, mas cada fabricante exige adaptador. Redis/RabbitMQ estão preparados por contrato; a ativação depende do ambiente. A Plataforma Web usa a mesma API e workspace; publicação web depende do domínio e hospedagem.
```

### 9.162 — `LEIA_ME_SPRINTS_16_A_20.md`

```text
# Atlas — Sprints 16 a 20

Entrega consolidada dos passos 201 a 250.

## Aplicação
1. Faça backup do projeto e banco.
2. Copie os arquivos completos mantendo os caminhos.
3. Execute `python -m alembic upgrade head` no backend.
4. Execute `python -m pytest -q`.
5. Execute `flutter clean`, `flutter pub get`, `flutter analyze` e `flutter run -d windows`.

## Migration
- revision: `20260806_0026`
- down_revision: `20260806_0025`

## Limites externos
Stripe, Mercado Pago, Pix, lojas Android/iOS, Power BI e inferência ML real exigem credenciais, homologação e adaptadores oficiais. Os contratos desta entrega não simulam uma integração externa ativa.

## Endpoints principais
- `GET /api/v1/sprints-16-20/dashboard`
- `POST /api/v1/sprints-16-20/billing/subscriptions`
- `POST /api/v1/sprints-16-20/public-api/apps`
- `GET /api/v1/sprints-16-20/public-api/openapi-contract`
- `POST /api/v1/sprints-16-20/analytics/datasets`
- `GET /api/v1/sprints-16-20/analytics/kpis`
- `POST /api/v1/sprints-16-20/ml/models`
- `PATCH /api/v1/sprints-16-20/ml/models/{id}/approve`
- `GET /api/v1/sprints-16-20/enterprise/readiness`
```

### 9.163 — `LEIA_ME_SPRINTS_21_A_25.md`

```text
# Atlas — Sprints 21 a 25 e correção arquitetural

## Correção obrigatória de nomes

Depois de copiar os arquivos, EXCLUA estes routers genéricos antigos:

- `backend/app/routers/sprints_11_15.py`
- `backend/app/routers/sprints_16_20.py`

O novo `backend/app/main.py` não os importa mais.

Os routers passam a usar nomes de domínio:

- `atlas_brain.py`
- `atlas_vision.py`
- `iot_platform.py`
- `cloud_operations.py`
- `web_platform.py`
- `billing.py`
- `public_api.py`
- `enterprise_analytics.py`
- `machine_learning_registry.py`
- `enterprise_release.py`
- `innovation_platform.py` (preserva integralmente os endpoints anteriores dos Sprints 11 a 15)
- `enterprise_product.py` (preserva integralmente os endpoints anteriores dos Sprints 16 a 20)
- `precision_livestock.py`
- `reproduction_advanced.py`
- `health_intelligence.py`
- `nutrition_intelligence.py`
- `farm_operations.py`

## Migration

`20260806_0027`, dependente de `20260806_0026`.

## Aplicação

'''powershell
cd "C:\caminho\para\Projetos Atlas\backend"
python -m alembic upgrade head
python -m pytest -q
python -m uvicorn app.main:app --reload
'''

'''powershell
cd "C:\caminho\para\Projetos Atlas"
flutter clean
flutter pub get
flutter analyze
flutter run -d windows
'''
```

### 9.164 — `LEIA_ME_SPRINTS_51_A_60.md`

```text
# Sprints 51 a 60

## Entrega
- backend completo com dispositivos, push em lote, pull paginado, conflitos e diagnósticos;
- migration `20260806_0029`;
- núcleo Flutter de banco SQLite, fila e sincronização;
- testes e ferramenta de readiness.

## Aplicação
1. Substitua a pasta `backend` integralmente.
2. Copie `lib/core/offline` para o projeto Flutter.
3. Acrescente as dependências listadas em `ATLAS_PUBSPEC_DEPENDENCIES_SPRINTS_51_60.txt` ao `pubspec.yaml` existente.
4. Execute migrations, testes, `flutter pub get`, `flutter analyze` e `flutter test`.

O banco local não armazena tokens. Tokens e permissões offline devem usar `flutter_secure_storage` em uma etapa de integração com o serviço de autenticação já existente.
```

### 9.165 — `LEIA_ME_SPRINTS_61_A_70.md`

```text
# Aplicação
1. Substitua a pasta backend integralmente.
2. Copie lib/core/offline sobre a pasta lib atual.
3. Confirme `sqflite_common_ffi: ^2.3.6` no pubspec.yaml.
4. Execute migrations, testes e flutter analyze.
```

### 9.166 — `LEIA_ME_SPRINTS_71_A_80.md`

```text
# Atlas — Sprints 71 a 80

1. Substitua a pasta `backend` pela pasta completa deste pacote.
2. Preserve `.env` e `.venv`.
3. Execute `python -m alembic upgrade head`.
4. Execute `python scripts/precision/check_precision_hub.py`.
5. Execute `python -m pytest -q`.
6. Inicie com `python -m uvicorn app.main:app --reload`.

Migration oficial: `20260806_0031`, após `20260806_0030`.
```

### 9.167 — `PACOTES_26_A_30_MANIFESTO.json`

```text
{
  "base": "Projetos Atlas(3).zip enviado pelo usuário",
  "packages": [
    26,
    27,
    28,
    29,
    30
  ],
  "modules": [
    "Sanidade Enterprise",
    "Reprodução Enterprise",
    "Pesagens Inteligentes",
    "Nutrição Enterprise",
    "Painel Executivo do Animal"
  ]
}
```

### 9.168 — `pilot/CHECKLIST_ATLAS_1_0.md`

```text
# Checklist Atlas 1.0

- [ ] `flutter analyze` sem erros;
- [ ] `flutter test` aprovado;
- [ ] `pytest -q` aprovado;
- [ ] migrações aplicadas em homologação;
- [ ] backup e restauração testados;
- [ ] login, MFA e recuperação testados;
- [ ] isolamento multempresa testado;
- [ ] sincronização e conflitos testados;
- [ ] PDF e CSV validados;
- [ ] política de privacidade publicada;
- [ ] plano de suporte definido;
- [ ] piloto aprovado.
```

### 9.169 — `PUBSPEC_DEPENDENCIES_CORRIGIDAS_SPRINTS_61_70.txt`

```text
No pubspec.yaml atual, mantenha as dependências existentes e confirme esta entrada:

  sqflite_common_ffi: ^2.3.6

Os arquivos corrigidos não usam mais path_provider, path ou sqflite_common diretamente.
Depois execute:
  flutter pub get
  dart format lib/core/offline
  flutter analyze
```

### 9.170 — `VALIDACAO_24D_CORRECAO.txt`

```text
PROJETO ATLAS — VALIDAÇÃO FINAL DO PACOTE 24D

Correção aplicada:
- Removido import não utilizado de:
  lib/features/enterprise_platform/domain/services/atlas_http_sync_transport.dart

Linha removida:
import '../../data/services/atlas_enterprise_remote_auth_store.dart';

A arquitetura HTTP permanece inalterada:
AtlasHttpSyncTransport
  -> AtlasEnterpriseApiClient
  -> /api/v1/sync/push
  -> /api/v1/sync/pull

Validações executadas neste ambiente:
- Presença dos arquivos críticos do 24D.
- Estrutura dos endpoints.
- Sintaxe Python compilada com py_compile.
- Import não utilizado removido.
- Balanceamento estrutural básico dos arquivos Dart críticos.

O flutter analyze NÃO foi executado neste ambiente.

Execute no seu computador:

flutter clean
flutter pub get
flutter analyze
flutter run -d windows

Para o backend:

1. Copie backend/.env.example para backend/.env
2. Na raiz do projeto:
   docker compose up --build

Depois teste:
http://localhost:8000/api/v1/health
http://localhost:8000/docs
```


---

## 10. Atualização final desta consolidação

### 2026-08-07 — Fechamento funcional e consolidação do projeto
- **Objetivo:** concluir lacunas técnicas identificadas na auditoria e eliminar registros históricos fragmentados.
- **Funções afetadas:** Piquetes, Estoque, Nutrição, Financeiro, Agenda, migrações e organização documental.
- **Arquivos alterados:** backend/app/models/legacy.py; backend/app/schemas/legacy.py; backend/app/routers/livestock.py; backend/app/routers/farm_operations.py; backend/alembic/versions/20260804_0002_auth_security.py; backend/alembic/versions/20260807_0037_v1_final_paddocks.py; lib/features/paddock/**.
- **Backend/endpoints:** CRUD remoto de piquetes; update/delete de estoque, planos nutricionais e financeiro; list/delete de ordens operacionais.
- **Migrações:** criada 20260807_0037 para piquetes; migração de autenticação tornou-se idempotente para bancos previamente criados por create_all.
- **Persistência/offline:** piquetes deixam de usar SharedPreferences como autoridade e passam ao backend oficial.
- **Organização:** 169 arquivos históricos soltos de fase/ciclo/correção/checklist foram removidos do pacote final. Este Registro Mestre passa a ser o único registro evolutivo.
- **Testes executados:** validação estática Python/compilação de módulos backend será executada no fechamento do pacote. Flutter deve ser validado no ambiente com SDK.
- **Pendências externas:** testes no aparelho físico, HTTPS de produção, chave Android release, Play Console, política de privacidade e homologação continuam dependendo do ambiente/credenciais externos e não podem ser concluídos apenas alterando código.
- **Status final:** IMPLEMENTAÇÃO DE CÓDIGO CONCLUÍDA; HOMOLOGAÇÃO EXTERNA PENDENTE.


## 11. Procedimento único de validação desta versão

No Windows/VS Code, na raiz `C:\Projetos\Projetos Atlas`, execute nesta ordem:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Backend:

```powershell
cd "C:\Projetos\Projetos Atlas\backend"
.\.venv\Scripts\Activate.ps1
python -m alembic upgrade head
python -m pytest
cd ..
```

Android físico:

```powershell
flutter devices
flutter run -d ZF524XKRWZ
```

Critério: somente após esses comandos e o checklist funcional no aparelho serem aprovados esta versão deve receber o rótulo **HOMOLOGADA**. Código implementado e código homologado são estados diferentes.

### Pendências que não podem ser “programadas” dentro do ZIP

Estas ações exigem infraestrutura, contas, credenciais ou observação física e, portanto, permanecem como gates externos:
- URL HTTPS pública de produção;
- segredos de produção;
- chave de assinatura Android;
- publicação e aprovação na Google Play;
- política de privacidade/termos em URL pública;
- teste real de backup/restauração;
- teste de perda e retorno de internet no aparelho;
- validação visual de todas as telas em diferentes tamanhos;
- homologação com dados reais de uma fazenda.

Esses itens não representam função de código faltante; representam **homologação e publicação**.


### 2026-08-11 — Identidade BESERRA, iconografia bovina e menu único
- **Objetivo:** consolidar a identidade visual da V1 antes da homologação final.
- **Alterações:** logo BESERRA aplicada ao login e ao menu principal; símbolo de pata substituído por ícone bovino nas áreas pecuárias; Dashboard deixa de possuir Drawer próprio; `AtlasHomeShell` torna-se a única navegação oficial em desktop e mobile.
- **Arquivos centrais:** `lib/core/navigation/atlas_home_shell.dart`, `lib/core/branding/atlas_branding.dart`, `lib/features/authentication/presentation/screens/login_screen.dart`, `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, `pubspec.yaml`, `assets/branding/beserra_logo.png` e arquivos que utilizavam `Icons.pets*`.
- **Dependência:** `font_awesome_flutter: ^11.0.0` para `FontAwesomeIcons.cow`.
- **Resultado esperado:** uma única navegação; logo BESERRA visível; nenhum ícone de pata de cachorro representando bovinos.
- **Validação obrigatória:** `flutter pub get`, `dart format lib test`, `flutter analyze`, `flutter test`, depois `flutter run -d windows`.
- **Status:** IMPLEMENTADO; HOMOLOGAÇÃO VISUAL PENDENTE.

### 2026-08-11 — Limpeza final dos registros históricos remanescentes
- **Objetivo:** manter o `ATLAS_REGISTRO_MESTRE.md` como registro evolutivo único.
- **Arquivos históricos removidos da raiz:** `ATLAS_PUBSPEC_DEPENDENCIES_SPRINTS_51_60.txt`, `ENTREGA_PACOTE_28.txt`, `HISTORICO_PACOTES_ESSENCIAL.txt`, `HISTORICO_UNICO_PACOTES_ATLAS.txt`, `PACOTES_26_A_30_MANIFESTO.json` e `PUBSPEC_DEPENDENCIES_CORRIGIDAS_SPRINTS_61_70.txt`.
- **Status:** CONCLUÍDO.

## Correção definitiva da iconografia bovina — 11/08/2026

- Removida a dependência `font_awesome_flutter`, incompatível com os contratos `IconData` da versão atual do Flutter usada pelo projeto.
- Criado o font asset próprio `assets/fonts/AtlasLivestock.ttf`, contendo um glifo bovino exclusivo do Atlas.
- Criado `lib/core/branding/atlas_livestock_icons.dart`, expondo `AtlasLivestockIcons.cow` como `IconData` nativo e compatível com os componentes existentes.
- Todos os usos de `FontAwesomeIcons.cow` foram migrados para `AtlasLivestockIcons.cow`.
- A solução mantém um símbolo inequivocamente bovino sem retornar à antiga pata genérica.

### 2026-08-10 — Correção de logo BESERRA e carregamento da Fazenda
- **Objetivo:** exibir a identidade BESERRA corretamente e impedir carregamento infinito ao abrir uma fazenda.
- **Causa da logo:** `assets/branding/beserra_logo.png` existia, porém `assets/branding/` não estava declarado no `pubspec.yaml`.
- **Causa do carregamento infinito:** `FarmDetailScreen.loadDashboard()` dependia de um único `Future.wait`; uma falha em qualquer módulo interrompia o método antes de `isLoading = false`.
- **Correção:** assets de branding declarados; carregadores de lotes, piquetes, financeiro, estoque e agenda isolados; falhas parciais não bloqueiam mais a abertura da fazenda; `isLoading` é finalizado em `finally`; aviso de dados parciais incluído no painel.
- **Status:** IMPLEMENTADO — requer `flutter pub get`, `flutter analyze`, `flutter test` e validação visual no Windows.

## 12. Consolidação de navegação, persistência de Fazenda e identidade pecuária — 10/08/2026

### Problemas reproduzidos
- Edições de `animais` e `área` da Fazenda voltavam para zero após recarregar.
- Acesso a Fazendas pelo Dashboard empilhava uma nova rota fora do `AtlasHomeShell`, criando comportamento diferente do menu principal.
- Clicar no card da Fazenda abria um detalhe legado em vez de ativar a propriedade e retornar ao Dashboard oficial.
- O ícone bovino próprio não seguia a identidade visual BESERRA.
- O menu `Segurança` utilizava uma permissão que não existe no catálogo canônico do backend.

### Correções aplicadas
- `backend/app/routers/farms.py`: criação e edição agora persistem `animals` e `area`, inclusive no audit log.
- `FarmListScreen`: após criar/editar/excluir, o contexto remoto da sessão é recarregado; o card ativa a Fazenda pelo ID remoto.
- `AtlasHomeShell`: Fazenda selecionada pelo card retorna ao Dashboard oficial; rotas do Dashboard usam o mesmo menu principal.
- `DashboardScreen`: atalhos de Fazendas, Rebanho, Sanidade, Reprodução, Nutrição, Financeiro, Estoque e Relatórios navegam pelo shell em vez de abrir uma segunda árvore quando executados dentro do shell.
- `DashboardScreen`: carregamento ficou resiliente a falha isolada da Agenda e sempre encerra o estado de loading.
- `FarmListScreen`: modo `embedded` remove AppBar duplicado quando exibido dentro do shell.
- `Segurança`: permissão de navegação alinhada para `platform.read`, que é a permissão usada pela API correspondente.
- `AtlasLivestock.ttf`: glifo `cow` redesenhado a partir do traço superior da própria logo BESERRA, preservando a silhueta do Nelore como ícone do Rebanho em todos os lugares que usam `AtlasLivestockIcons.cow`.
- Adicionado teste de regressão para criação/edição/releitura de `animals` e `area` da Fazenda.

### Auditoria estática desta entrega
- 24 rotas principais encontradas no `AtlasHomeShell`; 24 labels únicos.
- Todas as permissões das rotas principais existem no catálogo canônico do backend após a correção de Segurança.
- Nenhum import `package:projeto_atlas/...` aponta para arquivo Dart inexistente.
- Backend compilado com `python -m compileall`: aprovado.
- O `pytest` não pôde ser executado no ambiente de empacotamento porque a biblioteca `python-jose` não está instalada nele; deve ser executado na `.venv` oficial do projeto.

### Organização
- Removidos 59 arquivos históricos soltos da raiz (ciclos, correções, validações, LEIA_ME e readiness antigos). O `ATLAS_REGISTRO_MESTRE.md` permanece como registro canônico único.

### Validação obrigatória no computador do projeto
```powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test

cd backend
.\.venv\Scripts\Activate.ps1
python -m pytest -q
```

**Status:** código corrigido e auditado estaticamente; homologação de execução depende dos comandos acima no ambiente oficial.

### 2026-08-11 — Correção BuildContext em Fazendas
- **Objetivo:** eliminar os três avisos `use_build_context_synchronously` em `farm_list_screen.dart`.
- **Causa:** `AtlasSessionScope.read(context)` era chamado após operações assíncronas de persistência/API.
- **Correção:** a referência ao `AtlasSessionScope` agora é capturada de forma síncrona antes do primeiro `await` de cada operação de criar, editar e excluir Fazenda; após os `await`, usa-se a referência já obtida.
- **Funções afetadas:** criar Fazenda, editar Fazenda, excluir Fazenda e recarregar contexto de sessão.
- **Regra de negócio:** inalterada.
- **Status:** CORRIGIDO; executar `dart format lib test`, `flutter analyze` e `flutter test` no ambiente Flutter do projeto.

## 13. Recuperação estrutural completa — 11/08/2026

### Objetivo
Interromper o ciclo de correções pontuais e consolidar autorização, Fazenda, persistência, rotas, migrações e diagnóstico de erros em uma única rodada de recuperação.

### Causas estruturais corrigidas
- **Escopo de Fazenda:** lista `farm_ids` vazia passa a significar consistentemente acesso irrestrito à empresa em todos os routers. Foram removidas verificações locais que interpretavam vazio como “nenhuma fazenda”.
- **Falso “Fazenda não autorizada”:** `AtlasSessionController.selectFarmById` valida no backend quando o contexto local está desatualizado e atualiza a sessão antes de selecionar.
- **Permissões ausentes:** adicionadas ao catálogo canônico `operations.read`, `operations.manage` e `sync.write`; papel legado `admin` normalizado como administrador total.
- **Administradores Flutter:** `owner`, `admin`, `companyAdministrator` e `superAdministrator` são reconhecidos de modo coerente tanto no controller quanto no modelo de sessão remota.
- **CRUD de Fazenda:** criação/edição grava `name`, `city`, `state`, `animals` e `area`; duplicidade retorna HTTP 409 em vez de 500; carteiras restritas recebem automaticamente a nova Fazenda.
- **Banco local antigo:** criada a revisão Alembic `20260811_0038` e um reparo seguro de desenvolvimento para adicionar `animals`/`area` em bancos locais antigos quando `ATLAS_AUTO_CREATE_SCHEMA=true`.
- **HTTP 500:** backend registra exceção não tratada com `request_id`; Flutter passa a exibir esse ID, facilitando diagnóstico em vez de mostrar apenas “Erro HTTP 500”.
- **Constante HTTP 422 depreciada:** todas as ocorrências foram removidas para evitar falhas causadas por `DeprecationWarning` no ambiente atual.
- **Cache de Fazendas:** a API continua sendo autoridade quando disponível; em falha transitória, o último cache local válido pode manter a interface utilizável.
- **Recarregamento após CRUD:** criar, editar e excluir Fazenda recarrega contexto e lista remota, reduzindo divergência entre UI e servidor.

### Auditoria automática incorporada
Criado `scripts/quality/atlas_full_project_audit.py`. Ele verifica:
- sintaxe Python;
- imports Dart internos inexistentes;
- permissões exigidas fora do catálogo;
- duplicidade de rotas FastAPI;
- verificações inseguras de escopo de Fazenda;
- cadeia Alembic e head único;
- constantes HTTP 422 depreciadas;
- retorno acidental da antiga pata de cachorro;
- referências remanescentes ao Font Awesome.

### Resultado desta entrega
- Sintaxe Python: **0 erros**.
- Imports Dart internos inexistentes: **0**.
- Permissões exigidas ausentes do catálogo: **0**.
- Rotas backend auditadas: **462**.
- Rotas HTTP duplicadas: **0**.
- Verificações inseguras de escopo de Fazenda: **0**.
- Revisões Alembic: **38**.
- Head Alembic: **1 (`20260811_0038`)**.
- Revisões órfãs: **0**.
- `HTTP_422_UNPROCESSABLE_ENTITY`: **0 ocorrências**.
- `Icons.pets`: **0 ocorrências**.
- Font Awesome: **0 referências**.
- Smoke test SQLAlchemy de Fazenda: **APROVADO** — criar com 120 animais/250 ha, recarregar, editar para 130 animais/275 ha e recarregar preservou os valores.
- `python -m compileall backend/app backend/tests`: **APROVADO**.

### Limite objetivo do ambiente de empacotamento
A suíte `pytest` completa não pôde ser iniciada neste ambiente porque ele não contém `python-jose`, `passlib` e `psycopg`, e o ambiente de execução não possui acesso de rede para instalar as versões fixadas no `requirements.txt`. Isso **não foi registrado como teste aprovado**. A suíte deve ser executada na `.venv` oficial do projeto no Windows.

### Regra daqui para frente
Nenhuma nova funcionalidade deve ser criada antes de o gate abaixo passar no ambiente oficial:
```powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test

cd backend
.\.venv\Scripts\Activate.ps1
python -m alembic upgrade head
python -m pytest -q
python ..\scripts\qualitytlas_full_project_audit.py
```

**Status:** RECUPERAÇÃO ESTRUTURAL IMPLEMENTADA E AUDITADA ESTATICAMENTE; HOMOLOGAÇÃO RUNTIME FINAL DEPENDE DO AMBIENTE OFICIAL.


### 2026-08-11 — Reconciliação definitiva entre schema local e Alembic
- **Problema:** o ambiente de desenvolvimento usa `Base.metadata.create_all()`, enquanto o histórico Alembic de bancos já existentes podia estar atrás do schema real. O gate então tentava recriar tabelas como `email_verification_tokens`, gerando `DuplicateTable`.
- **Correção:** criado `backend/scripts/reconcile_local_alembic.py`. Em `development/test`, ele cria apenas objetos ausentes, aplica reparos locais seguros, compara todas as tabelas e colunas dos modelos SQLAlchemy com o banco e somente após compatibilidade total executa `alembic stamp head`.
- **Produção:** staging/production não usam reconciliação nem `create_all`; continuam obrigatoriamente com `alembic upgrade head`.
- **Quality Gate:** atualizado para 9 etapas, incluindo limpeza resiliente no Windows, reconciliação local segura, verificação `current/heads`, pytest e auditoria estrutural.
- **Resultado esperado:** bancos locais previamente criados pelo ORM deixam de falhar em migrações por objetos duplicados sem apagar dados.
- **Status:** CONCLUÍDO NO CÓDIGO; executar o gate no ambiente Windows para homologação final.

## 2026-08-12 — Teste integrado real de autenticação e Fazendas

- Login real contra `POST /api/v1/auth/login` validado com as credenciais bootstrap do ambiente local.
- `TokenResponse` confirmado com `access_token`, `refresh_token`, usuário, empresa, tenant, role, permissões efetivas e escopo de fazendas.
- Adicionado `scripts/quality/test_integrated_api_farms.ps1` para validar contra o PostgreSQL real: OpenAPI, autenticação, permissões, listagem, criação, releitura, edição, nova releitura, consistência da listagem e desativação de uma fazenda temporária de QA.
- O script não modifica a Fazenda Santa Helena; cria e remove logicamente apenas um registro temporário próprio.
- Critério de aprovação: `ATLAS FAZENDAS INTEGRADO: APROVADO`.

## 2026-08-12 — Consolidação Flutter ↔ API de Fazendas

### Evidências já aprovadas no ambiente oficial
- `ATLAS FULL QUALITY GATE: APROVADO`.
- 79 testes backend aprovados na execução registrada antes desta consolidação.
- Login real em `POST /api/v1/auth/login`: **APROVADO**.
- Teste integrado de Fazendas: **ATLAS FAZENDAS INTEGRADO: APROVADO** — listagem, criação, releitura, PATCH, nova releitura, consistência da listagem e desativação.

### Correções desta consolidação
- `AtlasActiveContext` passa a reconhecer o mesmo conjunto administrativo canônico de `AtlasRemoteSession`: `owner`, `admin`, `companyAdministrator` e `superAdministrator`. Isso remove falsos `Fazenda não autorizada` para administradores empresariais.
- `AtlasActiveContext.selectFarm()` lê sempre a sessão persistida mais recente antes de validar `farm_ids`, evitando usar uma carteira antiga após CRUD.
- `AtlasRemoteFarm` agora mantém também `animals` e `area`, não descartando indicadores recebidos da API.
- `FarmStorageService` usa a resposta remota como autoridade completa quando a sessão Enterprise está ativa; valores antigos de cache não são mais misturados com dados atuais do servidor.
- `AtlasSessionController.refreshAfterFarmMutation()` atualiza sessão + carteira de Fazendas sem desmontar o `AtlasHomeShell` nem trocar toda a aplicação por tela de loading/failure.
- Criar, editar e excluir Fazenda passam a manter a resposta confirmada do servidor na interface e sincronizar o contexto em segundo momento. Uma falha secundária de refresh não faz o usuário acreditar que o POST/PATCH/DELETE falhou.
- O teste `test_integrated_api_farms.ps1` remove automaticamente somente resíduos cujo nome começa com `ATLAS QA ` antes de iniciar uma nova rodada.
- `atlas_full_project_audit.py` agora bloqueia regressões nos contratos Flutter de Fazenda: papéis administrativos, modelo remoto, autoridade da API, sincronização pós-CRUD e prefixo `/api/v1`.
- Criado `scripts/quality/run_runtime_api_validation.ps1` para repetir OpenAPI + fluxo real de Fazendas em um único comando enquanto o backend estiver rodando.

### Testes/regressões adicionados
- `test/core/session/atlas_remote_farm_test.dart`: valida `animals`, `area`, localização e estado ativo.
- `test/core/atlas_remote_session_test.dart`: valida acesso irrestrito do `companyAdministrator`.
- `test/features/farm/farm_data_test.dart`: valida que `FarmData` preserva os indicadores fornecidos pela API.

### Auditoria estática desta consolidação
- `python -m compileall backend/app backend/tests`: **APROVADO**.
- `scripts/quality/atlas_full_project_audit.py`: **ATLAS AUDIT: OK**.
- `farm_frontend_contract_errors`: **0**.
- Imports Dart internos ausentes: **0**.
- Rotas backend duplicadas: **0**.
- Escopos inseguros de Fazenda detectados: **0**.

**Status:** integração Fazenda Flutter ↔ API consolidada no código. O gate Flutter deve ser repetido no Windows após substituir esta versão, e então a homologação visual/runtime segue pelo `flutter run -d windows`.

## 2026-08-12 — Correção canônica da abertura de Fazenda

- **Sintoma:** ao clicar no card da Fazenda Santa Helena na lista de Fazendas, o Atlas ativava a propriedade, mas retornava automaticamente ao Dashboard geral.
- **Causa:** `AtlasHomeShell` injetava `onFarmSelected: (_) => _navigateToLabel('Dashboard')` em `FarmListScreen`, sobrescrevendo o fluxo canônico já existente em `openFarm()`.
- **Correção:** o menu oficial agora usa `const FarmListScreen(embedded: true)` sem callback de redirecionamento. O card continua selecionando a Fazenda na sessão e então abre `FarmDetailScreen`, a visão completa da propriedade.
- **Proteção contra regressão:** `atlas_full_project_audit.py` agora reprova qualquer retorno do redirecionamento automático `Fazenda -> Dashboard`.
- **Fluxo esperado:** Fazendas → clicar no card → selecionar fazenda ativa → abrir detalhe completo da propriedade. Dashboard permanece acessível exclusivamente pelo menu/atalhos próprios.

## 2026-08-12 — Auditoria e conexão dos módulos operacionais

Antes de criar qualquer nova funcionalidade foi realizada auditoria completa de Reprodução, Sanidade, Nutrição, Financeiro, Estoque e Agenda. A auditoria confirmou que os formulários e telas de CRUD já existiam; o problema era que o menu principal apontava para painéis genéricos somente-leitura e parte dos serviços persistia apenas em cache local.

Correções consolidadas:
- Reprodução: reutilizado `AnimalReproductionFormScreen`; criado acesso explícito **Novo evento reprodutivo** e mantida sincronização oficial `/livestock/animals/{animal_id}/reproduction`.
- Sanidade: reutilizado `AnimalHealthFormScreen`; criado acesso explícito **Novo evento sanitário** e mantida sincronização `/livestock/health`.
- Nutrição: reutilizado `NutritionPlanDialog`; planos ligados a `/livestock/nutrition/plans` com resolução de lote para `lot_id`.
- Financeiro: reutilizado `FarmFinanceFormScreen`; CRUD ligado a `/livestock/finance/v2`.
- Estoque: reutilizado `FarmInventoryFormScreen`; produtos e movimentações ligados aos endpoints oficiais `/livestock/inventory/...`; integração com Financeiro preservada.
- Agenda: reutilizados `FarmAgendaListScreen` e `FarmAgendaFormScreen`; Agenda voltou ao menu único e passou a usar `/operations/tasks`.
- `AtlasHomeShell` agora abre as telas operacionais existentes, em vez do painel genérico somente-leitura, para os módulos acima.
- O auditor `atlas_full_project_audit.py` passou a reprovar se esses formulários, rotas de menu ou conexões backend desaparecerem.

Auditoria desta entrega: `ATLAS AUDIT: OK`, 221 tabelas únicas, 490 declarações de rota sem duplicidade local, backend compilado sem erro de sintaxe.


## 2026-08-12 — Correção do Quality Gate após conexão dos módulos

O `flutter analyze` encontrou 5 problemas na primeira execução da entrega de conexão dos módulos. Todos foram corrigidos antes de prosseguir:
- `farm_inventory_list_screen.dart`: corrigida referência de `savedItem` antes da declaração; o `createItem()` agora recebe corretamente `newItem`.
- `farm_inventory_list_screen.dart`: adicionadas chaves nos fluxos `if (!mounted)` e `if (farmId.isEmpty)`.
- `farm_inventory_storage_service.dart`: normalizados os fluxos condicionais de retorno para blocos com chaves, eliminando `curly_braces_in_flow_control_structures`.
- `nutrition_storage_service.dart`: normalizados `continue` e retornos condicionais para blocos com chaves, eliminando a mesma classe de lint.
- Auditoria estrutural repetida após a correção: `ATLAS AUDIT: OK`.
- `python -m compileall backend/app backend/tests`: aprovado.

**Status:** correções de análise estática aplicadas; o `run_full_quality_gate.ps1` deve ser executado novamente no Windows para validar Flutter analyze/test e backend na mesma rodada.

## 2026-08-12 — Correção final do Quality Gate após conexão dos módulos

- Corrigido `farm_finance_list_screen.dart`: `savedRecord` agora recebe `newRecord` na criação remota, eliminando `referenced_before_declaration`.
- Corrigidos fluxos condicionais sem chaves em Financeiro e Agenda, incluindo o caso reportado em `farm_agenda_storage_service.dart`.
- Revisados os pontos equivalentes no fluxo Financeiro para evitar nova interrupção do `flutter analyze` pelo mesmo lint.
- Nenhuma funcionalidade nova foi criada nesta correção; foram apenas saneados os problemas encontrados pelo gate na integração já existente.
## 2026-08-12 — Correção de persistência na edição da Agenda

- Corrigido o fluxo `Agenda -> Editar compromisso -> Salvar`.
- A categoria (`source_type`) agora também é persistida no `PATCH /operations/tasks/{task_id}`.
- O backend `OperationalTaskUpdateRequest` passou a aceitar `source_type`.
- Responsável e observações deixaram de ser concatenados repetidamente no campo `description`.
- A leitura da Agenda agora separa novamente `Responsável:` das observações, impedindo duplicações após editar/reabrir.
- O auditor estrutural passou a reprovar se esses contratos de persistência desaparecerem.


## Agenda — persistência verificada + calendário semanal/mensal — 13/08/2026

- Corrigido o fluxo de criação e edição da Agenda para não considerar uma operação concluída apenas pela resposta inicial do POST/PATCH.
- Após criar ou editar um compromisso, o Flutter executa uma nova leitura de `/operations/tasks` e somente confirma sucesso quando o registro reaparece com o ID persistido no backend.
- Falhas de criação/edição agora são exibidas ao usuário em vez de gerar falsa confirmação visual.
- `FarmAgendaStorageService.updateTask` passou a receber explicitamente `farmId`, garantindo que a verificação pós-PATCH seja feita no escopo correto da fazenda.
- Mantida a serialização compatível de responsável e observações para tarefas existentes.
- Adicionadas três visualizações na Agenda: Lista, Semana e Mês.
- A Semana mostra os sete dias e os compromissos de cada dia; o Mês mostra uma grade de 42 células com tarefas por data.
- Os compromissos do calendário são os mesmos registros carregados da API oficial, sem criar uma segunda agenda ou armazenamento paralelo.
- O clique em uma tarefa no calendário abre o mesmo formulário de edição já existente.
- Auditoria estrutural executada: ATLAS AUDIT OK; backend compileall OK; imports internos e contratos operacionais sem pendências.
## 2026-08-13 — Limpeza final da Agenda

- Removido o método privado legado `_upsertLocal` de `farm_agenda_storage_service.dart`.
- O método havia ficado sem referências após a migração da Agenda para persistência verificada no backend.
- A remoção elimina o aviso `unused_element` do `flutter analyze` sem alterar o fluxo funcional atual.
- Permanecem como fonte oficial da Agenda os endpoints de `/operations/tasks`, com confirmação pós-`POST/PATCH` e visualizações Lista / Semana / Mês.

## 2026-08-13 — Recuperação da Central do Animal

- **Sintoma:** ao abrir `Central do animal`, a rota era exibida, porém a tela permanecia indefinidamente em carregamento.
- **Causa raiz:** `AnimalDetailScreen.loadDashboard()` aguardava oito fontes dentro de um único `Future.wait` sem isolamento por fonte. Uma única chamada lenta/indisponível — especialmente a Timeline Enterprise — bloqueava a renderização completa. Além disso, não havia garantia estrutural de encerramento de `isLoading` em qualquer exceção inesperada.
- **Correção:** cada fonte passou a ser carregada por `_safeLoad<T>`, com timeout individual, captura de erro e fallback para lista vazia.
- Timeline Enterprise possui timeout mais curto de 6 segundos; as demais fontes usam 8 segundos.
- `Sanidade` agora recebe o `farmId` real da Fazenda ativa (`farm.id ?? ''`), mantendo o escopo correto da consulta remota.
- O `loadDashboard()` agora possui `try/catch/finally`; `isLoading` é sempre encerrado no `finally`.
- A Central deixou de bloquear toda a interface com um spinner central. O cabeçalho, navegação e seções são renderizados imediatamente com os dados disponíveis, usando `LinearProgressIndicator` apenas enquanto atualiza.
- Se uma fonte falhar, a tela continua utilizável e exibe `Central carregada parcialmente`, listando as fontes indisponíveis e oferecendo `Tentar novamente`.
- O auditor `atlas_full_project_audit.py` ganhou o contrato `animal_central_contract_errors` e reprova regressões que removam isolamento, timeout, `finally`, carregamento não bloqueante, aviso parcial ou propagação do `farmId`.
- Validações executadas nesta entrega: `ATLAS AUDIT: OK`; `python -m compileall backend/app backend/tests`: OK; 221 tabelas únicas; 490 declarações de rota sem duplicidade local; arquitetura consolidada: OK.

## 2026-08-13 — Marco Núcleo Pecuário: Rebanho resiliente e leitura canônica

- Auditoria do núcleo Rebanho/Central do Animal concluída antes de criar novas funcionalidades.
- Corrigido N+1 no Rebanho: antes havia uma chamada de animais por lote; agora há uma leitura de lotes e uma leitura de todos os animais da fazenda.
- Animais sem lote ou vinculados a lote fora da carteira ativa deixam de desaparecer da visão geral.
- O Rebanho agora possui timeout e isolamento de fontes, encerramento garantido do loading e aviso de carregamento parcial.
- A área oficial da Fazenda é preservada ao abrir a Central do Animal a partir do Rebanho.
- O auditor estrutural passou a reprovar regressões de N+1, omissão de animais sem lote, perda de área da fazenda e loading sem proteção.

## Marco 2 — Gestão da Fazenda consolidada — 13/08/2026

- Auditoria completa de Nutrição, Piquetes, Estoque e Financeiro antes de criar novos recursos.
- Nutrição: cache separado por fazenda; ingredientes e estado de integração com estoque persistidos oficialmente no backend.
- Nova migração `20260813_0039_nutrition_inventory_flags.py` para `stock_integration_enabled`, `inventory_deducted` e `inventory_deduction_cost`.
- Integração Nutrição → Estoque deixa de alterar somente cache local e passa a registrar movimentações oficiais com referência ao plano nutricional.
- Ordem transacional corrigida: dieta é criada primeiro; baixa de estoque ocorre depois; estado da integração é persistido e relido do servidor.
- Estoque: criação, edição e movimentação são confirmadas por nova leitura da fonte oficial.
- Financeiro: lote/animal digitados são resolvidos para IDs oficiais; recarga volta a apresentar nomes/identificadores humanos.
- Integração Estoque → Financeiro passou a usar `reference_type=inventory_movement` e `reference_id`, com prevenção de duplicidade.
- Piquetes: criação, edição e exclusão são verificadas por nova leitura do backend.
- Nutrição, Piquetes, Estoque e Financeiro encerram loading mesmo em falhas/timeout.
- Adicionado `backend/tests/test_marco2_management_crud.py` cobrindo CRUD integrado dos quatro domínios.
- Auditor estrutural ampliado com `management_core_contract_errors`.

## Marco 3 — Agenda e integrações consolidadas — 13/08/2026

- Auditados os fluxos reais entre Reprodução, Sanidade, Agenda, Estoque e Financeiro antes de criar novas telas.
- Corrigida Reprodução: edição de evento sincronizado deixa de gerar novo `POST`; agora usa `PATCH /livestock/animals/{animal_id}/reproduction/{event_id}` com releitura de confirmação.
- Corrigida Reprodução: exclusão deixa de remover apenas o cache; agora usa `DELETE` remoto, confirma a ausência e recalcula o estado reprodutivo do animal.
- Reprodução → Agenda: eventos com `expected_date` criam/atualizam uma única tarefa com `source_type=reproduction_event` e `source_id` oficial; retirar a data cancela a tarefa vinculada.
- Agenda → Reprodução: alteração da data de uma tarefa integrada atualiza `expected_date` do evento de origem sem perder o vínculo técnico.
- Corrigida Sanidade: edição/exclusão deixam de ser apenas locais ou de gerar novos registros; passam por `PATCH/DELETE` remoto com releitura.
- Removida a autoridade paralela `AnimalHealthInventoryService`: a baixa sanitária passa a ocorrer exclusivamente no backend oficial.
- Sanidade → Estoque → Financeiro permanece transacional no backend: uma aplicação com produto de estoque gera uma única saída `health_event` e um único lançamento financeiro vinculado.
- Sanidade → Agenda: `next_date` cria/atualiza tarefa com `source_type=health_event` e `source_id` oficial.
- Agenda → Sanidade: editar a data da tarefa integrada atualiza `next_date` do evento sanitário.
- Exclusão sanitária agora compensa efeitos: devolve ao estoque a quantidade consumida por movimento `health_event_reversal`, remove o financeiro vinculado e remove a tarefa de Agenda correspondente.
- A Agenda passou a preservar `sourceType/sourceId` separadamente da categoria amigável exibida ao usuário, impedindo que uma edição rompa a integração.
- Adicionado `backend/tests/test_marco3_agenda_integrations.py`, cobrindo criação, edição, sincronização bidirecional, ausência de duplicidade e exclusão compensada.
- `atlas_full_project_audit.py` ganhou `marco3_integration_contract_errors` e reprova regressões desses contratos.
- Validação estrutural desta entrega: `ATLAS AUDIT: OK`; sintaxe Python sem erros; imports Dart internos ausentes: 0; rotas duplicadas: 0; head Alembic permanece `20260813_0039`.
- O pytest do Marco 3 não pôde ser executado neste ambiente Linux porque `python-jose` (`jose`) não está instalado; deve ser executado pela `.venv` Windows no `run_full_quality_gate.ps1`.

## 2026-08-14 — Marco 4D: fechamento funcional da V1

- Criado `scripts/quality/atlas_marco4_v1_functional_closure.py`.
- Quality Gate ampliado para 13 etapas.
- 20 contratos funcionais V1 auditados; 0 divergências inesperadas.
- 6 regressões essenciais tornadas obrigatórias no contrato do Marco 4D.
- Removido import residual não utilizado em `farm_detail_screen.dart` após desacoplamento da persistência preditiva local.
- Fotos e Documentos foram formalizados como bloqueadores de produção do Marco 5 por ainda dependerem de armazenamento/referência local.
- Abertura de documentos via Windows e entrada manual de caminho de foto foram formalizadas como bloqueadores Android do Marco 6.
- Criado `ATLAS_PRODUCTION_BLOCKERS.json` para impedir que esses débitos sejam esquecidos ou declarados resolvidos sem implementação real.
- Marco 4 encerrado como `closed_with_explicit_downstream_blockers`; próximo marco oficial: Marco 5 — Qualidade e Segurança de Produção.

## 2026-08-15 — Correção definitiva da autenticação PostgreSQL local

Auditoria do erro `password authentication failed for user "atlas"` identificou volume PostgreSQL persistente com credencial histórica. O ambiente local foi endurecido com reconciliação idempotente da role, autenticação real pelo SQLAlchemy do backend, inicializador único do backend e contrato estático de infraestrutura integrado ao Quality Gate. Nenhum volume é apagado para corrigir credenciais.


## 2026-08-15 — Correção definitiva do falso negativo de porta PostgreSQL

- Causa confirmada: `docker compose port db 5432` + `$LASTEXITCODE` em pipeline PowerShell produzia falso negativo no Windows mesmo com `HostConfig.PortBindings` correto.
- `start_local_infrastructure.ps1` passou a inspecionar diretamente `docker inspect -> HostConfig.PortBindings`.
- A disponibilidade externa é validada por socket TCP `.NET` em `127.0.0.1:5432`.
- Se o binding estiver ausente ou stale, somente o container `db` é recriado com `--force-recreate --no-deps`, preservando o volume PostgreSQL.
- Depois da porta, a autenticação real continua obrigatória via SQLAlchemy usando `backend/.env`.
- O auditor de infraestrutura agora bloqueia a reintrodução da checagem frágil anterior.


## Correção definitiva do bootstrap Python do validador local — 2026-08-15
`backend/scripts/check_local_database_connection.py` agora adiciona explicitamente
a raiz `backend/` ao `sys.path` antes de importar `app.config`. Isso elimina
`ModuleNotFoundError: No module named 'app'` quando o arquivo é executado
diretamente pelo PowerShell. Foi adicionado teste de regressão dedicado.


## Reconciliação definitiva de schema local antigo — 2026-08-15
- Bancos locais previamente `stamp head` podiam manter colunas ausentes porque
  `create_all()` não altera tabelas existentes.
- `backend/app/database.py` agora adiciona genericamente apenas colunas ausentes
  em development/test, preservando linhas existentes.
- Colunas NOT NULL com default escalar recebem default temporário para backfill;
  no PostgreSQL esse default temporário é removido em seguida.
- Colunas obrigatórias sem default seguro em tabelas populadas são criadas
  nullable apenas no reparo local para não inventar dados de domínio.
- `reconcile_local_alembic.py` só executa `stamp head` após revalidar todas as
  tabelas e colunas.
- Adicionado teste de regressão para banco legado e idempotência.


## Bootstrap automático da .venv — 2026-08-15
- Extrações limpas não dependem mais de copiar a `.venv` antiga.
- Criado `scripts/dev/ensure_backend_venv.ps1`.
- O bootstrap detecta `py -3` ou `python`, cria `backend/.venv`, valida Python 3.11+,
  instala `requirements-dev.txt`, mantém fingerprint SHA-256 dos requirements e
  executa smoke test dos imports críticos.
- `start_backend.ps1` e `run_full_quality_gate.ps1` utilizam o mesmo bootstrap.
- Se requirements mudarem ou a .venv ficar incompleta, as dependências são
  reinstaladas automaticamente.


## Marco 4E — Baseline Estável: mudança de método — 2026-08-15
- O desenvolvimento deixa de ser reativo a erros individuais.
- A baseline passa a ser validada como conjunto antes de novos marcos.
- `uuid` já estava corretamente declarado no pubspec; os erros no editor eram
  consequência de `flutter pub get` ainda não ter concluído na pasta limpa.
- Python multilinha embutido em PowerShell foi proibido pela auditoria.
- Criado `backend/scripts/check_python_environment.py`.
- Criado `scripts/dev/bootstrap_project.ps1` para preparar `.venv` e Flutter.
- Criado `scripts/quality/atlas_baseline_static_audit.py`.
- O Quality Gate começa agora por ambiente Python + baseline estática +
  infraestrutura, antes de Flutter/Alembic/testes.
- O Marco 5 permanece bloqueado até o Quality Gate completo passar em uma
  extração limpa.


## Marco 4E — parser PowerShell protegido — 2026-08-15
- Corrigido `Get-AtlasEnvironment` no Quality Gate.
- Auditados os 40 scripts PowerShell da árvore consolidada.
- Criado `atlas_powershell_static_audit.py`.
- A baseline bloqueia métodos iniciados em nova linha sem continuação,
  Python multiline embutido em PowerShell e delimitadores desbalanceados.
- Quality Gate agora possui 18 etapas.

## Marco 4E — baseline preditiva v8d — 2026-08-15
- Preflight nativo PowerShell obrigatório.
- Auditoria preditiva de riscos e manifesto anti-resíduos.
- PS1 normalizados para UTF-8 BOM + CRLF.
- Quality Gate separado em wrapper + core.
- Contrato de infraestrutura atualizado para wrapper -> preflight -> core -> infraestrutura.


## Marco 5D — Fotos e Documentos remotos — 2026-08-15
- Criada tabela `animal_media` e migração 0040.
- Arquivos persistidos no servidor em volume dedicado.
- Upload/download protegidos por tenant, empresa, fazenda e animal.
- Flutter passou a usar backend como autoridade e cache temporário/local apenas
  para visualização offline.
- ATT-001 e ATT-002 resolvidos.


## Marco 5 — concluído tecnicamente — 2026-08-15
- 5E: estoque com row lock e referências idempotentes com advisory locks.
- 5F: rate limit distribuído via Redis; produção exige Redis compartilhado.
- 5G: backup completo banco+anexos e restore temporário verificável.
- 5H: gate final exige zero bloqueadores técnicos no inventário.
- ATT-003 permanece explicitamente no Marco 6/Android.


## Marco 6 — Android V1 — 2026-08-15
- package `br.com.projetoatlas.app`, versão 1.0.0+6.
- API 36, minSdk 24, JDK 17.
- signing release obrigatório.
- AAB/APK automatizados.
- branding Beserra Android.
- Photo Picker/câmera/file selector/FileProvider.
- endpoint production HTTPS imutável.
- Caddy/TLS + Alembic antes da API.
- gate exige Android real e faixa Play.

---

## Registro de alteração — 2026-08-24 — Pós-V21 Pacote 9C

**Objetivo:** tornar a implantação inicial do Atlas persistente e acompanhável pela Central da Consultoria, além de eliminar o falso negativo do gate de staging do 9B.

**Baseline de entrada:** Pacote 9B publicado em produção; migration 0045 confirmada.

**Arquivos funcionais principais:**
- `backend/app/routers/saas_growth.py`;
- `lib/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart`;
- `lib/features/consultancy_client/data/services/atlas_client_onboarding_service.dart`;
- `lib/features/consultancy_client/presentation/widgets/atlas_client_onboarding_card.dart`;
- `lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart`.

**Funções afetadas:** leitura e gravação do onboarding da empresa, visualização do progresso na Central da Consultoria e gestão dos cinco passos iniciais de implantação.

**Backend/endpoints:**
- `GET /saas-growth/onboarding`;
- `POST /saas-growth/onboarding`;
- `GET /saas-growth/onboarding/deployment-readiness`.

**Persistência:** reutiliza `onboarding_progress`; não cria migration nova.

**Permissões:** `farms.read` para leitura e `farms.update` para atualização.

**Qualidade e prevenção:** gate estrutural específico do 9C, teste de contrato Flutter, checker pós-deploy e correção do checker de staging do 9B para reconhecer corretamente estado pós-commit.

**Rollback:** restaurar os arquivos listados para a baseline 9B. Não há rollback de schema porque não há migration nova.

**Status da entrega:** implementação concluída no pacote; homologação Windows e publicação em produção devem seguir os gates do 9C.


## Registro de alteração — 2026-08-24 — Pós-V21 Pacote 9D

- Implantação Atlas deixa de aceitar conclusão fictícia dos passos operacionais.
- Progresso passa a ser escopado pela fazenda aberta na Central da Consultoria.
- Fazenda/contexto, rebanho inicial, contato veterinário e rotina/agenda são derivados automaticamente das fontes oficiais.
- Apenas treinamento inicial permanece como confirmação manual persistida.
- Backend bloqueia a autoridade manual sobre passos automáticos e devolve evidências explicáveis por etapa.
- Nenhuma migration nova: `onboarding_progress` continua armazenando somente o estado manual necessário.

## Registro de alteração — 2026-08-24 — Pós-V21 Pacote 9E

- Corrige o último ponto ainda company-scoped da implantação: a confirmação manual de treinamento passa a ser isolada por fazenda.
- Migration `20260824_0046` adiciona `farm_id` a `onboarding_progress`, remove unicidade exclusiva por empresa e cria unicidade `company_id + farm_id`.
- Estado legado é preservado e expandido para as fazendas existentes; empresa sem fazenda mantém fallback legado até o primeiro vínculo real.
- `GET/POST /saas-growth/onboarding` passam a selecionar o registro por empresa + fazenda.
- Evidências automáticas do 9D permanecem calculadas pelos módulos oficiais e somente `initial_training` continua manual.
- Readiness de produção passa a comprovar a coluna `farm_id` e a migration `0046`.


## Pós-V21 — Macropacote 10A: Ciclo Operacional Mensurável
- Linha de base e resultado por ação consultiva.
- Vínculo com registro operacional de origem.
- Histórico longitudinal e eficácia por fazenda/área.
- Migration 0049.

## Pós-V21 — Macropacote 10B: Inteligência e Integridade do Produto (2026-08-25)

- Inteligência operacional consolidada em uma fonte canônica compartilhada por Dashboard, Central de Alertas e Central da Consultoria.
- Corrigido contrato de posição das prioridades (`position`, com compatibilidade `priority`).
- Frontend passa a rejeitar resumo/alertas de fazenda divergente e versões contratuais incompatíveis.
- Auditoria transversal 10B cobre 12 módulos essenciais, 541 rotas backend, sintaxe Python, contratos existentes, autoridade remota/cache e ausência de chamadas diretas fora da fonte canônica.
- `atlas_full_project_audit.py` permanece aprovado e `atlas_predictive_risk_audit.py` foi promovido para a baseline `post-v21-macro10b-integrity`, eliminando o falso bloqueio da antiga baseline V18.
- Matriz de integridade gerada em CSV + JSON dentro de `docs/`.
- Nenhuma migration nova: banco permanece na revisão `0049`.

## Pós-V21 — Macropacote 10C — Rastreabilidade, Dados e UX (2026-08-25)

- Central do Animal passa a expor cobertura de rastreabilidade baseada em identificação, lote, pesagens, sanidade, reprodução, movimentações, timeline enterprise, fotos e documentos.
- Caches legados usados pela Central do Animal são normalizados por `AtlasTextNormalizer` antes de reconstruir os modelos locais.
- Migration `20260825_0050_data_quality_utf8_traceability.py` executa novo saneamento global de colunas textuais e, agora, também JSON/JSONB, registrando prova persistente em `atlas_data_quality_state`.
- A normalização UTF-8 continua ativa na entrada/saída Flutter e na borda `before_flush` do SQLAlchemy, evitando reintrodução por operações ORM.
- `AtlasUiText` permanece como vocabulário canônico para categorias técnicas (`health`, `nutrition`, `maintenance`, `inventory`, `reproduction`, `livestock`).
- Gate 10C bloqueia mojibake em superfícies de produção, rótulos técnicos literais na UI e regressões de rastreabilidade/normalização.
- A baseline Alembic avança de `0049` para `0050`.
