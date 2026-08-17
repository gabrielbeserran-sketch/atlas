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
```powershell
dart format lib
flutter analyze
flutter test
```

## Validação no Android
Com backend ativo e o Moto G75 5G conectado:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android\09_prepare_first_android_run.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\android\05_run_on_android.ps1
```
