# Hotfix 6D-D — contrato de fazenda ativa

A implementação 6D-D tornou o estado sem fazenda acionável, substituindo
`const _AtlasSelectFarmMessage()` por `_AtlasSelectFarmMessage` com callback
para o seletor oficial de fazendas.

O teste legado `v21_critical_flows_contract_test.dart` ainda verificava
literalmente o construtor antigo. A funcionalidade estava correta; o contrato
de regressão estava desatualizado.

Correções:
- contrato V21 atualizado para exigir o novo estado acionável;
- gate 6D-D agora procura em todos os testes qualquer referência ao construtor
  passivo antigo e falha antes da suíte Flutter;
- regressão estática completa reexecutada e aprovada.
