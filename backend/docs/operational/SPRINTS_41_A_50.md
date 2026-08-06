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

```powershell
python scripts/operational/run_core_validation.py --company-id COMPANY_ID --farm-id FARM_ID --fail-on-issues
```

## Testes

```powershell
python -m pytest -q tests/test_core_livestock_validation.py
```

O validador não altera dados. Ele foi criado para localizar inconsistências antes de operações de piloto, importações, sincronizações ou análises da IA.
