# Atlas Pós-V21 — Pacote 9A: Contato Veterinário

## Baseline

Pacote 8C homologado.

## Auditoria

A Central da Consultoria já possuía:
- Falar no WhatsApp;
- Solicitar visita;
- Enviar resumo;
- integração com Agenda;
- integração com resumo operacional;
- boletins mensais.

A duplicação de uma nova tela foi descartada.

O problema encontrado foi arquitetural: o contato do veterinário responsável
estava gravado diretamente no código Flutter.

## Nova arquitetura

O contato agora é oficial, remoto e por fazenda.

Backend:
`GET /api/v1/consultancy/contact?farm_id=...`

Edição:
`PATCH /api/v1/consultancy/contact?farm_id=...`

Leitura exige `farms.read`.
Edição exige `farms.update`.

## Dados do responsável

- nome;
- função;
- WhatsApp;
- consultoria/empresa;
- ativo/inativo.

O número é normalizado e validado entre 10 e 15 dígitos.

## Segurança e isolamento

A API valida:
- empresa ativa;
- escopo da fazenda;
- permissão;
- fazenda pertencente à empresa.

Há uma única configuração por `company_id + farm_id`.

O Flutter não contém mais nome ou telefone pessoal hardcoded.

## Experiência do cliente

Quando o responsável está configurado:
- Falar no WhatsApp;
- Solicitar visita;
- Enviar resumo

ficam disponíveis.

Quando não está configurado, os botões ficam desabilitados em vez de abrir um
contato antigo ou incorreto.

Usuários com `farms.update` recebem:
- Configurar responsável;
- Editar responsável.

## WhatsApp

Continua usando `wa.me` por HTTPS e a abertura externa consolidada.

A mensagem fica visível para revisão antes do envio.

O Atlas não envia mensagem em nome do cliente sem ação explícita.

## Banco

Migration:
`20260823_0044_consultancy_contacts.py`

Tabela:
`consultancy_contacts`

Cadeia:
`0043 -> 0044`

## Produção

O Render continua aplicando `alembic upgrade head` automaticamente.

Depois do deploy:
`scripts/quality/check_post_v21_package9a_vet_contact_deployed.ps1`

## Release seguro

Antes do commit:
`scripts/quality/run_post_v21_package9a_release_preflight.ps1`

Depois de `git add -A`:
`scripts/quality/check_post_v21_package9a_staged_release.ps1`

Esses scripts já incorporam a correção aprendida no 8A: migration untracked é
aceita antes do staging, pager fica desabilitado e a presença no staging é
exigida somente depois do `git add`.

## Validação local disponível

- gate 9A: aprovado;
- gate de release 9A: aprovado;
- contrato legado do Pacote 4 atualizado para contato remoto;
- Dart structural guard: 5/5;
- regressão estática completa anterior: 33/33.
