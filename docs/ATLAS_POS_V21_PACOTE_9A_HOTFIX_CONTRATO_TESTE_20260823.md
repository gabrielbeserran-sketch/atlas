# Atlas Pós-V21 — Hotfix 9A: contrato legado da Consultoria

## Falha observada

A homologação 9A falhava no teste:

`post_v21_package4_consultancy_contract_test.dart`

Caso:

`cliente fala diretamente com veterinário responsável`

O teste exigia que `atlas_consultancy_contact_service.dart` contivesse
literalmente `role: Veterinário responsável`.

## Causa

Esse contrato era válido no Pacote 4, quando o contato era local/hardcoded.
No Pacote 9A o serviço foi corretamente convertido para buscar o contato
oficial por fazenda em `/consultancy/contact`. O gate Python do Pacote 4 foi
atualizado, mas o teste Flutter legado não foi migrado junto.

## Correção

O teste agora valida comportamento e contrato, não implementação antiga:

- ações Falar no WhatsApp / Solicitar visita / Enviar resumo;
- chamada real `whatsAppService.openConversation`;
- `contact.role` e `contact.displayName` vindos do perfil carregado;
- serviço remoto `/consultancy/contact`;
- `loadForFarm(farmId)`;
- papel padrão mantido no modelo de perfil, não no serviço HTTP.

## Prevenção

`atlas_test_contract_semantics_gate.py` agora bloqueia testes da Consultoria
que voltem a exigir contato pessoal/default hardcoded dentro do serviço HTTP.

`atlas_post_v21_package9a_vet_contact_gate.py` também verifica que o teste
legado já está no contrato remoto.

A homologação 9A executa o gate de semântica explicitamente antes da regressão
Flutter, reduzindo tempo perdido em falhas tardias.

## Validação neste pacote

- gates estáticos: 34/34 aprovados;
- Dart structural guard: 5/5;
- gate 9A: aprovado;
- semantic contract gate: aprovado;
- Pacote 4: 36/36.

O `flutter test` completo deve ser executado no ambiente Windows homologado,
onde o SDK Flutter do projeto está instalado.
