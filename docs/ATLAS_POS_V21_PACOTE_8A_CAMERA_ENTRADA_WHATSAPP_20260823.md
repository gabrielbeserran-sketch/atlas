# Atlas Pós-V21 — Pacote 8A: Câmera da Entrada → WhatsApp

## Baseline

Pacote 7F homologado no Windows.

## Auditoria antes da implementação

A solicitação de três boletins separados por WhatsApp já estava implementada
no Pacote 5 e foi preservada:

1. boletim zootécnico;
2. boletim de operação/equipe;
3. boletim financeiro.

Eles já possuem:
- agenda mensal independente;
- opt-in;
- outbox durável;
- templates oficiais;
- webhook de status;
- cron externo.

O 8A não cria outro sistema de boletins.

Também foram encontradas duas gerações de IoT. A câmera NÃO foi construída
sobre `iot_devices` (legado). Ela pertence ao `AtlasIotDevice` consolidado
(`atlas_iot_devices_v2`), já usado pelo Precision Hub.

## O que o 8A implementa

### Cadastro da câmera

A câmera da entrada aparece dentro do Precision Hub / IoT, mapas e visão.

O cadastro usa:
- nome;
- identificação externa única;
- `device_type = entrance_camera`.

A identificação externa é o vínculo entre a câmera/gateway físico e o Atlas.
Duplicidade é recusada para impedir que um evento seja atribuído à fazenda
errada.

### Configuração do alerta

Por câmera:
- WhatsApp do produtor;
- confirmação de autorização;
- alertar pessoa: sim/não;
- alertar veículo: sim/não;
- habilitar/desabilitar;
- intervalo mínimo entre alertas iguais.

O intervalo pode ficar entre 10 e 3600 segundos e evita dezenas de mensagens
durante o mesmo movimento.

### Ingestão física

Endpoint:

`POST /api/v1/security-camera/events/ingest`

Formato multipart:
- `device_external_id`;
- `event_external_id`;
- `event_type`: `person` ou `vehicle`;
- `captured_at`;
- `confidence` opcional;
- `image`.

Autenticação:
`X-Atlas-Iot-Key`.

A chave nunca é exposta no Flutter.

O `event_external_id` torna o evento idempotente. Se o gateway repetir o mesmo
evento por timeout/rede, o Atlas não cria uma segunda ocorrência.

### Detecção

O Atlas não finge que consegue detectar pessoa/veículo sem hardware.

Nesta arquitetura, a câmera ou gateway local é responsável por detectar
`person` ou `vehicle` e entregar a captura ao backend.

Isso permite integrar câmeras que já possuem detecção inteligente e também
permite, no próximo pacote, criar adaptadores locais para equipamentos que não
possuam webhook nativo.

### Foto

A captura é validada como:
- JPEG;
- PNG;
- WebP.

Ela usa o mesmo backend oficial de anexos já consolidado no projeto:
Supabase Storage em produção.

O arquivo fica sob uma árvore exclusiva `security-camera/...`; nenhum novo
storage paralelo foi criado.

### WhatsApp

O provider existente foi ampliado, não duplicado.

Nova variável:
`ATLAS_WHATSAPP_TEMPLATE_SECURITY_ALERT`.

O template esperado possui:
- cabeçalho de imagem;
- corpo com 3 parâmetros:
  1. nome da câmera;
  2. `Pessoa detectada` ou `Veículo detectado`;
  3. data/hora.

Fluxo:

câmera/gateway
→ evento + foto
→ autenticação IoT
→ idempotência
→ persistência da foto
→ regra de opt-in/tipo/cooldown
→ upload da imagem ao WhatsApp
→ template oficial com foto
→ confirmação de `message_id`
→ webhook acompanha sent/delivered/read/failed

Se credenciais/template não existirem, o evento é salvo com
`blocked_provider`. O Atlas não informa envio fictício.

### Anti-spam

Eventos consecutivos do mesmo tipo e da mesma câmera dentro do intervalo
configurado são persistidos como `suppressed_cooldown`, mas não geram nova
mensagem.

### Retry

Eventos com falha podem ser reenviados pelo aplicativo depois que a
configuração/provedor for corrigida.

Eventos já aceitos, entregues, lidos ou suprimidos por cooldown não oferecem
retry.

## Banco

Migration:
`20260823_0043_security_camera_alerts.py`

Nova tabela:
`security_camera_events`.

FK:
`atlas_iot_devices_v2.id`.

Não há tabela de câmera paralela: a câmera continua sendo um AtlasIotDevice.

## App

Novo card `Segurança da entrada` dentro do Precision Hub.

Mostra:
- câmeras cadastradas;
- prontidão do WhatsApp;
- opt-in;
- tipos de detecção;
- status dos alertas;
- eventos recentes;
- retry de falhas.

## Deploy

O 8A altera backend e banco.

Depois da homologação local:
1. publicar backend no Render;
2. executar `alembic upgrade head`;
3. configurar `ATLAS_WHATSAPP_TEMPLATE_SECURITY_ALERT` quando o template
   oficial estiver aprovado;
4. executar
   `scripts/quality/check_post_v21_package8a_security_camera_deployed.ps1`.

A verificação pública confirma:
- backend pronto;
- migration 0043;
- chave IoT configurada;
- backend de Storage;
- disponibilidade do template de segurança sem expor segredo.

## Próximo pacote

8B — adaptador físico/edge para câmera.

Ele deve receber o modelo/protocolo real do equipamento e ligar o evento
`person/vehicle` ao contrato 8A. Se a câmera já emitir eventos inteligentes,
o adaptador será apenas de protocolo; se não emitir, será necessário um
gateway local de visão computacional.
