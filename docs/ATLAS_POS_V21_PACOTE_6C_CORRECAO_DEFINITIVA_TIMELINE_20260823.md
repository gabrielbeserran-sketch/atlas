# Atlas Pós-V21 — Correção definitiva do teste da Timeline

## Causa real

O teste de resiliência da Timeline ainda continha uma verificação de texto de
`debugPrint`. Esse texto não faz parte do contrato funcional da Timeline e pode
mudar sem qualquer alteração de rede, timeout, fallback ou serviço.

No incidente, todas as verificações funcionais anteriores passaram e somente a
asserção da linha de log falhou.

## Correção

O teste agora valida exclusivamente:
- identificador técnico estável;
- `AnimalEnterpriseTimelineService`;
- `loadTimeline(animal.id)`;
- ausência de timeout local de 6 e 8 segundos;
- ausência de `.timeout()` no wrapper e no serviço;
- `return await loader();`;
- fallback imutável.

Nenhuma frase específica de `debugPrint` é exigida.

## Prevenção adicional

Foi feita uma varredura em toda a suíte procurando `source.contains()` acoplado
diretamente a textos de log. Resultado: 0 ocorrências.

O gate `atlas_post_v21_package6c_timeline_contract_gate.py` agora protege
15 contratos e inclui explicitamente a regra de que o teste não pode exigir o
texto do log da Timeline.

## Regressão estática

- Timeline contract: 15/15
- Capability ownership: OK, 98 componentes / 69 raízes / 0 órfãos
- Arquitetura 6B: OK
- Navegação 6A: 63/63
- Pacote 5: 68/68
- Pacote 4: 36/36
- Pacote 3 completo: 43/43
- Pacote 3: 30/30
- Pacote 2: 44/44
- Pacote 1: 27/27
- Baseline Static Audit: OK
- Full Project Audit: OK
