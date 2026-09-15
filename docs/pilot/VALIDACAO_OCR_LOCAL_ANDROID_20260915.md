# Validação em aparelho — OCR local de documentos financeiros

## Objetivo

Confirmar, em uma única sessão no Android, que a foto de uma nota fiscal ou
uma imagem recebida pelo WhatsApp preenche apenas sugestões revisáveis no
lançamento financeiro, inclusive sem conexão. A imagem e o texto devem
permanecer no aparelho enquanto a leitura local estiver em uso.

## Artefato a instalar

- Arquivo: `build/app/outputs/flutter-apk/app-debug.apk`
- SHA-256: `62D6AC6C1F1977C5B6D16DD9A408FD825C55C206C85532CA7750A026C740FEFA`
- Origem: `421fef0` / tag `atlas-ocr-local-date-validation-20260915`

## Preparação

1. Copiar o APK ao celular e instalá-lo, autorizando a instalação da fonte
   usada para a transferência.
2. Ter uma nota legível: razão social, data, número e total visíveis. Se ela
   tiver QR Code de NF-e, mantê-lo dentro do enquadramento.
3. Deixar uma segunda imagem da mesma nota salva na galeria ou recebida pelo
   WhatsApp para validar a importação.
4. Anotar o total e a data impressos: eles são a referência de conferência,
   nunca o resultado do OCR.

## Cenário A — foto pela câmera, conectado

1. Abrir **Financeiro** e escolher **Novo lançamento**.
2. Selecionar **Fotografar nota** e tirar a foto inteira, sem reflexo forte.
3. Confirmar que o formulário abre com a faixa de leitura local e que os
   campos sugeridos continuam editáveis.
4. Conferir fornecedor, data, documento, valor e categoria contra o papel.
5. Se houver QR Code, confirmar que a chave de acesso possui exatamente 44
   dígitos quando preenchida.
6. Corrigir qualquer divergência manualmente e salvar somente após a revisão.

**Aceite:** não há lançamento automático; a foto fica anexada ao lançamento
salvo e os campos reconhecidos são conferíveis antes de gravar.

## Cenário B — imagem do WhatsApp/galeria, sem internet

1. Ativar modo avião e manter o Atlas aberto.
2. Em **Novo lançamento**, escolher **Importar foto da galeria** e selecionar
   a imagem recebida pelo WhatsApp.
3. Conferir que a leitura local continua disponível e que não há bloqueio por
   servidor ou tentativa obrigatória de nuvem.
4. Validar particularmente uma data curta, como `09-09-26`: ela deve aparecer
   como `09/09/2026`.
5. Salvar ou cancelar após conferir. Caso salve, verificar a indicação de
   sincronização pendente, sem perda da foto.

**Aceite:** a ausência de internet não impede abrir o formulário, revisar os
dados nem preservar o lançamento/foto para sincronização posterior.

## Cenário C — proteção contra leitura inválida

1. Repetir a importação com foto desfocada, parcialmente cortada ou contendo
   uma data impossível, por exemplo `31/02/2026`.
2. Confirmar que o Atlas exibe aviso de dado não identificado ou deixa o campo
   vazio; nunca deve criar uma data, valor ou fornecedor fictício.

**Aceite:** toda informação incompleta exige preenchimento humano, sem travar
o lançamento manual.

## Evidências a registrar

- Modelo e versão do Android.
- Uma captura da tela de revisão para cada cenário (sem expor dados fiscais de
  terceiros fora da equipe autorizada).
- Resultado: aprovado, divergência corrigida ou falha reproduzível.
- Em falha: foto de tela, etapa, tipo de origem (câmera/galeria), estado de
  rede e mensagem apresentada.

## Critério de encerramento

A etapa de OCR local passa de 98% para 100% somente se os cenários A e B forem
aprovados em aparelho real e o cenário C confirmar que não há preenchimento
inventado. Qualquer erro reprodutível abre correção antes de nova release.
