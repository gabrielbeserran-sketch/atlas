# Atlas V19.5 — Navegação operacional direta

Data: 21/08/2026

## Problema corrigido
A V19.4 ainda mantinha uma tela-resumo (`AtlasLivestockModuleScreen`) entre as entradas de navegação e as centrais operacionais reais. Isso duplicava a experiência: Menu/Fazenda/Dashboard -> resumo -> central CRUD.

Na Central do Animal, os atalhos Sanidade+, Reprodução+, Pesagens+, Nutrição e Executivo também selecionavam uma seção intermediária que apenas oferecia outro botão "Abrir ...".

## Regra canônica V19.5
Uma ação de navegação deve chegar diretamente à tela que executa o trabalho.

- Sanidade -> `HealthOverviewScreen(farm: farm)`
- Reprodução -> `ReproductionOverviewScreen(farm: farm)`
- Nutrição -> `NutritionOverviewScreen(farm: farm)`
- Financeiro -> `FarmFinanceListScreen(farm: farm)`
- Estoque -> `FarmInventoryListScreen(farm: farm)`

Essa regra foi aplicada a:
- menu lateral desktop;
- drawer/mobile;
- Dashboard e seus atalhos;
- detalhe da Fazenda;
- Central do Animal para Sanidade+, Reprodução+, Pesagens+, Nutrição e Executivo.

A antiga `AtlasLivestockModuleScreen` foi preservada como componente técnico/compatibilidade e não é mais autoridade de navegação principal.

## Segurança e persistência
Nenhum endpoint, modelo de banco ou regra transacional foi recriado. As centrais operacionais continuam usando os serviços e contratos remotos existentes. O escopo da fazenda ativa é propagado para as centrais farm-scoped.

## Gates
- V19 canonical navigation: 30/30
- V19.2 CRUD: 30/30
- V19.3 CRUD visível: 38/38
- V19.4 área de ações: 14/14
- V19.5 navegação direta: 37/37
- Atlas Full Project Audit: OK
- Python compileall: OK

## Gate local obrigatório
No ambiente Windows do projeto:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows --debug
```
