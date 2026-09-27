# Avaliação da base reprodutiva — 26/09/2026

## Entrega e critérios

- Identidades de animais ausentes/repetidas são excluídas deste calculador. Todas as cópias de um ID de evento repetido no mesmo animal são excluídas; o mesmo ID em animais diferentes não gera colisão.
- Eventos anteriores ao nascimento conhecido não produzem idade negativa, DEL ou contagem de inseminações.
- Últimos diagnósticos no mesmo dia precisam concordar numa situação reconhecida. Ausência, inconclusivo ou contradição não viram resultado negativo nem escolha arbitrária.
- Prenhe/Vazia (formulário) e pregnant/open (API) são equivalentes somente na leitura deste calculador; os registros permanecem intactos.
- Diagnósticos positivos acima do número de tentativas não geram percentual superior a 100%; indicador indisponível e aviso, sem arredondar artificialmente para 100%.
- Painel identifica a razão histórica diagnósticos positivos/inseminações e o intervalo parto–primeira inseminação. Período de serviço real aparece sem concepção vinculada; não se inventa data de concepção.

Validação local: 66 testes Leite/Corte/painel aprovados, oito novos; análise estática de três arquivos sem apontamentos, diff aprovado. Único build profile Windows oficial aprovado em 316,4 s; inclui o pacote de cronologia 71bf7e8. Artefato em release/windows/reproducao-integridade-20260926, identidade com.example/projeto_atlas, SHA-256 app.so 754B7608DD584B3D3F0EC1D93E19B030A84C721A5387A08FC9EEE49CC23F10A8. Checkpoint atlas-dairy-reproductive-base-20260926. Janela anterior preservada; versão agrupada não aberta.

## Limitações antes do aceite técnico

A razão histórica não é taxa de concepção comprovada. IDs diferentes para o mesmo evento clínico não são deduplicados automaticamente. O diagnóstico mais recente não recebeu prazo de validade ou invalidação por parto neste pacote. Não há migração de eventos, reparo automático nem vínculo persistido entre diagnóstico e inseminação. Outros módulos reprodutivos ainda precisam da mesma revisão de situações em português/inglês. Matriz ativa não significa automaticamente matriz de leite: a definição de população operacional continua no aceite técnico.

Avaliar em versão agrupada: alertas visíveis, DEL excluindo secagem vigente, retorno de situações válidas e indicadores indisponíveis sem zeros inventados. Sem inserir dados fictícios no aplicativo oficial. Não foi alterado banco, PIN ou autenticação, nem instalada nova versão no celular.

Próximo pacote local: auditar consistência das situações entre os módulos reprodutivos e validade do último diagnóstico após novo parto. Posteriormente: vínculo persistido de concepção, avaliação humana, ensaio offline/dois dispositivos e gates externos descritos no cronograma.
