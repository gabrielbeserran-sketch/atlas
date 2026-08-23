# Hotfix 7F — contrato de matrizes

A implementação estava correta: quando não existem animais classificados como
Matriz/Matrizes, o Dr. Beserra informa que não vai inferir quais fêmeas entram
no resumo.

O teste falhava porque procurava uma frase contínua no texto-fonte, enquanto
o Dart a compunha com dois literais adjacentes. Em runtime os literais formam
uma única mensagem; no arquivo-fonte existe uma quebra entre eles.

Correção:
- o teste agora valida os dois fragmentos semânticos reais separadamente;
- a implementação não foi enfraquecida;
- `atlas_test_contract_semantics_gate.py` passou a bloquear o retorno desse
  contrato frágil que atravessava literais Dart adjacentes;
- toda a cadeia estática anterior foi reexecutada e aprovada.

Backend/banco: sem alterações.
