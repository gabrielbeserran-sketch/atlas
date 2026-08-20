# Atlas — V16 + V17

## V16 — Gate funcional automatizado

Foi adicionado `scripts/quality/gate_v16_v17_production.ps1`.

Quando a produção estiver disponível, um único comando valida:

- health;
- login;
- `/auth/me`;
- fazendas;
- Rebanho;
- Lotes;
- Sanidade;
- Nutrição;
- Financeiro;
- Estoque;
- Central de Alertas;
- Resumo Operacional;
- Reconciliação V9.

O gate é somente leitura após o login.

## V17 — Segurança e robustez

### Proteção contra dupla submissão

O cliente HTTP não faz retry automático de POST/PATCH/PUT/DELETE após timeout
ou falha transitória. Somente métodos idempotentes (GET/HEAD/OPTIONS) recebem
retry automático.

Isso evita o cenário:

`POST chega ao servidor → cliente perde resposta → retry cria duplicidade`.

### Backoff e Retry-After

GETs transitórios usam backoff com jitter e respeitam `Retry-After`, inclusive
para 429/502/503/504.

### Refresh token single-flight

Múltiplas chamadas 401 simultâneas compartilham uma única renovação de sessão.
Isso reduz corrida entre refresh tokens e logout indevido.

### Secure Storage

Falhas de DPAPI/`CryptUnprotectData` agora recuperam o armazenamento local de
forma segura. Tokens nunca são movidos para SharedPreferences.

Se a credencial local ficar corrompida, o Atlas limpa somente a sessão local e
solicita novo login.

### Produção lenta / cold start

O timeout de produção sobe para 60 segundos. Como mutações não são repetidas
automaticamente, o aumento não introduz dupla submissão.

### Backend

Além de usuário, empresa, membership, tenant, refresh session, revogação e
expiração, o backend agora verifica se o papel (`role`) do JWT ainda corresponde
ao membership atual. Alteração de papel invalida token antigo.
