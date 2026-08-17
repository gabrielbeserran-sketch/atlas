from __future__ import annotations

import csv
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / 'lib'
BACKEND_ROUTERS = ROOT / 'backend' / 'app' / 'routers'
TEST = ROOT / 'test'

ROUTE_RE = re.compile(
    r'@router\.(get|post|patch|put|delete)\(\s*["\']([^"\']*)', re.S
)
PREFIX_RE = re.compile(r'APIRouter\(\s*prefix\s*=\s*["\']([^"\']*)', re.S)
HTTP_CALL_RE = re.compile(
    r"(?:[A-Za-z_][A-Za-z0-9_]*\.)?(?:send|request|requestList)\(\s*['\"](GET|POST|PATCH|PUT|DELETE)['\"]\s*,\s*['\"]([^'\"]+)['\"]",
    re.S,
)
URI_REQUEST_RE = re.compile(
    r"(?:request|requestList)\(\s*['\"](GET|POST|PATCH|PUT|DELETE)['\"]\s*,\s*([A-Za-z_][A-Za-z0-9_]*)\.toString\(\)",
    re.S,
)
URI_DECL_RE = re.compile(
    r"(?:final|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*Uri\(\s*path\s*:\s*['\"]([^'\"]+)['\"]",
    re.S,
)
SCREEN_RE = re.compile(r'class\s+([A-Za-z_][A-Za-z0-9_]*Screen)\s+extends')


def normalize_backend_path(path: str) -> str:
    return re.sub(r'\{[^}]+\}', '{}', path)


def normalize_frontend_path(path: str) -> str:
    path = path.split('?', 1)[0]
    path = re.sub(r'\$\{[^}]+\}', '{}', path)
    path = re.sub(r'\$[A-Za-z_][A-Za-z0-9_.]*', '{}', path)
    return path


def backend_routes() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for path in sorted(BACKEND_ROUTERS.glob('*.py')):
        text = path.read_text(encoding='utf-8', errors='ignore')
        prefix_match = PREFIX_RE.search(text)
        prefix = prefix_match.group(1) if prefix_match else ''
        for match in ROUTE_RE.finditer(text):
            rows.append(
                {
                    'method': match.group(1).upper(),
                    'path': prefix + match.group(2),
                    'file': str(path.relative_to(ROOT)),
                }
            )
    return rows


def dart_files() -> list[Path]:
    return sorted(LIB.rglob('*.dart'))


def frontend_calls(files: list[Path]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for path in files:
        text = path.read_text(encoding='utf-8', errors='ignore')
        seen: set[tuple[str, str]] = set()
        for match in HTTP_CALL_RE.finditer(text):
            method = match.group(1).upper()
            route = match.group(2)
            key = (method, route)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    'method': method,
                    'path': route,
                    'normalized_path': normalize_frontend_path(route),
                    'file': str(path.relative_to(ROOT)),
                }
            )

        uri_paths = {name: route for name, route in URI_DECL_RE.findall(text)}
        for match in URI_REQUEST_RE.finditer(text):
            method = match.group(1).upper()
            route = uri_paths.get(match.group(2))
            if not route:
                continue
            key = (method, route)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    'method': method,
                    'path': route,
                    'normalized_path': normalize_frontend_path(route),
                    'file': str(path.relative_to(ROOT)),
                }
            )
    return rows


def screen_matrix(files: list[Path]) -> tuple[list[dict[str, object]], list[str]]:
    identifier_counts: Counter[str] = Counter()
    declarations: list[tuple[str, Path, str]] = []

    for path in files:
        text = path.read_text(encoding='utf-8', errors='ignore')
        identifier_counts.update(re.findall(r'\b[A-Za-z_][A-Za-z0-9_]*Screen\b', text))
        for match in SCREEN_RE.finditer(text):
            declarations.append((match.group(1), path, text))

    matrix: list[dict[str, object]] = []
    orphans: list[str] = []
    for class_name, path, text in declarations:
        calls = [
            {
                'method': match.group(1).upper(),
                'path': match.group(2),
            }
            for match in HTTP_CALL_RE.finditer(text)
        ]
        refs = identifier_counts[class_name]
        if refs <= 2:
            orphans.append(f'{class_name} ({path.relative_to(ROOT)})')
        matrix.append(
            {
                'screen': class_name,
                'file': str(path.relative_to(ROOT)),
                'references': refs,
                'network_calls': calls,
                'uses_shared_preferences': 'SharedPreferences' in text,
                'action_callbacks': len(
                    re.findall(r'\b(?:onPressed|onTap|onLongPress|onSubmitted)\s*:', text)
                ),
                'disabled_actions': len(
                    re.findall(r'\b(?:onPressed|onTap|onLongPress)\s*:\s*null\b', text)
                ),
            }
        )
    return matrix, orphans


def main() -> int:
    files = dart_files()
    routes = backend_routes()
    calls = frontend_calls(files)
    matrix, orphan_screens = screen_matrix(files)

    backend_normalized = {
        (row['method'], normalize_backend_path(row['path'])) for row in routes
    }
    unmatched_calls = [
        row
        for row in calls
        if (row['method'], row['normalized_path']) not in backend_normalized
    ]

    route_counts = Counter((row['method'], row['path']) for row in routes)
    duplicate_backend_routes = [
        f'{method} {path} x{count}'
        for (method, path), count in route_counts.items()
        if count > 1
    ]

    placeholder_tests = [
        str(path.relative_to(ROOT))
        for path in sorted(TEST.rglob('*placeholder_test.dart'))
    ]

    disabled_actions: list[str] = []
    todo_fixme: list[str] = []
    shared_preferences_files: list[str] = []
    demo_seed_files: list[str] = []

    for path in files:
        text = path.read_text(encoding='utf-8', errors='ignore')
        rel = str(path.relative_to(ROOT))
        if re.search(r'\b(?:onPressed|onTap|onLongPress)\s*:\s*null\b', text):
            disabled_actions.append(rel)
        if re.search(r'\b(?:TODO|FIXME)\b', text):
            todo_fixme.append(rel)
        if 'SharedPreferences' in text:
            shared_preferences_files.append(rel)
        if re.search(r'\b(?:demo_|case_demo|weather_demo|demonstrativ[oa])\b', text, re.I):
            demo_seed_files.append(rel)

    consumers_text = ''
    consumer_roots = [ROOT / 'lib', ROOT / 'backend' / 'tests', ROOT / 'scripts', ROOT / 'admin_portal']
    for base in consumer_roots:
        if not base.exists():
            continue
        for path in base.rglob('*'):
            if not path.is_file() or any(part in {'.venv', '__pycache__', 'build'} for part in path.parts):
                continue
            if path.suffix.lower() not in {'.dart', '.py', '.ps1', '.js', '.ts', '.html'}:
                continue
            consumers_text += '\n' + path.read_text(encoding='utf-8', errors='ignore')

    frontend_consumed = {
        (row['method'], row['normalized_path']) for row in calls
    }
    routes_without_obvious_consumer: list[str] = []
    for row in routes:
        normalized = normalize_backend_path(row['path'])
        if (row['method'], normalized) in frontend_consumed:
            continue
        literal = re.sub(r'\{[^}]+\}', '', row['path']).rstrip('/')
        if literal and literal in consumers_text:
            continue
        routes_without_obvious_consumer.append(f"{row['method']} {row['path']}")

    report = {
        'backend_route_count': len(routes),
        'frontend_http_call_count': len(calls),
        'screen_count': len(matrix),
        'duplicate_backend_routes': duplicate_backend_routes,
        'frontend_calls_without_backend_route': unmatched_calls,
        'orphan_screens': orphan_screens,
        'placeholder_tests': placeholder_tests,
        'disabled_action_files': disabled_actions,
        'todo_fixme_files': todo_fixme,
        'shared_preferences_file_count': len(shared_preferences_files),
        'shared_preferences_files': shared_preferences_files,
        'shared_preferences_local_only_count': sum(
            1
            for rel in shared_preferences_files
            if not any(
                token in (ROOT / rel).read_text(encoding='utf-8', errors='ignore')
                for token in ('AtlasHttpClient', '.send(', '/livestock/', '/operations/')
            )
        ),
        'demo_seed_file_count': len(demo_seed_files),
        'demo_seed_files': demo_seed_files,
        'routes_without_obvious_consumer_count': len(routes_without_obvious_consumer),
        'routes_without_obvious_consumer': routes_without_obvious_consumer,
    }

    json_path = ROOT / 'ATLAS_MARCO4_ROUTE_SCREEN_MATRIX.json'
    json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')

    routes_csv_path = ROOT / 'ATLAS_MARCO4_ROTAS.csv'
    with routes_csv_path.open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=['method', 'path', 'file', 'obvious_consumer'])
        writer.writeheader()
        missing = set(routes_without_obvious_consumer)
        for row in routes:
            key = f"{row['method']} {row['path']}"
            writer.writerow({
                'method': row['method'],
                'path': row['path'],
                'file': row['file'],
                'obvious_consumer': key not in missing,
            })

    csv_path = ROOT / 'ATLAS_MARCO4_TELAS.csv'
    with csv_path.open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                'screen',
                'file',
                'references',
                'network_calls',
                'uses_shared_preferences',
                'action_callbacks',
                'disabled_actions',
            ],
        )
        writer.writeheader()
        for row in matrix:
            csv_row = dict(row)
            csv_row['network_calls'] = '; '.join(
                f"{item['method']} {item['path']}" for item in row['network_calls']
            )
            writer.writerow(csv_row)

    blocking = bool(
        duplicate_backend_routes
        or unmatched_calls
        or orphan_screens
        or placeholder_tests
        or disabled_actions
        or todo_fixme
    )

    print(json.dumps({
        'backend_route_count': len(routes),
        'frontend_http_call_count': len(calls),
        'screen_count': len(matrix),
        'duplicate_backend_routes': duplicate_backend_routes,
        'frontend_calls_without_backend_route': unmatched_calls,
        'orphan_screens': orphan_screens,
        'placeholder_tests': placeholder_tests,
        'disabled_action_files': disabled_actions,
        'todo_fixme_files': todo_fixme,
        'shared_preferences_file_count': len(shared_preferences_files),
        'shared_preferences_local_only_count': report['shared_preferences_local_only_count'],
        'demo_seed_file_count': len(demo_seed_files),
        'routes_without_obvious_consumer_count': len(routes_without_obvious_consumer),
    }, ensure_ascii=False, indent=2))
    print('\nATLAS MARCO 4 MATRIX:', 'FAIL' if blocking else 'OK')
    return 1 if blocking else 0


if __name__ == '__main__':
    raise SystemExit(main())
