# Auditoria de navegação — 05/09/2026

## Fonte de verdade

`lib/core/navigation/atlas_home_shell.dart` é a navegação utilizada pelo
aplicativo autenticado. A barra lateral e o drawer compacto são montados a
partir de `AtlasHomeShell.routes` e filtrados pelas permissões da sessão.

`lib/core/presentation/layouts/atlas_main_layout.dart` contém uma navegação
legada sem consumidores no diretório `lib/`. Ela não define o menu exibido
no Atlas e não deve ser tomada como referência para a reorganização.

## Menu canônico atual

| Grupo exibido | Rota interna | Rótulo visível | Escopo |
| --- | --- | --- | --- |
| Hoje | Dashboard | Início | global |
| Hoje | Realizar manejo | Realizar manejo | fazenda |
| Hoje | Agenda | Agenda | fazenda |
| Hoje | Dr. Beserra | Dr. Beserra | fazenda |
| Animais | Rebanho | Rebanho | fazenda |
| Animais | Sanidade | Sanidade | fazenda |
| Animais | Reprodução | Reprodução | fazenda |
| Fazenda | Fazendas | Fazendas | global |
| Fazenda | Nutrição | Nutrição | fazenda |
| Fazenda | Estoque | Estoque | fazenda |
| Fazenda | Campo | Campo | fazenda |
| Gestão | Financeiro | Financeiro | fazenda |
| Gestão | Inteligência | Análises | fazenda |
| Gestão | Relatórios | Relatórios | global |
| Apoio | Offline | Sem internet | global |
| Apoio | Consultoria | Consultoria | fazenda |

O bloqueio de escopo por fazenda é centralizado em
`_handleRouteSelection`; nenhum módulo de fazenda deve perder esse guarda
durante a reorganização.

## Conexões que exigem preservação

- `DashboardScreen` navega por rótulo via `_navigateToLabel`.
- `Financeiro` abre `FinanceOverviewScreen`; também existem entradas diretas
  para a lista financeira legada dentro de fluxos de fazenda. A reorganização
  deve manter as duas entradas até sua reconciliação explícita.
- `Inteligência` abre `AtlasIntelligenceCenterScreen` e depende de fazenda
  ativa.
- Rebanho, Sanidade, Reprodução, Nutrição, Estoque, Campo, Agenda, Manejo e
  Consultoria dependem de fazenda ativa.
- A visibilidade continua subordinada às permissões da sessão, não apenas à
  organização visual.

## Regra de mudança

Nenhuma rota será apagada por aparência. Cada item comparado à versão Android
receberá uma destas decisões: **manter**, **mover**, **renomear**,
**ocultar por permissão** ou **descontinuar**. Uma descontinuação exige a
lista de consumidores, rota substituta e teste de navegação antes de remover
o código.

## Gate pendente

Em 05/09/2026, `flutter devices` detectou somente Windows, Chrome e Edge. O
Android precisa ser exposto por depuração USB para que a hierarquia da versão
mais recente seja extraída e comparada ao quadro acima. Até esse confronto,
esta auditoria impede que o menu seja refeito por suposição.
