# Atlas Pós-V21 — Pacote 7B: Voz do Dr. Beserra

## Princípio

A voz não possui permissões próprias de negócio.

Pipeline obrigatório:

`microfone -> transcrição -> sendText -> DrBeserraCommandGateway`

O mesmo gateway usado pelo teclado continua responsável por interpretação,
confirmações e escrita.

## Reconhecimento

Dependências:
- `speech_to_text ^7.4.0`;
- `speech_to_text_windows ^1.0.1`.

Foi criado `DrBeserraVoiceService` singleton porque o recognizer deve ser
inicializado uma vez por sessão.

O serviço:
- inicializa reconhecimento;
- procura locale em português, priorizando pt-BR;
- recebe resultados parciais;
- envia apenas o resultado final para o fluxo conversacional;
- permite iniciar, parar e cancelar;
- não conhece Agenda, Sanidade, Reprodução, Manejo, HTTP ou banco.

## Segurança

A voz não recebeu nenhuma nova escrita.

A única escrita conversacional continua sendo a já homologada no 7A:
concluir uma tarefa da Agenda, após confirmação explícita e verificação de
persistência pelo serviço oficial.

Sanidade, Reprodução e Manejo continuam apenas navegando para seus módulos
oficiais.

## Plataformas

### Android
Adicionadas permissões de microfone e Bluetooth e a query de
`android.speech.RecognitionService`.

### iOS
Adicionadas descrições de uso de reconhecimento de voz e microfone.

### macOS
Adicionadas descrições de privacidade e entitlement de entrada de áudio.

### Windows
Adicionado `speech_to_text_windows` e registro explícito da implementação no
startup.

## Interface

O compositor do Dr. Beserra possui:
- botão de microfone;
- indicação visual de escuta;
- botão para parar;
- transcrição exibida no campo;
- envio automático somente quando o recognizer produz resultado final.

O texto reconhecido passa pelo mesmo `sendText` usado pelo teclado.

## Backend e banco

Nenhuma alteração de backend, banco ou migration foi necessária.
