# Correção da Fase 44 — Métodos de backup

Foram restaurados no `AtlasEnterpriseApiClient`:

- `backups()`, usando `GET /backups`;
- `runBackup()`, usando `POST /backups/run`.

A correção elimina os erros exibidos em
`atlas_enterprise_24d_screen.dart`.
