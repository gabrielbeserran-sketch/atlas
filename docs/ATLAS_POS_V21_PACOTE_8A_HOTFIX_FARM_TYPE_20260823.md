# Hotfix 8A — fronteira de tipo da fazenda

## Falha observada

`atlas_precision_hub_screen.dart` recebeu `AtlasRemoteFarm` da sessão oficial,
mas `AtlasSecurityCameraCard` exigia `FarmData`.

Isso causava:

`The argument type 'AtlasRemoteFarm' can't be assigned to the parameter type 'FarmData'.`

## Causa

O novo card da câmera foi acoplado ao modelo errado de fazenda.

O Precision Hub pertence à sessão remota e usa `AtlasRemoteFarm`.
O card da câmera não precisava de cidade, estado, área, número de animais ou
qualquer outro dado de `FarmData`: precisava somente do identificador oficial
da fazenda.

## Correção estrutural

O `AtlasSecurityCameraCard` não recebe mais objeto de fazenda.

Contrato novo:

- `farmId: String`
- `canManage: bool`

O Precision Hub passa:

`farmId: farm.id`

Com isso o recurso deixa de depender tanto de `FarmData` quanto de
`AtlasRemoteFarm`.

## Prevenção

Foi criado:

`tools/atlas_flutter_farm_model_boundary_gate.py`

O gate procura montagens de widgets em superfícies baseadas em sessão remota e
bloqueia widgets filhos que voltem a exigir `FarmData` de forma incompatível.

O gate 8A também passou a exigir a fronteira primitiva `farmId`.

## Validação executada

- Python compile: 10/10
- Farm Model Boundary Gate: OK
- Pacote 8A Gate: APROVADO
- cadeia estática anterior: 27/27
- Dart structural guard: 5/5
- nenhum acoplamento `FarmData` permanece no card da câmera

Backend, migration 0043 e contrato de câmera/WhatsApp foram preservados.
