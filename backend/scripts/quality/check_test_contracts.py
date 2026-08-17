from pathlib import Path
import ast

ROOT = Path(__file__).resolve().parents[2]
TESTS = ROOT / 'tests'
required = {'test_auth_and_sync.py', 'test_quality_platform.py', 'test_security_and_tenant.py'}
missing = sorted(name for name in required if not (TESTS / name).exists())
parsed = 0
for path in TESTS.rglob('test_*.py'):
    ast.parse(path.read_text(encoding='utf-8'))
    parsed += 1
if missing:
    raise SystemExit(f'FALHA: contratos obrigatórios ausentes: {missing}')
print(f'OK: {parsed} arquivos de teste compilados; contratos essenciais presentes.')
