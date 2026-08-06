#!/usr/bin/env python3
from __future__ import annotations
import argparse, json
from pathlib import Path

def load(path: str):
    return json.loads(Path(path).read_text(encoding='utf-8'))

def index_files(data):
    return {x['path']: x for x in data.get('files', [])}

def main():
    p=argparse.ArgumentParser(description='Compara duas versões do mapa vivo do Projeto Atlas.')
    p.add_argument('baseline')
    p.add_argument('current')
    p.add_argument('--out', default='docs/architecture/ATLAS_ARCHITECTURE_DIFF.md')
    a,b=load(p.parse_args().baseline),load(p.parse_args().current)
    args=p.parse_args()
    fa,fb=index_files(a),index_files(b)
    added=sorted(set(fb)-set(fa)); removed=sorted(set(fa)-set(fb))
    changed=[]
    for path in sorted(set(fa)&set(fb)):
        keys=('lines','bytes','imports_local','public_declarations','role','module')
        if any(fa[path].get(k)!=fb[path].get(k) for k in keys): changed.append(path)
    da=set(a.get('duplicate_public_declarations',{})); db=set(b.get('duplicate_public_declarations',{}))
    new_dups=sorted(db-da); resolved_dups=sorted(da-db)
    ma={x['module'] for x in a.get('modules',[])}; mb={x['module'] for x in b.get('modules',[])}
    lines=['# Projeto Atlas — Diferenças Arquiteturais','',
           f'- Arquivos adicionados: **{len(added)}**',f'- Arquivos removidos: **{len(removed)}**',
           f'- Arquivos alterados estruturalmente: **{len(changed)}**',f'- Novas declarações públicas repetidas: **{len(new_dups)}**',
           f'- Repetições resolvidas: **{len(resolved_dups)}**','']
    sections=[('Arquivos adicionados',added),('Arquivos removidos',removed),('Arquivos alterados',changed),
              ('Novas duplicidades públicas',new_dups),('Duplicidades resolvidas',resolved_dups),
              ('Módulos adicionados',sorted(mb-ma)),('Módulos removidos',sorted(ma-mb))]
    for title,items in sections:
        lines += [f'## {title}','']
        lines += [f'- `{x}`' for x in items] if items else ['Nenhum.']
        lines.append('')
    lines += ['## Regra de decisão','',
              'Uma alteração estrutural só deve ser aprovada após revisar novas duplicidades, arquivos removidos, módulos novos e mudanças nas dependências dos módulos canônicos.']
    out=Path(args.out); out.parent.mkdir(parents=True,exist_ok=True); out.write_text('\n'.join(lines),encoding='utf-8')
    print(out)
if __name__=='__main__': main()
