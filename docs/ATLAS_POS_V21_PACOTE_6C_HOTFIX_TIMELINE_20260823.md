# Atlas Pós-V21 — Pacote 6C Hotfix Timeline

## Incidente corrigido

O teste `animal_central_timeline_production_resilience_test.dart` falhava porque
estava acoplado ao literal `label: 'Timeline Enterprise'`.

Esse literal era usado como evidência indireta de um comportamento que o teste
realmente precisava proteger:
- uso de `AnimalEnterpriseTimelineService`;
- carregamento por `loadTimeline(animal.id)`;
- ausência de timeout local;
- fallback em falhas transitórias.

Uma alteração de nomenclatura poderia, portanto, derrubar a homologação mesmo
sem regressão de rede.

## Correção

Foi criado um identificador técnico estável e privado:

`_enterpriseTimelineLoadLabel = 'Timeline Enterprise'`

O callsite e o log usam esse identificador. O texto visível da interface pode
continuar simples, sem alterar o contrato técnico.

O teste foi reescrito para verificar o comportamento real:
- serviço Enterprise oficial;
- label técnico compartilhado;
- `return await loader();`;
- ausência de `.timeout`;
- fallback imutável.

## Prevenção

Novo gate:
`tools/atlas_post_v21_package6c_timeline_contract_gate.py`

Ele protege 14 contratos e bloqueia:
- retorno dos timeouts locais de 6 ou 8 segundos;
- `.timeout()` direto ou no wrapper;
- remoção do serviço oficial;
- remoção do fallback;
- divergência entre teste e implementação;
- novo acoplamento da regra de rede ao texto da interface.

O gate 6B também foi atualizado para verificar o contrato sem depender de uma
string literal no callsite.

## Resultado estático

- Timeline 6C: 14/14
- Arquitetura 6B: aprovado
- Navegação 6A: 63/63
- Pacote 5: 68/68
- Pacote 4: 36/36
- Pacote 3 completo: 43/43
- Pacote 3: 30/30
- Pacote 2: 44/44
- Pacote 1: 27/27
- Baseline audit: OK
- Full project audit: OK
