# Fase 44 — Aplicativo Conectado e Funcionamento Offline

## Pacotes
- 331: Cliente HTTP centralizado;
- 332: Sessão segura no aplicativo;
- 333: Login conectado ao backend;
- 334: Seleção de empresa e fazenda;
- 335: Rebanho conectado à API;
- 336: Reprodução conectada à API;
- 337: Sanidade conectada à API;
- 338: Nutrição, financeiro e estoque conectados;
- 339: Banco offline estruturado;
- 340: Sincronização bidirecional real.

## Entrega executável
- cliente HTTP único;
- timeouts e repetição controlada;
- refresh automático;
- armazenamento seguro de sessão;
- cadastro, recuperação e MFA;
- contexto de empresa e fazenda;
- repositórios remotos com fallback local;
- SQLite via sqflite_common_ffi;
- cache estruturado;
- fila offline persistente;
- chaves idempotentes;
- retentativas;
- indicador de sincronização.

## Limite atual
O backend da Fase 43 ainda não possui endpoint incremental de download por
cursor nem campos formais de versão em todas as entidades. Por isso, o motor
desta fase envia a fila local e atualiza o cache ao consultar as APIs, mas a
resolução avançada de conflitos fica para a Fase 45.
