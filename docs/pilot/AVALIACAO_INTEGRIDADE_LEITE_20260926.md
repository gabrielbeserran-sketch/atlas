# Integridade de ordenhas — avaliação local

Checkpoint: `atlas-dairy-input-integrity-20260926`. Dados reais e versão do celular preservados. Não é aceite técnico/comercial do módulo inteiro.

Executável preservado: `C:/Projetos/Projetos Atlas/release/windows/leite-integridade-20260926/projeto_atlas.exe`. Inclui as correções anteriores de Campo/Operações/pastagem. SHA-256 data/app.so: 6B9AAC67E39C6F97A12859B983DECAD17424DBC052056757C1671E7148EC7FCB; identidade com.example/projeto_atlas e build main.dart production com URL oficial conferidos. Salvar e fechar a versão anterior antes de abrir; não usar duas janelas no mesmo armazenamento. Nenhuma autenticação automatizada.

Validações: 45 testes Leite/Corte/painel aprovados, incluindo dez novos casos (um widget); análise de cinco arquivos sem apontamentos, diff aprovado e um build Windows profile agrupado aprovado (146,1 s). Build não substitui avaliação no aparelho ou aceite técnico.

## Mudanças

- Leitura de uma ordenha exige data ISO válida e existente no calendário; data ausente/ilegível não é convertida em hoje. Números textuais válidos são aceitos; texto ilegível, valor não finito ou quantidade fracionária de vacas são recusados.
- A janela de 30 dias considera o dia civil, inclusive registros de hoje com horário. Registro com horário no mesmo dia não é rotulado como data futura.
- Médias dividem antes da soma para evitar overflow intermediário de valores finitos. Não são limites zootécnicos recomendados; valores extremos foram usados apenas nos testes de segurança aritmética.
- Salvar/excluir exige leitura estrita de todos os registros anteriores. JSON ou registro ilegível bloqueia a alteração e mantém o conteúdo original, sem substituir a coleção por vazia.
- A tela de produção diária mostra aviso de falha de leitura, não apresenta o cartão de “ainda não há produção”, bloqueia Registrar ordenha e oferece nova leitura. Falhas ao alterar são tratadas na tela.

## Limites e avaliação

Testes usam preferências mockadas, inclusive corrupção simulada. Não apagar, editar ou corromper o armazenamento real para reproduzir os casos. Não há reparação automática de conteúdo ilegível; a recuperação exige diagnóstico e cópia de segurança autorizada.

A leitura permissiva do serviço retorna lista vazia quando não consegue interpretar a coleção; a tela de Leite usa leitura estrita para diferenciar falha de ausência. Outros consumidores permissivos não receberam novos alertas individuais neste pacote. Não houve migração da chave legada por fazenda nem mudança de isolamento por empresa/tenant; esses pontos exigem pacote próprio antes da homologação comercial.

Após salvar/fechar a versão anterior, avaliar a versão agrupada: conferir produção existente, cadastrar uma ordenha válida por fluxo normal e verificar litros/dia, vacas ordenhadas e data. Usar somente dados autorizados. A validação de Corte neste pacote foi regressão dos indicadores existentes, não mudança de funções.
