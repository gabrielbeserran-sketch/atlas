# Fase 43 — APIs Pecuárias Reais

Esta fase preserva as APIs existentes de empresas e fazendas e adiciona
modelos relacionais, migração e endpoints executáveis para lotes, animais,
identificadores, movimentações, pesagens, reprodução, sanidade, nutrição,
estoque e custos.

## Integrações automáticas
- pesagem atualiza o peso corrente do animal;
- movimentação atualiza o lote e a situação;
- nutrição pode baixar estoque;
- nutrição pode gerar despesa financeira;
- estoque impede saldo negativo.

## Segurança
Todas as consultas são filtradas por empresa e por fazendas autorizadas.
