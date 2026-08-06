# Atlas Enterprise — arquitetura final
Flutter/Portal → API `/api/v1` → JWT → RBAC → tenant/company guard → PostgreSQL.

Offline: fila 24C → transporte HTTP 24D → push/baseVersion → conflito ou commit → pull incremental.

O pacote contém os artefatos de publicação, mas publicação oficial só existe após deploy real, domínio/HTTPS e validação externa.
