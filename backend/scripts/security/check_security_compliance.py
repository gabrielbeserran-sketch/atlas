from pathlib import Path
required=['security_compliance_models.py','routers/security_compliance.py']
base=Path(__file__).resolve().parents[2]/'app'
missing=[x for x in required if not (base/x).exists()]
if missing: raise SystemExit(f'Arquivos ausentes: {missing}')
print('Security & Compliance: estrutura presente.')
