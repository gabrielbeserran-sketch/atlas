# Integridade comercial de Corte — avaliação local

Checkpoint: `atlas-beef-commercial-integrity-20260926`. Dados reais e celular preservados; não constitui aceite comercial ou revisão de todos os índices zootécnicos.

Executável preservado: `C:/Projetos/Projetos Atlas/release/windows/corte-integridade-20260926/projeto_atlas.exe`; reúne correções anteriores de Leite/Campo/Operações. SHA-256 data/app.so: E2DE779AF31330B2C8953B44162535CC6AF6C5DC1CC19697E7225E3E4559749B, identidade com.example/projeto_atlas, entrada main.dart production com URL oficial conferidos. Não abrir duas versões no mesmo armazenamento; salvar/fechar a anterior primeiro. Nenhuma autenticação automatizada.

Validações: 53 testes Corte/Leite/painel aprovados (oito novos), análise de três arquivos sem apontamentos, diff e um build profile Windows oficial aprovados (145,4 s). Nova compilação preservada, não aberta neste pacote.

## Regras verificadas

- Contagem de saídas comerciais usa animais identificados sem ambiguidade e datas dentro da janela existente de 12 meses. Ausência de preço não elimina uma saída datada da contagem.
- IDs vazios ou repetidos são excluídos deste calculador, com aviso. Não há exclusão de cadastro nem escolha arbitrária entre cópias. Outros resumos do aplicativo não receberam normalização global de IDs neste pacote.
- Receita e valor médio usam apenas valores positivos e finitos. Peso positivo e finito também é exigido para preço por quilo. A cobertura mostra quantas vendas possuem valores/pesos válidos.
- Receita com valores conhecidos para apenas parte das vendas recebe rótulo de base parcial, sem extrapolação. Quando existem vendas mas nenhum valor válido, receita fica indisponível; zero é reservado à ausência de vendas datadas na janela.
- Preço por quilo é a soma dos valores dividida pela soma dos pesos das mesmas vendas elegíveis, não a média simples dos preços individuais. O cálculo usa médias escaladas equivalentes para evitar overflow intermediário.
- Soma/razão fora do intervalo numérico fica indisponível com aviso. Médias representáveis podem permanecer disponíveis mesmo se a receita total não puder ser representada. Valores extremos são apenas testes aritméticos, não parâmetros recomendados de produção.

## Casos reproduzidos

1. Uma venda válida de R$ 5.000 e quatro sem valor válido: receita registrada R$ 5.000, cobertura 1/5, sem receita total extrapolada.
2. Valores R$ 1.000/R$ 9.000 e pesos 100/300 kg: preço ponderado R$ 25/kg, não média simples de R$ 20/kg.
3. Vendas com IDs a/a/vazio/b: somente b entra nos indicadores; as outras três são sinalizadas, sem alterar os cadastros.
4. Valores finitos cuja soma transborda: receita indisponível, sem infinito; valor médio e preço por kg representáveis continuam disponíveis.

## Avaliação manual pendente

Após salvar/fechar a versão anterior, abrir a versão agrupada e conferir Produção de Corte no painel técnico. Usar apenas dados autorizados; não criar duplicações, valores extremos ou corrupção nos registros reais. Confirmar clareza dos rótulos de cobertura/ausência antes do aceite técnico. A receita calculada a partir do cadastro de vendas não é conciliação financeira do caixa; o módulo Financeiro não foi alterado.
