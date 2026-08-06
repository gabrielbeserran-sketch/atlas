# Fase 48 — Monitoramento em Tempo Real

## Pacotes
- 371: Central de eventos;
- 372: WebSockets;
- 373: atualização em tempo real;
- 374: alertas instantâneos;
- 375: centro de notificações;
- 376: base para push mobile;
- 377: alertas inteligentes;
- 378: monitor operacional;
- 379: sala de controle;
- 380: operação em tempo real.

## Implementação
A fase acrescenta persistência de eventos, hub WebSocket em memória,
notificações com leitura e deduplicação, assinaturas por usuário,
métricas operacionais e uma tela Flutter para acompanhar eventos.

## Correções incorporadas
- bootstrap do administrador corrigido;
- `email_verified` pertence ao usuário, não ao vínculo Membership.

## Limites
O hub atual funciona em uma única instância do backend. Para escalar
horizontalmente, a próxima evolução deverá usar Redis Pub/Sub, NATS,
RabbitMQ ou Kafka. Push externo, SMS e WhatsApp permanecem como
adaptadores futuros.
