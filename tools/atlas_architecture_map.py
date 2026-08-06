#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter, defaultdict, deque
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

IMPORT_RE = re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]", re.MULTILINE)
EXPORT_RE = re.compile(r"^\s*export\s+['\"]([^'\"]+)['\"]", re.MULTILINE)
DECL_RE = re.compile(
    r"^\s*(?:abstract\s+|base\s+|final\s+|interface\s+|sealed\s+)?"
    r"(class|enum|mixin|extension|typedef)\s+([A-Za-z_]\w*)",
    re.MULTILINE,
)
ROUTE_RE = re.compile(r"(?:MaterialPageRoute|CupertinoPageRoute)\s*<[^>]*>?\s*\(|Navigator\.(?:push|pushNamed|pushReplacement|pushReplacementNamed)")
WIDGET_RE = re.compile(r"\b(?:StatelessWidget|StatefulWidget)\b")
SERVICE_HINT_RE = re.compile(r"(?:Service|Engine|Repository|Adapter|Controller|Provider|Store|Storage|Loader|Manager)$")
MODEL_HINT_RE = re.compile(r"(?:Model|Data|Result|Request|Response|Entity|Item|Record|Summary|Context|Decision|Action|Alert|Scenario|Strategy|Conflict|Impact|Memory)$")

@dataclass
class FileInfo:
    path: str
    module: str
    layer: str
    role: str
    lines: int
    bytes: int
    imports_local: list[str]
    imports_external: list[str]
    exports_local: list[str]
    declarations: list[str]
    public_declarations: list[str]
    is_screen: bool
    has_navigation: bool


def norm(path: Path) -> str:
    return path.as_posix()


def module_and_layer(rel: Path) -> tuple[str, str]:
    parts = rel.parts
    if len(parts) >= 3 and parts[0] == 'features':
        module = parts[1]
        layer = parts[2] if parts[2] in {'data', 'domain', 'presentation'} else 'other'
        return module, layer
    if parts and parts[0] == 'core':
        return 'core', parts[1] if len(parts) > 1 else 'root'
    return 'app', parts[0] if parts else 'root'


def resolve_local_uri(current: Path, uri: str, lib_root: Path) -> Path | None:
    if uri.startswith('dart:') or uri.startswith('package:flutter'):
        return None
    if uri.startswith('package:'):
        match = re.match(r'package:[^/]+/(.+)$', uri)
        if not match:
            return None
        candidate = lib_root / match.group(1)
    else:
        candidate = (current.parent / uri).resolve()
    try:
        candidate.relative_to(lib_root.resolve())
    except ValueError:
        return None
    return candidate


def classify_role(path: Path, declarations: list[str], text: str) -> str:
    stem = path.stem
    if stem.endswith('_screen') or WIDGET_RE.search(text):
        return 'screen/widget'
    public = [name for name in declarations if not name.startswith('_')]
    if any(SERVICE_HINT_RE.search(name) for name in public) or any(x in stem for x in ('service', 'engine', 'repository', 'adapter')):
        return 'service/engine'
    if any(MODEL_HINT_RE.search(name) for name in public) or '/models/' in norm(path):
        return 'model/contract'
    if stem in {'app', 'main', 'routes', 'router'} or 'route' in stem:
        return 'bootstrap/routing'
    return 'support'


def scan(lib_root: Path) -> tuple[list[FileInfo], dict[str, set[str]]]:
    files: list[FileInfo] = []
    graph: dict[str, set[str]] = defaultdict(set)
    for path in sorted(lib_root.rglob('*.dart')):
        rel = path.relative_to(lib_root)
        text = path.read_text(encoding='utf-8', errors='replace')
        declarations = [name for _, name in DECL_RE.findall(text)]
        public = [name for name in declarations if not name.startswith('_')]
        local_imports: list[str] = []
        external_imports: list[str] = []
        local_exports: list[str] = []
        for uri in IMPORT_RE.findall(text):
            resolved = resolve_local_uri(path, uri, lib_root)
            if resolved and resolved.exists():
                target = norm(resolved.relative_to(lib_root))
                local_imports.append(target)
                graph[norm(rel)].add(target)
            else:
                external_imports.append(uri)
        for uri in EXPORT_RE.findall(text):
            resolved = resolve_local_uri(path, uri, lib_root)
            if resolved and resolved.exists():
                target = norm(resolved.relative_to(lib_root))
                local_exports.append(target)
                graph[norm(rel)].add(target)
        module, layer = module_and_layer(rel)
        files.append(FileInfo(
            path=norm(rel), module=module, layer=layer,
            role=classify_role(rel, declarations, text),
            lines=text.count('\n') + 1, bytes=path.stat().st_size,
            imports_local=sorted(set(local_imports)),
            imports_external=sorted(set(external_imports)),
            exports_local=sorted(set(local_exports)),
            declarations=declarations,
            public_declarations=public,
            is_screen=rel.stem.endswith('_screen') or 'Screen' in public,
            has_navigation=bool(ROUTE_RE.search(text)),
        ))
    return files, graph


def reachable(graph: dict[str, set[str]], roots: Iterable[str]) -> set[str]:
    seen: set[str] = set()
    queue = deque(roots)
    while queue:
        node = queue.popleft()
        if node in seen:
            continue
        seen.add(node)
        queue.extend(graph.get(node, set()) - seen)
    return seen


def write_reports(lib_root: Path, out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    files, graph = scan(lib_root)
    paths = {f.path for f in files}
    indegree = Counter()
    for source, targets in graph.items():
        for target in targets:
            indegree[target] += 1

    declarations: dict[str, list[str]] = defaultdict(list)
    for f in files:
        for name in f.public_declarations:
            declarations[name].append(f.path)
    duplicate_declarations = {k: v for k, v in declarations.items() if len(v) > 1}

    roots = [x for x in ('main.dart', 'app.dart') if x in paths]
    roots += [f.path for f in files if f.role == 'bootstrap/routing']
    used = reachable(graph, roots)
    likely_orphans = [
        f.path for f in files
        if f.path not in used and indegree[f.path] == 0 and f.path not in roots
    ]

    module_rows = []
    by_module: dict[str, list[FileInfo]] = defaultdict(list)
    for f in files:
        by_module[f.module].append(f)
    for module, group in sorted(by_module.items()):
        deps = set()
        consumers = set()
        group_paths = {f.path for f in group}
        for f in group:
            for target in graph.get(f.path, set()):
                target_file = next((x for x in files if x.path == target), None)
                if target_file and target_file.module != module:
                    deps.add(target_file.module)
        for source, targets in graph.items():
            source_file = next((x for x in files if x.path == source), None)
            if source_file and source_file.module != module and targets & group_paths:
                consumers.add(source_file.module)
        module_rows.append({
            'module': module,
            'files': len(group),
            'screens_widgets': sum(f.role == 'screen/widget' for f in group),
            'services_engines': sum(f.role == 'service/engine' for f in group),
            'models_contracts': sum(f.role == 'model/contract' for f in group),
            'local_dependency_count': len(deps),
            'depends_on': ', '.join(sorted(deps)),
            'used_by': ', '.join(sorted(consumers)),
            'lines': sum(f.lines for f in group),
        })

    with (out / 'atlas_file_inventory.csv').open('w', newline='', encoding='utf-8-sig') as fh:
        fieldnames = ['path','module','layer','role','lines','bytes','local_import_count','external_import_count','public_declarations','is_screen','has_navigation','incoming_references']
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for f in files:
            writer.writerow({
                'path': f.path, 'module': f.module, 'layer': f.layer, 'role': f.role,
                'lines': f.lines, 'bytes': f.bytes,
                'local_import_count': len(f.imports_local),
                'external_import_count': len(f.imports_external),
                'public_declarations': ' | '.join(f.public_declarations),
                'is_screen': f.is_screen, 'has_navigation': f.has_navigation,
                'incoming_references': indegree[f.path],
            })

    with (out / 'atlas_module_matrix.csv').open('w', newline='', encoding='utf-8-sig') as fh:
        writer = csv.DictWriter(fh, fieldnames=list(module_rows[0].keys()))
        writer.writeheader(); writer.writerows(module_rows)

    with (out / 'atlas_dependency_edges.csv').open('w', newline='', encoding='utf-8-sig') as fh:
        writer = csv.DictWriter(fh, fieldnames=['source','target'])
        writer.writeheader()
        for source in sorted(graph):
            for target in sorted(graph[source]):
                writer.writerow({'source': source, 'target': target})

    with (out / 'atlas_duplicate_public_declarations.csv').open('w', newline='', encoding='utf-8-sig') as fh:
        writer = csv.DictWriter(fh, fieldnames=['declaration','occurrences','files'])
        writer.writeheader()
        for name, locations in sorted(duplicate_declarations.items()):
            writer.writerow({'declaration': name, 'occurrences': len(locations), 'files': ' | '.join(locations)})

    payload = {
        'summary': {
            'dart_files': len(files),
            'modules': len(by_module),
            'screens_widgets': sum(f.role == 'screen/widget' for f in files),
            'services_engines': sum(f.role == 'service/engine' for f in files),
            'models_contracts': sum(f.role == 'model/contract' for f in files),
            'local_dependency_edges': sum(len(v) for v in graph.values()),
            'duplicate_public_declarations': len(duplicate_declarations),
            'likely_orphans': len(likely_orphans),
            'roots': sorted(set(roots)),
        },
        'modules': module_rows,
        'duplicate_public_declarations': duplicate_declarations,
        'likely_orphans': likely_orphans,
        'files': [asdict(f) | {'incoming_references': indegree[f.path]} for f in files],
    }
    (out / 'atlas_architecture_map.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')

    top_modules = sorted(module_rows, key=lambda x: x['files'], reverse=True)[:20]
    md = []
    md.append('# Projeto Atlas — Mapa Vivo da Arquitetura\n')
    md.append('Este documento foi gerado automaticamente a partir do código Dart presente na pasta `lib`.')
    md.append('Ele deve ser regenerado antes de alterações estruturais importantes.\n')
    md.append('## Resumo\n')
    for key, value in payload['summary'].items():
        if key != 'roots':
            md.append(f'- **{key.replace("_", " ").title()}:** {value}')
    md.append(f'- **Pontos de entrada analisados:** {", ".join(payload["summary"]["roots"]) or "nenhum localizado"}\n')
    md.append('## Regra arquitetural oficial\n')
    md.append('```text\nDados dos módulos → BI/indicadores → Decision Engine V2 → Executive Brain → Plano de Ação/Alertas → Copiloto/Painéis → Memória\n```\n')
    md.append('Os painéis apresentam resultados; não devem criar motores decisórios paralelos. Adaptadores canônicos devem traduzir estruturas existentes, sem repetir regras de negócio.\n')
    md.append('## Maiores módulos por quantidade de arquivos\n')
    md.append('| Módulo | Arquivos | Telas/widgets | Serviços/motores | Modelos/contratos | Linhas |')
    md.append('|---|---:|---:|---:|---:|---:|')
    for row in top_modules:
        md.append(f"| {row['module']} | {row['files']} | {row['screens_widgets']} | {row['services_engines']} | {row['models_contracts']} | {row['lines']} |")
    md.append('\n## Declarações públicas repetidas\n')
    if duplicate_declarations:
        md.append('Estas repetições exigem revisão humana. Uma repetição pode ser legítima em bibliotecas isoladas, mas também pode indicar versões concorrentes do mesmo recurso.\n')
        for name, locations in sorted(duplicate_declarations.items()):
            md.append(f'- **{name}**: ' + '; '.join(f'`{x}`' for x in locations))
    else:
        md.append('Nenhuma declaração pública repetida foi encontrada.')
    md.append('\n## Arquivos possivelmente órfãos\n')
    md.append('A lista abaixo é heurística: arquivos carregados dinamicamente ou usados fora da pasta `lib` podem aparecer como órfãos. Eles não devem ser apagados automaticamente.\n')
    for path in likely_orphans[:200]:
        md.append(f'- `{path}`')
    if len(likely_orphans) > 200:
        md.append(f'- ... e mais {len(likely_orphans)-200} arquivos no JSON completo.')
    md.append('\n## Procedimento obrigatório antes de cada nova funcionalidade\n')
    md.append('1. Procurar modelo, serviço, tela e regra equivalentes no inventário.')
    md.append('2. Verificar dependências recebidas e consumidores do módulo afetado.')
    md.append('3. Reutilizar ou ampliar a implementação existente.')
    md.append('4. Criar adaptador quando os formatos forem diferentes.')
    md.append('5. Executar `flutter analyze` antes de registrar a entrega como concluída.')
    md.append('6. Regenerar este mapa e comparar o resultado com a versão anterior.\n')
    md.append('## Arquivos complementares\n')
    md.append('- `atlas_architecture_map.json`: visão completa, adequada para comparação automática.')
    md.append('- `atlas_module_matrix.csv`: matriz de módulos e dependências.')
    md.append('- `atlas_file_inventory.csv`: inventário de todos os arquivos Dart.')
    md.append('- `atlas_dependency_edges.csv`: relações de importação/exportação.')
    md.append('- `atlas_duplicate_public_declarations.csv`: declarações públicas repetidas.')
    (out / 'PROJETO_ATLAS_MAPA_VIVO_DA_ARQUITETURA.md').write_text('\n'.join(md), encoding='utf-8')

    print(json.dumps(payload['summary'], ensure_ascii=False, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description='Gera o mapa vivo da arquitetura Dart/Flutter do Projeto Atlas.')
    parser.add_argument('--lib', default='lib', help='Caminho da pasta lib.')
    parser.add_argument('--out', default='docs/architecture', help='Pasta de saída.')
    args = parser.parse_args()
    lib_root = Path(args.lib).resolve()
    if not lib_root.is_dir():
        raise SystemExit(f'Pasta lib não encontrada: {lib_root}')
    write_reports(lib_root, Path(args.out).resolve())

if __name__ == '__main__':
    main()
