from pathlib import Path
import ast, sys
ROOT=Path(__file__).resolve().parents[2]
errors=[]
for p in (ROOT/'tests').glob('test_*.py'):
    if p.name.startswith(('test_sprints_','test_phase','test_phases','test_blocks_','test_advanced_blocks_')):
        errors.append(f'teste legado ativo: {p.name}')
for rel in ('app/core','app/models','app/repositories','app/services','app/routers','app/schemas','app/workers'):
    if not (ROOT/rel).is_dir(): errors.append(f'pacote ausente: {rel}')
found={}
for p in (ROOT/'app').rglob('*.py'):
    try: tree=ast.parse(p.read_text(encoding='utf-8'),filename=str(p))
    except SyntaxError as exc: errors.append(f'sintaxe: {p}: {exc}'); continue
    for n in ast.walk(tree):
        if isinstance(n,ast.ClassDef):
            for s in n.body:
                if isinstance(s,(ast.Assign,ast.AnnAssign)):
                    target=s.targets[0] if isinstance(s,ast.Assign) else s.target
                    value=s.value
                    if isinstance(target,ast.Name) and target.id=='__tablename__' and isinstance(value,ast.Constant) and isinstance(value.value,str):
                        if value.value in found: errors.append(f'tabela duplicada {value.value}: {found[value.value]} e {p}:{n.name}')
                        found[value.value]=f'{p}:{n.name}'
if errors:
    print('FALHA NA CONSOLIDACAO')
    print('\n'.join(f'- {e}' for e in errors))
    print('Execute: python scripts/quality/archive_legacy_tests.py')
    sys.exit(1)
print(f'OK: arquitetura consolidada; {len(found)} tabelas únicas; testes legados arquivados.')
