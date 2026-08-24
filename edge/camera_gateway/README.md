# Atlas Camera Gateway — Pacote 8B

Este gateway é a ponte física entre a câmera/NVR da fazenda e o contrato
`/security-camera/events/ingest` do backend Atlas.

## O que ele faz

- recebe do adaptador local um evento `person` ou `vehicle`;
- recebe a foto correspondente;
- valida formato e confiança;
- cria/preserva um `event_external_id`;
- copia a foto para uma fila local antes de tentar a internet;
- envia ao Atlas com `X-Atlas-Iot-Key`;
- só remove da fila quando o backend confirma um ID de evento;
- mantém eventos pendentes durante queda de internet;
- repete a entrega com o mesmo ID, permitindo idempotência no backend.

## O que ele NÃO faz

Ele não inventa detecção de pessoa/veículo e não presume uma marca de câmera.

A origem da detecção será um adaptador específico:
- webhook do equipamento;
- NVR;
- ONVIF/eventos;
- SDK do fabricante;
- gateway de visão computacional.

Esse adaptador será definido quando o modelo/protocolo do equipamento real
estiver escolhido.

## Instalação

Python 3.11+:

```bash
python -m venv .venv
. .venv/bin/activate
pip install .
```

Copie `.env.example` para `.env` e configure sem versionar a chave real.

## Teste controlado com uma foto real

```bash
atlas-camera-gateway emit \
  --type person \
  --image ./foto_entrada.jpg \
  --event-id teste-entrada-001
```

Se a internet estiver indisponível, o resultado será `delivery=pending_offline`.
A captura continuará na fila local.

## Worker

```bash
atlas-camera-gateway worker
```

Ou via Docker:

```bash
docker compose up -d --build
```

## Princípio de segurança

A chave IoT nunca deve ser gravada no repositório ou dentro do aplicativo
Flutter. Ela existe somente no backend e no gateway físico controlado.


## Diagnóstico de compatibilidade física — 8C

Antes de implementar um driver específico, o gateway consegue descobrir
capabilidades básicas sem assumir marca/modelo:

```bash
atlas-camera-gateway probe-camera \
  --host 192.168.1.20 \
  --onvif-port 80 \
  --rtsp-port 554 \
  --username admin \
  --output camera-report.json
```

Se a câmera exigir senha, ela deve ser fornecida somente por variável de
ambiente no gateway:

```bash
ATLAS_CAMERA_PASSWORD=... atlas-camera-gateway probe-camera ...
```

A senha nunca entra no relatório JSON nem deve ser colocada na linha de
comando, evitando histórico de shell.

O relatório diferencia:

- porta RTSP alcançável;
- serviço ONVIF alcançável;
- autenticação ONVIF aceita;
- endpoint de mídia anunciado;
- endpoint de eventos anunciado;
- limitações ainda não confirmadas.

Uma porta aberta **não é tratada como prova de recurso**. Por exemplo, RTSP
TCP aberto não significa que o caminho do stream, codec ou credenciais já
estejam homologados.

### Por que esta etapa existe

O próximo driver físico só deve ser implementado depois de sabermos o que o
equipamento realmente oferece. Isso evita manter código específico de uma
marca que talvez nem seja usada na fazenda.
