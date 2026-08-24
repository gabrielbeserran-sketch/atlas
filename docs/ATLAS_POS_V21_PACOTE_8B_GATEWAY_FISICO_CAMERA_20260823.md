# Atlas Pós-V21 — Pacote 8B: Gateway físico da câmera

## Baseline

Pacote 8A publicado e homologado em produção:
- backend pronto;
- migration 0043 confirmada;
- ingestão IoT protegida;
- schema da câmera publicado.

O template oficial de segurança do WhatsApp ainda pode permanecer não
configurado. Nesse caso, o 8A continua persistindo eventos sem fingir envio.

## Objetivo do 8B

Criar a ponte física entre a câmera/NVR da fazenda e o contrato 8A sem
amarrar o Atlas a uma marca ainda não escolhida.

O gateway é vendor-neutral.

## Arquitetura

câmera/NVR
→ adaptador específico do equipamento
→ evento person/vehicle + foto
→ fila local durável
→ gateway Atlas
→ POST /security-camera/events/ingest
→ backend 8A
→ Supabase Storage
→ WhatsApp quando provider/template estiverem prontos

## Verdade física

O gateway NÃO executa detecção de pessoa ou veículo por conta própria.

Não foi incluído:
- YOLO;
- OpenCV;
- reconhecimento facial;
- TensorFlow;
- Torch;
- detector inventado.

A detecção deve vir do equipamento, NVR ou de um adaptador de visão
explicitamente escolhido e homologado.

## Contrato de adapter

Foi criado `CameraEventAdapter`.

Qualquer driver real precisa produzir apenas:
- `person` ou `vehicle`;
- foto JPEG/PNG/WebP;
- identificador externo do evento;
- data/hora;
- confiança opcional.

## Adapter genérico por pasta

Foi incluído `FolderEventAdapter`.

Ele atende equipamentos/NVRs capazes de executar scripts ou gravar metadados
em uma pasta monitorada.

Exemplo de `<id>.event.json`:

```json
{
  "event_type": "person",
  "image": "snapshot-001.jpg",
  "event_external_id": "camera-evt-001",
  "captured_at": "2026-08-23T15:30:00-03:00",
  "confidence": 0.92
}
```

A imagem precisa permanecer dentro da árvore autorizada da inbox. Tentativa de
`../` ou outro escape de caminho é rejeitada.

## Fila offline

Antes de tentar a internet, o gateway:
1. cria diretório temporário;
2. copia a foto;
3. grava event.json;
4. promove atomicamente para `pending`.

Assim, queda de internet depois do evento não perde a captura.

O evento só sai de `pending` quando o backend Atlas retorna um ID oficial.

Falha de rede:
- evento permanece pendente;
- erro é registrado;
- worker faz retry;
- backoff aumenta gradualmente.

## Idempotência

O mesmo `event_external_id`:
- não cria duas entradas no spool local;
- pode ser reenviado depois de timeout;
- o backend 8A também reconhece a repetição.

Isso protege contra duplicidade nos dois lados.

## Segurança

O gateway exige:
- `ATLAS_CAMERA_DEVICE_EXTERNAL_ID`;
- `ATLAS_IOT_INGEST_KEY` com pelo menos 32 caracteres;
- URL HTTP/HTTPS válida.

A chave:
- não está no Flutter;
- não está no `.env.example`;
- não é gravada no repositório;
- existe apenas no backend e no equipamento/gateway controlado.

## Execução

Com Python:

`atlas-camera-gateway emit --type person --image foto.jpg --event-id evento-001`

Fila contínua:

`atlas-camera-gateway worker`

Adapter de pasta:

`atlas-camera-gateway watch-folder --inbox ./inbox --processed ./processed`

Docker:

`docker compose up -d --build`

O volume `/data` preserva a fila entre reinicializações.

## Validação

- Python compile do gateway: 9/9;
- selftest offline: aprovado;
- adapter folder: OK;
- spool offline: OK;
- idempotência local: OK;
- proteção de path escape: OK;
- gate 8B: aprovado;
- regressão estática Atlas completa: 31/31.

## Backend e banco

Nenhuma alteração adicional no 8B.

O gateway reutiliza o backend 8A já publicado e a migration 0043 já ativa.

## Próxima etapa

8C — driver físico específico.

Para fechar a integração de campo será necessário escolher ou informar pelo
menos um dos seguintes:
- marca/modelo da câmera;
- NVR utilizado;
- suporte a ONVIF;
- webhook/event API;
- RTSP/SDK do fabricante.

Somente então o adaptador específico será implementado e homologado.
