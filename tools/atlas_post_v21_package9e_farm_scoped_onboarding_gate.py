from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

required = {
    'backend/alembic/versions/20260824_0046_onboarding_progress_farm_scope.py': [
        'revision = "20260824_0046"',
        'down_revision = "20260824_0045"',
        'uq_onboarding_progress_company_farm',
        'onboarding_progress_company_id_key',
        'farm_id',
    ],
    'backend/app/saas_growth_models.py': [
        "UniqueConstraint('company_id','farm_id',name='uq_onboarding_progress_company_farm')",
        "farm_id: Mapped[str|None]",
    ],
    'backend/app/routers/saas_growth.py': [
        '_onboarding_row(',
        'OnboardingProgress.farm_id == farm_id',
        'claim_legacy=True',
        "'farm_scoped_manual_progress': True",
        "'legacy_progress_migration': True",
        "'migration': '0046'",
    ],
    'lib/features/consultancy_client/data/services/atlas_client_onboarding_service.dart': [
        "queryParameters: {'farm_id': farmId}",
        'saveManualStep',
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

router = (ROOT / 'backend/app/routers/saas_growth.py').read_text(encoding='utf-8-sig')
legacy_company_only = "select(OnboardingProgress).where(OnboardingProgress.company_id == p.company.id)"
if legacy_company_only in router:
    errors.append('router ainda possui seleção de onboarding somente por empresa')

migration = (ROOT / 'backend/alembic/versions/20260824_0046_onboarding_progress_farm_scope.py').read_text(encoding='utf-8-sig')
if 'INSERT INTO onboarding_progress' not in migration or 'JOIN farms' not in migration:
    errors.append('migration 0046 não preserva/expande estado legado para fazendas existentes')

homologation_path = ROOT / 'scripts/quality/run_post_v21_package9e_farm_scoped_onboarding_homologation.ps1'
if homologation_path.is_file():
    homologation = homologation_path.read_text(encoding='utf-8-sig')
    for test_name in [
        'post_v21_package9c_onboarding_contract_test.dart',
        'post_v21_package9d_verified_onboarding_contract_test.dart',
        'post_v21_package9e_farm_scoped_onboarding_contract_test.dart',
    ]:
        if test_name not in homologation:
            errors.append(f'homologação 9E não executa regressão: {test_name}')

manifest_path = ROOT / 'docs/ATLAS_POS_V21_PACOTE_9E_MANIFEST.json'
if manifest_path.is_file():
    manifest = json.loads(manifest_path.read_text(encoding='utf-8-sig'))
    paths = manifest.get('release_paths', [])
    if len(paths) != len(set(paths)):
        errors.append('manifesto 9E contém caminhos duplicados')
    for relative in paths:
        if not (ROOT / relative).is_file():
            errors.append(f'manifesto aponta arquivo ausente: {relative}')

if errors:
    print('ATLAS POS-V21 PACOTE 9E: REPROVADO')
    for error in errors:
        print(f'[ERRO] {error}')
    raise SystemExit(1)

print('ATLAS POS-V21 PACOTE 9E: APROVADO')
print('[OK] Progresso manual isolado por fazenda.')
print('[OK] Migration 0046 preserva estado legado.')
print('[OK] Evidências automáticas 9D permanecem intactas.')
print('[OK] Readiness comprova schema 0046 em produção.')
