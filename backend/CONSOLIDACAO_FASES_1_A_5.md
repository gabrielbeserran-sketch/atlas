# Consolidação Atlas — Fases 1 a 5

## Fase 1 — Imports
Testes com imports de routers removidos foram retirados da suíte ativa. O `main.py` permanece como fonte oficial dos routers.

## Fase 2 — Legado
Testes por sprint, fase e bloco foram movidos para `test_backups/legacy_sprint_phase_contracts`. Nenhum arquivo foi descartado.

## Fase 3 — Testes oficiais
A suíte ativa foi renomeada por domínio: autenticação, rebanho, IA, plataforma de dados, operações empresariais, SaaS, segurança, precisão e release.

## Fase 4 — Nomenclatura
Nomes de sprint foram removidos da suíte ativa e da documentação operacional. Migrations históricas não foram renomeadas.

## Fase 5 — Arquitetura definitiva
Foram formalizados os pacotes `core`, `models`, `repositories`, `services`, `routers`, `schemas` e `workers`, com verificador automático.
