# Lotação por peso registrado — UA/ha

Implementação local: `a127538`, tag `atlas-grazing-ua-indicator-20260926`.

## Fórmula e referência

UA/ha = soma das últimas pesagens confirmadas dos animais selecionados / 450 / hectares efetivos confirmados.

A equivalência de 1 UA com 450 kg de peso vivo e o cálculo por área seguem a [Embrapa Gado de Corte](https://cloud.cnpgc.embrapa.br/sac/2012/09/14/como-faco-para-calcular-quantos-ua%C2%B4sha-ou-lotacao-animal/).

O resultado representa peso registrado, não estimativa do peso atual nem recomendação de capacidade de suporte. Oferta de forragem e capacidade de suporte não são deduzidas desse indicador.

## Critérios do Atlas

- Base de área e carteira/seleção atuais (até sete dias), com IDs explícitos e quantidade correspondente à base; revisão da base invalida os vínculos anteriores.
- Pesagens confirmadas pelo servidor e presentes no cache isolado por empresa/fazenda/animal. A tela não consulta a rede ao abrir.
- Última data válida por animal nos últimos 90 dias, inclusivos. Essa janela é política operacional explícita do aplicativo, não um prazo recomendado pela Embrapa.
- Datas em formato dia/mês/ano estritamente válidas; dias futuros, pesos não positivos e valores não finitos ficam fora.
- Se existem pesos diferentes na última data do animal, sem horário preservado pelo modelo atual, o animal fica pendente. Cópias iguais não duplicam o peso.
- Pesagens locais sem confirmação remota ficam fora, com contagem de registros ignorados no cartão.
- Todos os animais precisam estar identificados como ativos na carteira e cobertos; uma amostra parcial não produz UA/ha do grupo nem peso total extrapolado.
- Base em conflito, área acima do cadastro, soma ou divisão não finita impedem o índice. Antes de exibir, são reconferidos fazenda, valores da base e seleção para descartar leitura obsoleta.

## Uso e limites

Pastagens → Suporte mostra cobertura, peso total quando completo, intervalo de datas e relação dos animais para conferir. Para repovoar o cache confirmado, consulte as pesagens no módulo Rebanho e retorne. Sem cache completo, o cartão informa indisponibilidade; não inventa medições.

O cálculo está validado localmente com 36 testes e build debug Windows. A versão aberta não foi substituída. Release agrupado e ensaio com dados reais são os próximos marcos. Vínculos individuais e auditoria de revisão permanecem locais; a homologação da sincronização da base ainda é separada.
