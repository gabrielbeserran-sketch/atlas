# Avaliação da cronologia reprodutiva — 26/09/2026

Pacote local, sem mudança dos registros persistidos ou instalação.

## Critérios automatizados

- Última secagem anterior ao parto é escolhida por data, não ordem da lista.
- Uma secagem não é reutilizada após outro parto.
- Primeira inseminação é escolhida dentro do ciclo, sem aproveitar o ciclo seguinte.
- Secagem no dia ou após o último parto retira a matriz da base do DEL; uma secagem futura não altera a situação atual.
- Cinco testes novos e regressão Leite/Corte/painel: 58 testes aprovados.

## Limitações e próximos passos

O campo legado averageServicePeriodDays ainda representa parto–primeira inseminação, e seu rótulo no painel precisa de revisão junto ao vínculo diagnóstico–inseminação. Não é período de serviço comprovado: a definição técnica é parto–concepção, conforme [Embrapa — manejo pós-parto](https://www.embrapa.br/en/web/agencia-de-informacao-tecnologica/criacoes/gado_de_leite/producao/sistemas-de-producao/reproducao/manejo-reprodutivo/manejo-da-vaca-leiteira/pos-parto).

Este pacote não resolve IDs repetidos, diagnósticos contraditórios ou eventos anteriores ao nascimento. Esses itens precedem o aceite técnico real. A compilação Windows/Android fica agrupada com o próximo pacote funcional; o aplicativo já instalado não contém esta mudança. Não foi alterado backend/atlas_test.db.
