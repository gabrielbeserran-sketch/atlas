# Atlas Pós-V21 — Pacote 8C: Compatibilidade física da câmera

## Baseline

Pacote 8B homologado no Windows.

## Objetivo

Antes de escrever um driver específico de fabricante, o gateway agora consegue
descobrir objetivamente quais capacidades básicas o equipamento oferece.

O 8C não presume marca/modelo e não cria detector de visão artificial.

## Comando

`atlas-camera-gateway probe-camera`

Parâmetros:
- `--host`;
- `--onvif-port` (padrão 80);
- `--rtsp-port` (padrão 554);
- `--username`;
- `--output` opcional.

Senha:
`ATLAS_CAMERA_PASSWORD`.

A senha não é aceita como argumento de linha de comando e não aparece no
relatório JSON, evitando vazamento em histórico de shell ou arquivo de
diagnóstico.

## O que é verificado

### Rede

O perfilador resolve o hostname/IP e testa conectividade TCP em:
- HTTP 80;
- HTTPS 443;
- RTSP;
- porta ONVIF informada;
- 8000;
- 8899.

Essas portas adicionais são somente indícios de conectividade e não são
tratadas como prova de compatibilidade de fabricante.

### ONVIF

Quando a porta ONVIF responde, o gateway envia uma chamada padronizada
`GetCapabilities`.

O relatório diferencia:
- serviço de dispositivo alcançável;
- autenticação aceita;
- XAddr de Media;
- XAddr de Events.

Ter serviço ONVIF acessível não significa automaticamente que eventos
inteligentes person/vehicle já estejam disponíveis.

### RTSP

O 8C confirma somente a conectividade TCP da porta RTSP.

Ele não inventa:
- caminho do stream;
- codec;
- autenticação;
- perfil;
- suporte a snapshot.

Esses itens dependem do equipamento real.

## Segurança

O host deve ser apenas IP ou hostname. URLs/caminhos arbitrários são rejeitados.

Credenciais ONVIF:
- usuário pode ser informado no diagnóstico;
- senha vem apenas de `ATLAS_CAMERA_PASSWORD`;
- senha não entra no JSON;
- senha não entra na linha de comando.

O perfilador não possui:
- YOLO;
- OpenCV;
- TensorFlow;
- Torch;
- reconhecimento facial.

## Dependências

O selftest offline não exige `httpx` nem rede.

`httpx` é importado somente quando o probe ONVIF real é executado. No gateway
instalado, a dependência já está declarada no `pyproject.toml`.

## Validação

- Gateway Python compile: 10/10;
- selftest offline: aprovado;
- perfilador ONVIF/RTSP local: OK;
- gate 8C: aprovado;
- regressão estática Atlas: 32/32.

## Backend e banco

Nenhuma alteração.
Nenhuma migration.

## Próxima etapa

Depois do 8C homologado, a próxima ação de campo é executar `probe-camera`
contra a câmera/NVR real. O relatório permitirá decidir entre:

- ONVIF Events;
- webhook/API do fabricante;
- NVR;
- RTSP + adaptador específico;
- folder adapter já existente.

Só então o driver específico será implementado.
