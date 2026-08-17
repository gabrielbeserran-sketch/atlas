from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
commands = [
    [sys.executable, 'scripts/quality/check_duplicate_tablenames.py'],
    [sys.executable, 'scripts/quality/check_consolidated_architecture.py'],
    [sys.executable, 'scripts/quality/check_route_declarations.py'],
    [sys.executable, 'scripts/quality/check_openapi.py'],
    [sys.executable, 'scripts/quality/check_test_contracts.py'],
    [sys.executable, 'scripts/quality/check_performance_budget.py'],
    [sys.executable, 'scripts/quality/check_infrastructure_contract.py'],
    [sys.executable, '-m', 'pytest', '-q'],
]
for command in commands:
    print('>', ' '.join(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)
print('OK: gate dos Ciclos 13 a 15 aprovado.')
