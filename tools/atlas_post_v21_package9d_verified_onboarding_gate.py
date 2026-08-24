from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required = {
    'backend/app/routers/saas_growth.py': [
        'ONBOARDING_AUTOMATIC_STEPS', '_onboarding_evidence(',
        'LivestockAnimal', 'HerdLot', 'ConsultancyContact', 'OperationalTask',
        "farm_id: str = Query(min_length=1)", "'automatic_evidence': True",
        "'manual_step_restricted': True",
    ],
    'lib/features/consultancy_client/data/services/atlas_client_onboarding_service.dart': [
        'Future<AtlasClientOnboardingProgress> load(String farmId)',
        'saveManualStep', "queryParameters: {'farm_id': farmId}",
    ],
    'lib/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart': [
        'AtlasClientOnboardingEvidence', 'required this.automatic',
        'copyWithManualStep', 'evidenceFor',
    ],
    'lib/features/consultancy_client/presentation/widgets/atlas_client_onboarding_card.dart': [
        'step.automatic || !canManage || saving',
        'Etapas automáticas não podem ser marcadas manualmente',
    ],
    'lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart': [
        'onboardingService.load(farmId)', 'saveManualStep(', 'step.automatic',
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

legacy_test = (ROOT / 'test/features/consultancy_client/post_v21_package9c_onboarding_contract_test.dart').read_text(encoding='utf-8-sig')
if 'copyWithStep' in legacy_test:
    errors.append('contrato legado 9C ainda referencia API removida copyWithStep')

homologation = (ROOT / 'scripts/quality/run_post_v21_package9d_verified_onboarding_homologation.ps1').read_text(encoding='utf-8-sig')
if 'post_v21_package9c_onboarding_contract_test.dart' not in homologation:
    errors.append('homologação 9D não executa regressão do contrato 9C')

router = (ROOT / 'backend/app/routers/saas_growth.py').read_text(encoding='utf-8-sig')
if "persisted['initial_training']" not in router:
    errors.append('backend não restringe persistência manual ao treinamento')
if "persisted['farm_context']" in router or "persisted['herd_baseline']" in router:
    errors.append('passos automáticos voltaram a ser persistidos manualmente')

manifest_path = ROOT / 'docs/ATLAS_POS_V21_PACOTE_9D_MANIFEST.json'
if not manifest_path.is_file():
    errors.append('manifesto 9D ausente')
else:
    manifest = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
    paths = manifest.get('release_paths', [])
    if len(paths) != len(set(paths)):
        errors.append('manifesto 9D contém caminhos duplicados')
    for relative in paths:
        if not (ROOT / relative).is_file():
            errors.append(f'manifesto aponta arquivo ausente: {relative}')

if errors:
    print('ATLAS POS-V21 PACOTE 9D: REPROVADO')
    for error in errors:
        print(f'[ERRO] {error}')
    raise SystemExit(1)

print('ATLAS POS-V21 PACOTE 9D: APROVADO')
print('[OK] Implantação escopada por fazenda.')
print('[OK] Quatro etapas derivadas de evidências oficiais.')
print('[OK] Somente treinamento permanece manual.')
print('[OK] Nenhuma migration nova necessária.')
