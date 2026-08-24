# Atlas Pós-V21 — Pacote 9D: Implantação Verificável

## Baseline

Pacote 9C publicado em produção no commit `290a3de` e working tree rastreada saneada.

## Lacuna encontrada na auditoria

O 9C tornou o onboarding persistente, porém os cinco passos ainda podiam ser marcados manualmente. Isso permitia declarar a implantação concluída sem que os módulos oficiais comprovassem a condição.

## Correção

O progresso passa a ser calculado por fazenda. Quatro passos são evidências automáticas:

1. `farm_context`: nome, localização e área da fazenda;
2. `herd_baseline`: ao menos um animal ativo e um lote ativo;
3. `technical_contact`: contato veterinário ativo e válido da própria fazenda;
4. `agenda_routine`: ao menos uma tarefa operacional registrada para a fazenda.

Apenas `initial_training` continua manual, pois sua conclusão não possui fonte operacional confiável no Atlas atual.

## Segurança

O backend ignora tentativas de usar o checklist para forjar passos automáticos. A UI desabilita os quatro checkboxes automáticos e mostra a evidência real retornada pelo servidor.

## Persistência

Reutiliza `onboarding_progress`. O banco guarda apenas a confirmação manual de treinamento; o percentual e os quatro passos operacionais são recalculados a partir das fontes oficiais.

## Migration

Nenhuma.
