# Projeto Atlas — Marco 5C

## Objetivo
Endurecer autenticação, sessões, MFA, recuperação de senha e isolamento da identidade.

## Correções
- Access JWT agora é vinculado a uma RefreshSession persistida por `session_id`.
- Logout, revogação, refresh rotation e resets invalidam access tokens imediatamente.
- Reset administrativo revoga todas as sessões e grava `password_changed_at`.
- TOTP de MFA é criptografado em repouso via Fernet e chave dedicada.
- Novo pedido de reset invalida tokens anteriores ainda não usados.
- Recovery codes usam comparação em tempo constante e consumo único.
- Challenge MFA revalida usuário, empresa e tenant.

## Próximo marco
5D — Fotos e Documentos remotos / autoridade multi-dispositivo.
