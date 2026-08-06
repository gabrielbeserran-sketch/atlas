
# Fase 49 — IoT Enterprise

## Pacotes
- 381: Gateway IoT;
- 382: Sensores de pastagem;
- 383: Sensores climáticos;
- 384: Sensores de água;
- 385: Coleiras inteligentes;
- 386: Balanças automáticas;
- 387: Cercas inteligentes;
- 388: Integração LoRaWAN;
- 389: Edge Computing;
- 390: Plataforma IoT Atlas.

## Entrega
- cadastro de gateways;
- cadastro de dispositivos;
- vínculo com fazenda, lote e animal;
- ingestão autenticada de telemetria;
- bateria e intensidade de sinal;
- regras automáticas;
- alertas em tempo real;
- comandos remotos;
- histórico de telemetria;
- dashboard IoT;
- migração Alembic;
- testes estruturais.

## Natureza da integração
A fase cria uma camada neutra de dispositivos. Ela não inclui drivers
proprietários de fabricantes nem um broker MQTT real. O endpoint HTTP de
ingestão permite integrar gateways, LoRaWAN Network Servers e agentes edge.

## Segurança
A ingestão usa o cabeçalho `X-Atlas-Iot-Key`. Em produção, a chave deve ser
substituída por credenciais individuais por gateway, rotação de segredo,
TLS e assinatura das mensagens.
