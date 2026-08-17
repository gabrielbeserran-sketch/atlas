# Projeto Atlas — Marco 5D

## Objetivo
Eliminar caminhos locais e SharedPreferences como autoridade oficial de Fotos
e Documentos do animal.

## Arquitetura implementada
- Metadados oficiais: PostgreSQL (`animal_media`).
- Bytes oficiais: armazenamento persistente do backend.
- Docker: volume `atlas_attachments:/data/attachments`.
- Escopo: tenant → empresa → fazenda → animal.
- Download e upload exigem sessão/permissionamento.
- Flutter: download para `Directory.systemTemp/atlas_media_cache`.
- SharedPreferences: somente snapshot confirmado para contingência offline.

## Segurança
- Extensões e MIME types permitidos por whitelist.
- Limite de tamanho configurável.
- Nome físico derivado do ID do registro, não do nome enviado pelo cliente.
- Caminho de leitura validado contra traversal.
- Exclusão remove metadado e arquivo.
- Documento pode ser referência web sem upload; foto exige arquivo.

## Bloqueadores resolvidos
- ATT-001 — fotos deixam de ter autoridade local.
- ATT-002 — documentos deixam de ter autoridade local.

## Débito mantido corretamente
- ATT-003 — seleção/abertura nativa Android fica para Marco 6.

## Próximo marco
5E — transações, concorrência e idempotência.
