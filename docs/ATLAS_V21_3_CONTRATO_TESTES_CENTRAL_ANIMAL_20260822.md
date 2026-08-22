# Atlas V21.3 — contrato de testes da Central do Animal

A falha do `flutter test` vinha de um teste antigo, não da navegação atual.

A V20.8 consolidou três grupos visíveis:
- Acesso rápido
- Mais informações
- Hoje e pendências

O teste anterior ainda exigia exatamente duas `NavigationModuleRow`.

Nesta versão:
- o teste foi atualizado para três grupos;
- os três títulos são validados;
- a primeira camada operacional é validada;
- o catálogo avançado continua obrigatório;
- todos os testes de `test/features/animal` foram varridos para contratos legados;
- o novo gate `atlas_v21_3_test_contract_gate.py` impede nova divergência entre código e teste.

A V21.3 permanece candidata até o gate completo passar no Windows.
