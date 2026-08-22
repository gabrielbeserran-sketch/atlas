from __future__ import annotations

import ast
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
LIB = ROOT / "lib"


def main() -> int:
    result: dict[str, object] = {}

    python_errors: list[str] = []
    for path in BACKEND.rglob("*.py"):
        if any(part in {".venv", "__pycache__"} for part in path.parts):
            continue
        try:
            ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
        except SyntaxError as exc:
            python_errors.append(f"{path.relative_to(ROOT)}: {exc}")
    result["python_syntax_errors"] = python_errors

    missing_imports: list[str] = []
    for path in LIB.rglob("*.dart"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for target in re.findall(r"import 'package:projeto_atlas/([^']+)'", text):
            if not (LIB / target).exists():
                missing_imports.append(f"{path.relative_to(ROOT)} -> {target}")
    result["dart_missing_internal_imports"] = missing_imports

    authz = (BACKEND / "app" / "authz.py").read_text(encoding="utf-8")
    known = set(re.findall(r'"([A-Za-z0-9_.]+)"', authz.split("ROLE_PERMISSIONS")[0]))
    required: list[str] = []
    for path in (BACKEND / "app").rglob("*.py"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        required.extend(re.findall(r'require_permission\(["\']([^"\']+)', text))
    result["missing_permission_catalog_entries"] = sorted(set(required) - known)

    routes: list[tuple[str, str]] = []
    for path in (BACKEND / "app" / "routers").glob("*.py"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        prefix_match = re.search(r'APIRouter\(\s*prefix\s*=\s*["\']([^"\']*)', text, re.S)
        prefix = prefix_match.group(1) if prefix_match else ""
        for match in re.finditer(r'@router\.(get|post|patch|put|delete)\(\s*["\']([^"\']*)', text, re.S):
            routes.append((match.group(1).upper(), prefix + match.group(2)))
    counts = Counter(routes)
    result["backend_route_count"] = len(routes)
    result["duplicate_routes"] = [f"{m} {p} x{n}" for (m, p), n in counts.items() if n > 1]

    unsafe_scope: list[str] = []
    for path in (BACKEND / "app" / "routers").glob("*.py"):
        for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            if line.strip() == "if farm_id not in allowed:" or "farm_id not in set(principal.membership.farm_ids or [])" in line:
                unsafe_scope.append(f"{path.relative_to(ROOT)}:{line_no}")
    result["unsafe_farm_scope_checks"] = unsafe_scope

    livestock_router_text = (
        BACKEND / "app" / "routers" / "livestock.py"
    ).read_text(encoding="utf-8", errors="ignore")
    livestock_farm_scope_errors: list[str] = []
    for marker, message in (
        ("def _farm_allowed(\n    db: Session", "escopo central não recebe sessão do banco"),
        ("Farm.company_id == principal.company.id", "escopo central não valida empresa da fazenda"),
        ("Farm.tenant_id == principal.company.tenant_id", "escopo central não valida tenant da fazenda"),
        ('detail="Fazenda não encontrada."', "escopo central não rejeita farm_id externo/inexistente"),
    ):
        if marker not in livestock_router_text:
            livestock_farm_scope_errors.append(message)
    if "_farm_allowed(principal," in livestock_router_text:
        livestock_farm_scope_errors.append(
            "há chamada de _farm_allowed sem validação de empresa/tenant"
        )
    result["livestock_farm_scope_contract_errors"] = livestock_farm_scope_errors

    migrations: dict[str, str | None] = {}
    for path in (BACKEND / "alembic" / "versions").glob("*.py"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        revision = re.search(r'(?<!down_)revision\s*=\s*["\']([^"\']+)', text)
        down = re.search(r'down_revision\s*=\s*["\']([^"\']+)', text)
        if revision:
            migrations[revision.group(1)] = down.group(1) if down else None
    referenced = {value for value in migrations.values() if value}
    result["alembic_revision_count"] = len(migrations)
    result["alembic_heads"] = [rev for rev in migrations if rev not in referenced]
    result["alembic_orphans"] = [rev for rev, down in migrations.items() if down and down not in migrations]

    result["deprecated_http_422_constants"] = sum(
        path.read_text(encoding="utf-8", errors="ignore").count("HTTP_422_UNPROCESSABLE_ENTITY")
        for path in (BACKEND / "app").rglob("*.py")
    )
    result["legacy_pet_icons"] = sum(
        path.read_text(encoding="utf-8", errors="ignore").count("Icons.pets")
        for path in LIB.rglob("*.dart")
    )
    result["fontawesome_refs"] = sum(
        path.read_text(encoding="utf-8", errors="ignore").count("FontAwesome")
        for path in LIB.rglob("*.dart")
    )

    # Contratos críticos Flutter <-> Fazendas. Estes checks impedem regressões
    # que já causaram dados obsoletos e falsos "Fazenda não autorizada".
    session_model = (
        LIB
        / "features"
        / "enterprise_platform"
        / "domain"
        / "models"
        / "atlas_enterprise_remote_session.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    active_context = (LIB / "core" / "auth" / "atlas_active_context.dart").read_text(
        encoding="utf-8", errors="ignore"
    )
    remote_farm = (
        LIB / "features" / "farm" / "domain" / "models" / "atlas_remote_farm.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    farm_storage = (
        LIB / "features" / "farm" / "data" / "services" / "farm_storage_service.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    farm_list = (
        LIB / "features" / "farm" / "presentation" / "screens" / "farm_list_screen.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    environment = (LIB / "core" / "network" / "atlas_environment.dart").read_text(
        encoding="utf-8", errors="ignore"
    )
    home_shell = (LIB / "core" / "navigation" / "atlas_home_shell.dart").read_text(
        encoding="utf-8", errors="ignore"
    )

    farm_frontend_contract_errors: list[str] = []
    for role in ("companyAdministrator", "superAdministrator"):
        if role not in session_model:
            farm_frontend_contract_errors.append(f"role administrativo ausente: {role}")
    if "hasUnrestrictedFarmAccess" not in active_context:
        farm_frontend_contract_errors.append("AtlasActiveContext não usa acesso administrativo canônico")
    for field in ("final int animals;", "final double area;"):
        if field not in remote_farm:
            farm_frontend_contract_errors.append(f"AtlasRemoteFarm sem campo: {field}")
    if ".map(FarmData.fromMap)" not in farm_storage:
        farm_frontend_contract_errors.append("FarmStorage não usa resposta remota como autoridade")
    if "refreshAfterFarmMutation" not in farm_list:
        farm_frontend_contract_errors.append("FarmList não sincroniza sessão após CRUD")
    if "sessionScope.loadContext()" in farm_list:
        farm_frontend_contract_errors.append("FarmList ainda desmonta sessão após CRUD")
    if "http://127.0.0.1:8000/api/v1" not in environment:
        farm_frontend_contract_errors.append("base URL development sem /api/v1")
    if "onFarmSelected: (_) => _navigateToLabel('Dashboard')" in home_shell:
        farm_frontend_contract_errors.append("card de fazenda ainda redireciona indevidamente ao Dashboard")
    if "body = const FarmListScreen(embedded: true);" not in home_shell:
        farm_frontend_contract_errors.append("AtlasHomeShell não deixa FarmList abrir o detalhe canônico da fazenda")
    result["farm_frontend_contract_errors"] = farm_frontend_contract_errors

    # Auditoria dos módulos operacionais já existentes e de suas conexões.
    module_contract_errors: list[str] = []
    module_files = {
        "home_shell": LIB / "core" / "navigation" / "atlas_home_shell.dart",
        "reproduction_overview": LIB / "features" / "animal_reproduction" / "presentation" / "screens" / "reproduction_overview_screen.dart",
        "reproduction_form": LIB / "features" / "animal_reproduction" / "presentation" / "screens" / "animal_reproduction_form_screen.dart",
        "health_overview": LIB / "features" / "animal_health" / "presentation" / "screens" / "health_overview_screen.dart",
        "health_form": LIB / "features" / "animal_health" / "presentation" / "screens" / "animal_health_form_screen.dart",
        "nutrition_overview": LIB / "features" / "nutrition" / "presentation" / "screens" / "nutrition_overview_screen.dart",
        "finance_form": LIB / "features" / "farm_finance" / "presentation" / "screens" / "farm_finance_form_screen.dart",
        "inventory_form": LIB / "features" / "farm_inventory" / "presentation" / "screens" / "farm_inventory_form_screen.dart",
        "agenda_form": LIB / "features" / "farm_agenda" / "presentation" / "screens" / "farm_agenda_form_screen.dart",
        "finance_storage": LIB / "features" / "farm_finance" / "data" / "services" / "farm_finance_storage_service.dart",
        "inventory_storage": LIB / "features" / "farm_inventory" / "data" / "services" / "farm_inventory_storage_service.dart",
        "nutrition_storage": LIB / "features" / "nutrition" / "data" / "services" / "nutrition_storage_service.dart",
        "agenda_storage": LIB / "features" / "farm_agenda" / "data" / "services" / "farm_agenda_storage_service.dart",
    }
    texts = {name: path.read_text(encoding="utf-8", errors="ignore") for name, path in module_files.items()}
    required_existing = {
        "reproduction_form": "AnimalReproductionFormScreen",
        "health_form": "AnimalHealthFormScreen",
        "nutrition_overview": "Nova dieta",
        "finance_form": "FarmFinanceFormScreen",
        "inventory_form": "FarmInventoryFormScreen",
        "agenda_form": "FarmAgendaFormScreen",
    }
    for key, token in required_existing.items():
        if token not in texts[key]:
            module_contract_errors.append(f"funcionalidade existente não localizada: {key} / {token}")
    for label in ("Sanidade", "Reprodução", "Nutrição", "Financeiro", "Estoque", "Agenda"):
        if f"'{label}'" not in texts["home_shell"]:
            module_contract_errors.append(f"módulo ausente do menu/navegação: {label}")
    expected_connections = {
        "finance_storage": ("/livestock/finance/v2",),
        "inventory_storage": ("/livestock/inventory/products", "/livestock/inventory/products/v2"),
        "nutrition_storage": ("/livestock/nutrition/plans",),
        "agenda_storage": ("/operations/tasks",),
        "reproduction_overview": ("Novo evento reprodutivo",),
        "health_overview": ("Novo evento sanitário",),
    }
    for key, tokens in expected_connections.items():
        for token in tokens:
            if token not in texts[key]:
                module_contract_errors.append(f"conexão ausente em {key}: {token}")

    # Agenda: edição precisa preservar a origem técnica quando a tarefa é integrada
    # e usar a categoria apenas para compromissos manuais.
    agenda_storage = texts["agenda_storage"]
    legacy_category_patch = "'source_type': task.category" in agenda_storage
    source_aware_patch = (
        "task.sourceType.trim().isNotEmpty" in agenda_storage
        and "task.category" in agenda_storage
        and "'source_id': task.sourceId" in agenda_storage
    )
    if not (legacy_category_patch or source_aware_patch):
        module_contract_errors.append(
            "Agenda não preserva source_type/source_id nem envia categoria no PATCH"
        )
    if "_responsibleFromDescription" not in agenda_storage or "_notesFromDescription" not in agenda_storage:
        module_contract_errors.append("Agenda não normaliza responsável/observações ao recarregar")
    legacy_schema = (BACKEND / "app" / "schemas" / "legacy.py").read_text(encoding="utf-8", errors="ignore")
    update_block = legacy_schema.split("class OperationalTaskUpdateRequest", 1)[-1].split("class OperationalTaskResponse", 1)[0]
    if "source_type: str | None = None" not in update_block:
        module_contract_errors.append("Backend não permite atualizar source_type da Agenda")
    # Confere se os endpoints usados pelos módulos existem no backend auditado.
    backend_paths = {path for _, path in routes}
    for expected in (
        "/livestock/finance/v2",
        "/livestock/inventory/products",
        "/livestock/inventory/products/v2",
        "/livestock/nutrition/plans",
        "/operations/tasks",
        "/livestock/health",
    ):
        if expected not in backend_paths:
            module_contract_errors.append(f"endpoint backend não encontrado: {expected}")
    if not any(path.startswith("/livestock/animals/{animal_id}/reproduction") for path in backend_paths):
        module_contract_errors.append("endpoint de reprodução animal não encontrado")
    result["operational_module_contract_errors"] = module_contract_errors

    # Central do Animal: nenhuma fonte isolada pode bloquear a tela inteira.
    animal_detail = (
        LIB / "features" / "animal" / "presentation" / "screens" / "animal_detail_screen.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    animal_central_errors: list[str] = []
    if "Future<List<T>> _safeLoad<T>" not in animal_detail:
        animal_central_errors.append("Central do Animal sem isolamento de fontes")
    http_client = (
        LIB / "core" / "network" / "atlas_http_client.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    official_network_timeout = (
        ".timeout(AtlasEnvironmentConfig.current.receiveTimeout)" in http_client
    )
    if ".timeout(timeout)" not in animal_detail and not official_network_timeout:
        animal_central_errors.append(
            "Central do Animal sem timeout local ou timeout oficial de rede"
        )
    if "finally {" not in animal_detail or "isLoading = false" not in animal_detail:
        animal_central_errors.append("Central do Animal não garante encerramento do loading")
    if "LinearProgressIndicator" not in animal_detail:
        animal_central_errors.append("Central do Animal ainda usa carregamento bloqueante")
    if "_AnimalCentralLoadWarning" not in animal_detail:
        animal_central_errors.append("Central do Animal não informa carregamento parcial")
    if "farmId: farm.id ?? ''" not in animal_detail:
        animal_central_errors.append("Central do Animal não propaga farmId para Sanidade")
    result["animal_central_contract_errors"] = animal_central_errors

    # Núcleo pecuário: Rebanho deve carregar a fazenda em duas leituras canônicas
    # (lotes + animais), sem N+1 por lote e sem omitir animais sem lote.
    herd_overview = (
        LIB / "features" / "herd" / "presentation" / "screens" / "herd_overview_screen.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    livestock_core_errors: list[str] = []
    if "loader: () => herdService.listGroups(farm.id)" not in herd_overview:
        livestock_core_errors.append("Rebanho não usa leitura canônica de lotes")
    if "lotId: ''" not in herd_overview:
        livestock_core_errors.append("Rebanho não carrega todos os animais da fazenda em uma única leitura")
    if "groups.map((group) async" in herd_overview:
        livestock_core_errors.append("Rebanho ainda executa N+1 chamadas por lote")
    if "_groupForAnimal" not in herd_overview or "'Sem lote'" not in herd_overview:
        livestock_core_errors.append("Rebanho pode omitir animais sem lote")
    if "remote.area" not in herd_overview:
        livestock_core_errors.append("Rebanho não preserva área oficial da fazenda")
    if "Future<List<T>> _safeLoad<T>" not in herd_overview:
        livestock_core_errors.append("Rebanho sem isolamento das fontes")
    if ".timeout(timeout)" not in herd_overview and not official_network_timeout:
        livestock_core_errors.append(
            "Rebanho sem timeout local ou timeout oficial de rede"
        )
    if "finally {" not in herd_overview:
        livestock_core_errors.append("Rebanho não garante encerramento do loading")
    result["livestock_core_contract_errors"] = livestock_core_errors

    # Marco 2 — Gestão da Fazenda. Valida conexões reais, não apenas presença de telas.
    management_core_errors: list[str] = []
    management_contracts = {
        "nutrition_storage": (
            LIB / "features" / "nutrition" / "data" / "services" / "nutrition_storage_service.dart",
            ("/livestock/nutrition/plans", "stock_integration_enabled", "inventory_deducted", "ingredients_json", "_loadRemotePlans"),
        ),
        "nutrition_inventory": (
            LIB / "features" / "nutrition" / "domain" / "services" / "nutrition_inventory_service.dart",
            ("registerMovement", "referenceType: 'nutrition_plan'", "required String farmId"),
        ),
        "inventory_storage": (
            LIB / "features" / "farm_inventory" / "data" / "services" / "farm_inventory_storage_service.dart",
            ("/livestock/inventory/products/v2", "/movements/v2", "_verifyProduct", "reference_type"),
        ),
        "finance_storage": (
            LIB / "features" / "farm_finance" / "data" / "services" / "farm_finance_storage_service.dart",
            ("/livestock/finance/v2", "_resolveReferences", "'lot_id': lotId", "'animal_id': animalId", "_verifyRecord", "hasReference"),
        ),
        "paddock_storage": (
            LIB / "features" / "paddock" / "data" / "services" / "paddock_storage_service.dart",
            ("/livestock/paddocks", "_verifyPaddock", "deletePaddock"),
        ),
    }
    for name, (path, tokens) in management_contracts.items():
        if not path.exists():
            management_core_errors.append(f"arquivo ausente: {name}")
            continue
        source = path.read_text(encoding="utf-8", errors="ignore")
        for token in tokens:
            if token not in source:
                management_core_errors.append(f"{name}: contrato ausente: {token}")
    nutrition_model = (BACKEND / "app" / "models" / "legacy.py").read_text(encoding="utf-8", errors="ignore")
    nutrition_schema = (BACKEND / "app" / "schemas" / "legacy.py").read_text(encoding="utf-8", errors="ignore")
    for token in ("stock_integration_enabled", "inventory_deducted", "inventory_deduction_cost"):
        if token not in nutrition_model or token not in nutrition_schema:
            management_core_errors.append(f"backend Nutrição sem persistência: {token}")
    if not (BACKEND / "alembic" / "versions" / "20260813_0039_nutrition_inventory_flags.py").exists():
        management_core_errors.append("migração 0039 de integração Nutrição/Estoque ausente")
    result["management_core_contract_errors"] = management_core_errors

    # Marco 3 — Agenda e integrações. Garante CRUD remoto real e vínculo
    # bidirecional de datas entre Sanidade/Reprodução e Agenda.
    marco3_errors: list[str] = []
    livestock_router = (BACKEND / "app" / "routers" / "livestock.py").read_text(encoding="utf-8", errors="ignore")
    operations_router = (BACKEND / "app" / "routers" / "operations.py").read_text(encoding="utf-8", errors="ignore")
    reproduction_storage = (
        LIB / "features" / "animal_reproduction" / "data" / "services" / "animal_reproduction_storage_service.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    health_storage = (
        LIB / "features" / "animal_health" / "data" / "services" / "animal_health_storage_service.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    agenda_model = (
        LIB / "features" / "farm_agenda" / "domain" / "models" / "farm_agenda_data.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    for token in (
        'source_type="reproduction_event"',
        'source_type="health_event"',
        'health_event_reversal',
        'def update_reproduction_event',
        'def delete_reproduction_event',
        'def update_health_event',
        'def delete_health_event',
    ):
        if token not in livestock_router:
            marco3_errors.append(f"backend Marco 3 sem contrato: {token}")
    for token in ('ReproductionEvent.id == task.source_id', 'event.expected_date = task.due_at'):
        if token not in operations_router:
            marco3_errors.append(f"Agenda não sincroniza Reprodução: {token}")
    for token in ('HealthEvent.id == task.source_id', 'event.next_date = task.due_at'):
        if token not in operations_router:
            marco3_errors.append(f"Agenda não sincroniza Sanidade: {token}")
    for token in ("'PATCH'", "'DELETE'", '_verifyAndCache'):
        if token not in reproduction_storage:
            marco3_errors.append(f"Reprodução sem CRUD remoto confirmado: {token}")
        if token not in health_storage:
            marco3_errors.append(f"Sanidade sem CRUD remoto confirmado: {token}")
    for token in ('sourceType', 'sourceId', 'isIntegrated'):
        if token not in agenda_model:
            marco3_errors.append(f"Agenda não preserva origem integrada: {token}")
    obsolete_health_inventory = (
        LIB / "features" / "animal_health" / "domain" / "services" / "animal_health_inventory_service.dart"
    )
    if obsolete_health_inventory.exists():
        marco3_errors.append("Sanidade ainda possui autoridade local paralela de baixa de estoque")
    if not (BACKEND / "tests" / "test_marco3_agenda_integrations.py").exists():
        marco3_errors.append("teste de regressão do Marco 3 ausente")
    result["marco3_integration_contract_errors"] = marco3_errors


    # Marco 4 — Matriz tela -> serviço -> endpoint. O auditor dedicado gera
    # relatórios detalhados; aqui mantemos os bloqueios de regressão de alta confiança.
    marco4_errors: list[str] = []
    placeholder_tests = sorted(ROOT.glob("test/**/*placeholder_test.dart"))
    if placeholder_tests:
        marco4_errors.extend(
            f"teste placeholder: {path.relative_to(ROOT)}" for path in placeholder_tests
        )

    dart_sources = {
        path: path.read_text(encoding="utf-8", errors="ignore")
        for path in LIB.rglob("*.dart")
    }
    screen_identifier_counts: Counter[str] = Counter()
    screen_declarations: list[tuple[str, Path]] = []
    for path, source in dart_sources.items():
        screen_identifier_counts.update(
            re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*Screen\b", source)
        )
        for match in re.finditer(
            r"class\s+([A-Za-z_][A-Za-z0-9_]*Screen)\s+extends", source
        ):
            screen_declarations.append((match.group(1), path))
        if re.search(r"\b(?:onPressed|onTap|onLongPress)\s*:\s*null\b", source):
            marco4_errors.append(f"ação desabilitada: {path.relative_to(ROOT)}")
        if re.search(r"\b(?:TODO|FIXME)\b", source):
            marco4_errors.append(f"TODO/FIXME: {path.relative_to(ROOT)}")

    intentionally_hidden_post_v21 = {
        "AtlasFlutterQualityScreen",
        "AtlasOperationalReadinessScreen",
        "AtlasCommercialReadinessScreen",
        "AtlasScaleCenterScreen",
    }

    for class_name, path in screen_declarations:
        if class_name in intentionally_hidden_post_v21:
            continue
        if screen_identifier_counts[class_name] <= 2:
            marco4_errors.append(
                f"tela órfã: {class_name} ({path.relative_to(ROOT)})"
            )

    normalized_backend_routes = {
        (method, re.sub(r"\{[^}]+\}", "{}", path)) for method, path in routes
    }
    http_call_pattern = re.compile(
        r"(?:[A-Za-z_][A-Za-z0-9_]*\.)?(?:send|request|requestList)\(\s*['\"](GET|POST|PATCH|PUT|DELETE)['\"]\s*,\s*['\"]([^'\"]+)['\"]",
        re.S,
    )
    for path, source in dart_sources.items():
        for match in http_call_pattern.finditer(source):
            endpoint = match.group(2).split("?", 1)[0]
            endpoint = re.sub(r"\$\{[^}]+\}", "{}", endpoint)
            endpoint = re.sub(r"\$[A-Za-z_][A-Za-z0-9_.]*", "{}", endpoint)
            key = (match.group(1).upper(), endpoint)
            if key not in normalized_backend_routes:
                marco4_errors.append(
                    f"endpoint Flutter sem rota backend: {key[0]} {match.group(2)} "
                    f"({path.relative_to(ROOT)})"
                )

    animal_cache = (
        LIB / "features" / "animal" / "data" / "services" / "animal_storage_service.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    herd_cache = (
        LIB / "features" / "herd" / "data" / "services" / "herd_storage_service.dart"
    ).read_text(encoding="utf-8", errors="ignore")
    if "AnimalEnterpriseService" not in animal_cache or "_resolveRemoteContext" not in animal_cache:
        marco4_errors.append("AnimalStorageService deixou de ser cache remote-first")
    if "HerdEnterpriseService" not in herd_cache or "_resolveFarmId" not in herd_cache:
        marco4_errors.append("HerdStorageService deixou de ser cache remote-first")
    result["marco4_route_screen_contract_errors"] = marco4_errors

    output = ROOT / "ATLAS_AUDITORIA_RECUPERACAO_FINAL.json"
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

    blocking = (
        bool(result["python_syntax_errors"])
        or bool(result["dart_missing_internal_imports"])
        or bool(result["missing_permission_catalog_entries"])
        or bool(result["duplicate_routes"])
        or bool(result["unsafe_farm_scope_checks"])
        or bool(result["livestock_farm_scope_contract_errors"])
        or bool(result["farm_frontend_contract_errors"])
        or bool(result["operational_module_contract_errors"])
        or bool(result["animal_central_contract_errors"])
        or bool(result["livestock_core_contract_errors"])
        or bool(result["management_core_contract_errors"])
        or bool(result["marco3_integration_contract_errors"])
        or bool(result["marco4_route_screen_contract_errors"])
        or bool(result["alembic_orphans"])
        or len(result["alembic_heads"]) != 1
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))
    print("\nATLAS AUDIT:", "FAIL" if blocking else "OK")
    return 1 if blocking else 0


if __name__ == "__main__":
    raise SystemExit(main())
