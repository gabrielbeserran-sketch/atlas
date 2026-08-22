# Atlas V21.5 — correção do parser PowerShell

## Falha real
O smoke V21.4 continha strings como:

`"$Operation: nova tentativa..."`

e

`"$Operation: falha transitória/cold start..."`

No PowerShell, `:` imediatamente após um nome interpolado pode ser interpretado como
qualificador/drive de variável. Como `Operation` não é um drive/escopo, o parser falhava
com `InvalidVariableReferenceWithDrive` antes de executar o smoke.

## Correção
As ocorrências foram substituídas por:

`"${Operation}: nova tentativa..."`

`"${Operation}: falha transitória/cold start..."`

## Prevenção
Foi criado `tools/atlas_v21_5_powershell_hygiene_gate.py`.

O gate:
- valida os dois scripts críticos da homologação;
- aceita qualificadores válidos como `$env:` e `$script:`;
- bloqueia referências ambíguas como `$Operation:`;
- exige explicitamente as duas interpolações seguras acima.

O gate de resiliência V21.4 também passou a exigir a forma segura.
