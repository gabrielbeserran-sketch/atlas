from __future__ import annotations
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'docs/architecture/11A/generated/atlas_architecture_map_11a.json'
POL=ROOT/'docs/architecture/11A/architecture_policy_11a.json'
REQ=[
 'docs/architecture/11A/ATLAS_11A_AUDITORIA_INTEGRAL.md',
 'docs/architecture/11A/ATLAS_11A_DOMAIN_OWNERSHIP.csv',
 'docs/architecture/11A/ATLAS_11A_ORPHAN_CANDIDATES.csv',
 'docs/architecture/11A/ATLAS_11A_DUPLICATE_DECLARATIONS.csv',
 'docs/architecture/WHERE_TO_CHANGE_ATLAS.md',
]
def main():
 errs=[]
 for r in REQ:
  if not (ROOT/r).is_file(): errs.append('ausente: '+r)
 if not BASE.is_file(): errs.append('mapa 11A ausente')
 if not POL.is_file(): errs.append('policy 11A ausente')
 if errs:
  print('\n'.join(errs)); print('ATLAS 11A GOVERNANCE: REPROVADO'); return 1
 arch=json.loads(BASE.read_text(encoding='utf-8'))
 pol=json.loads(POL.read_text(encoding='utf-8'))
 s=arch['summary']; debt=pol['debt_baseline']
 for k in ['dart_files','modules','duplicate_public_declarations','likely_orphans']:
  if s.get(k)!=debt.get(k): errs.append(f'baseline documental divergente em {k}')
 if not (ROOT/'lib/features').is_dir() or not (ROOT/'lib/core').is_dir(): errs.append('estrutura Flutter base ausente')
 if not (ROOT/'backend/alembic/versions').is_dir(): errs.append('Alembic ausente')
 print(json.dumps({'summary':s,'errors':errs},ensure_ascii=False,indent=2))
 if errs:
  print('ATLAS 11A GOVERNANCE: REPROVADO'); return 1
 print('ATLAS 11A GOVERNANCE: APROVADO')
 print('[OK] Snapshot integral documentado.')
 print('[OK] Ownership de módulos catalogado.')
 print('[OK] Dívida arquitetural congelada como baseline, sem remoção automática.')
 print('[OK] Estratégia feature-first + modular monolith formalizada.')
 return 0
if __name__=='__main__': raise SystemExit(main())
