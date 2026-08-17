from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
limits = {'max_router_lines': 1200, 'max_service_lines': 1500}
violations = []
for folder, limit in [('routers', limits['max_router_lines']), ('services', limits['max_service_lines'])]:
    for path in (ROOT / 'app' / folder).glob('*.py'):
        lines = len(path.read_text(encoding='utf-8').splitlines())
        if lines > limit:
            violations.append(f'{path.relative_to(ROOT)}: {lines}>{limit}')
if violations:
    print('ATENÇÃO: arquivos acima do orçamento:')
    print('\n'.join(f'- {item}' for item in violations))
else:
    print('OK: routers e services dentro do orçamento estático de tamanho.')
