# Atlas Pós-V21 — Pacote 9C: Implantação Atlas Persistente

## Baseline

Pacote 9B publicado e comprovado em produção.

## Objetivo

Transformar a etapa de implantação do cliente em um processo real e rastreável dentro do Atlas, sem criar outro módulo paralelo e sem manter checklist fictício de conclusão.

## Reuso da arquitetura existente

O backend já possuía `onboarding_progress` no domínio `saas-growth`. O 9C reutiliza essa tabela e não cria migration nova.

## Entrega funcional

A Central da Consultoria passa a exibir `Implantação Atlas`, com cinco passos canônicos:

1. Fazenda e contexto configurados.
2. Rebanho inicial conferido.
3. Responsável técnico definido.
4. Rotina e agenda inicial organizadas.
5. Treinamento inicial concluído.

O progresso é lido do backend e persistido no backend. Usuários sem permissão de gestão enxergam o andamento, mas não podem alterá-lo.

## Backend

Rotas:

- `GET /api/v1/saas-growth/onboarding`
- `POST /api/v1/saas-growth/onboarding`
- `GET /api/v1/saas-growth/onboarding/deployment-readiness`

Permissões:

- leitura: `farms.read`;
- atualização: `farms.update`.

O POST agora devolve também `steps`, `completion_percent` e `completed_at`, permitindo confirmação remota após cada alteração.

## Segurança operacional

A interface usa atualização otimista apenas durante a ação do usuário. Se o backend rejeitar ou falhar, o estado anterior é restaurado e a falha é exibida.

## Endurecimento de release

O 9C também corrige o falso negativo encontrado no gate do 9B. `check_post_v21_package9b_staged_release.ps1` agora diferencia:

- pacote realmente em staging;
- pacote já commitado, com working tree limpo e arquivos obrigatórios presentes no HEAD.

Assim o gate não exige que um arquivo já commitado volte artificialmente ao staging.

## Migration

Nenhuma.

O pacote reutiliza `onboarding_progress`, já existente na baseline atual.

## Homologação

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\quality\run_post_v21_package9c_onboarding_homologation.ps1"
```

## Produção

Depois do deploy:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\quality\check_post_v21_package9c_onboarding_deployed.ps1"
```
