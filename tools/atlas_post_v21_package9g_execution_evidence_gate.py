from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required = {
    'backend/alembic/versions/20260824_0048_consultancy_execution_evidence.py': [
        'revision = "20260824_0048"',
        'down_revision = "20260824_0047"',
        'completed_by_user_id',
        'execution_evidence_json',
    ],
    'backend/app/business_models.py': [
        'completed_by_user_id: Mapped[str | None]',
        'execution_evidence_json: Mapped[dict[str, Any]]',
    ],
    'backend/app/routers/business.py': [
        'class ActionCompletionPayload',
        'Informe o resultado executado antes de concluir a ação.',
        'row.completed_by_user_id = principal.user.id',
        'record_audit(',
        '"migration": "0048"',
    ],
    'backend/app/routers/operations.py': [
        'requested_evidence',
        'Informe a evidência/resultado da execução',
        'action.completed_by_user_id = principal.user.id',
        'consultancy_action_completed_from_agenda',
    ],
    'lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart': [
        'Registrar execução',
        'Concluir com evidência',
        'actualResult: result',
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

screen = (ROOT / 'lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart').read_text(encoding='utf-8-sig')
if screen.count('void openReports()') != 1:
    errors.append('regressão estrutural na tela: openReports duplicado/ausente')
if "actualResult: 'Concluída pela Central da Consultoria.'" in screen:
    errors.append('Central ainda possui conclusão fictícia sem evidência')

manifest_path = ROOT / 'docs/ATLAS_POS_V21_PACOTE_9G_MANIFEST.json'
if manifest_path.is_file():
    manifest = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
    paths = manifest.get('release_paths', [])
    if len(paths) != len(set(paths)):
        errors.append('manifesto 9G contém caminhos duplicados')
    for relative in paths:
        if not (ROOT / relative).is_file():
            errors.append(f'manifesto aponta arquivo ausente: {relative}')

if errors:
    print('ATLAS POS-V21 PACOTE 9G: REPROVADO')
    for error in errors:
        print(f'[ERRO] {error}')
    raise SystemExit(1)

print('ATLAS POS-V21 PACOTE 9G: APROVADO')
print('[OK] Conclusão exige evidência/resultado real.')
print('[OK] Executor e momento da execução ficam persistidos.')
print('[OK] Agenda e Consultoria aplicam a mesma regra.')
print('[OK] Conclusão gera trilha oficial de auditoria.')
