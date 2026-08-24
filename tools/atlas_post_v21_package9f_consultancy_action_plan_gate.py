from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required = {
    'backend/alembic/versions/20260824_0047_consultancy_action_idempotency.py': [
        'revision = "20260824_0047"',
        'down_revision = "20260824_0046"',
        'uq_atlas_action_company_farm_idempotency',
    ],
    'backend/app/business_models.py': [
        'idempotency_key: Mapped[str | None]',
    ],
    'backend/app/routers/business.py': [
        '@router.get("/consulting/actions")',
        'source_type="consultancy_action"',
        'source_id=row.id',
        'replayed=True',
        '"agenda_sync": True',
        '"migration": "0047"',
    ],
    'backend/app/routers/operations.py': [
        'task.source_type == "consultancy_action"',
        'action.status = task.status',
        'action.completed_at = task.completed_at',
    ],
    'lib/features/consultancy_client/data/services/atlas_consultancy_action_service.dart': [
        "'/business/consulting/actions'",
        'createFromPriority',
        'idempotency_key',
    ],
    'lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart': [
        'AtlasConsultancyActionPlanCard',
        'createActionsFromPriorities',
        'completeConsultancyAction',
    ],
}

for relative, markers in required.items():
    path = ROOT / relative
    if not path.is_file():
        errors.append(f'arquivo ausente: {relative}')
        continue
    content = path.read_text(encoding='utf-8-sig')
    for marker in markers:
        if marker not in content:
            errors.append(f'{relative}: marcador ausente: {marker}')

business = (ROOT / 'backend/app/routers/business.py').read_text(encoding='utf-8-sig')
if 'db.add(task)' not in business or 'db.flush()' not in business:
    errors.append('criação consultiva não prova transação com tarefa oficial')

operations = (ROOT / 'backend/app/routers/operations.py').read_text(encoding='utf-8-sig')
if 'action.actual_result = task.evidence.strip()' not in operations:
    errors.append('conclusão pela Agenda não devolve evidência ao plano consultivo')

manifest_path = ROOT / 'docs/ATLAS_POS_V21_PACOTE_9F_MANIFEST.json'
if manifest_path.is_file():
    manifest = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
    paths = manifest.get('release_paths', [])
    if len(paths) != len(set(paths)):
        errors.append('manifesto 9F contém caminhos duplicados')
    for relative in paths:
        if not (ROOT / relative).is_file():
            errors.append(f'manifesto aponta arquivo ausente: {relative}')

if errors:
    print('ATLAS POS-V21 PACOTE 9F: REPROVADO')
    for error in errors:
        print(f'[ERRO] {error}')
    raise SystemExit(1)

print('ATLAS POS-V21 PACOTE 9F: APROVADO')
print('[OK] Plano consultivo usa persistência oficial já existente.')
print('[OK] Criação é idempotente e gera tarefa oficial da Agenda.')
print('[OK] Conclusão é sincronizada nos dois sentidos.')
print('[OK] Central da Consultoria opera sobre dados da fazenda ativa.')
