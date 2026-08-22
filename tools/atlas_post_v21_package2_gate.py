from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
shell = (ROOT / "lib/core/navigation/atlas_home_shell.dart").read_text(
    encoding="utf-8",
    errors="ignore",
)
screen = (
    ROOT
    / "lib/features/farm_handling/presentation/screens/farm_handling_screen.dart"
).read_text(encoding="utf-8", errors="ignore")
service = (
    ROOT
    / "lib/features/farm_handling/data/services/farm_handling_enterprise_service.dart"
).read_text(encoding="utf-8", errors="ignore")
schemas = (ROOT / "backend/app/schemas/legacy.py").read_text(
    encoding="utf-8",
    errors="ignore",
)
backend = (ROOT / "backend/app/routers/livestock.py").read_text(
    encoding="utf-8",
    errors="ignore",
)

route_start = shell.find("static final List<AtlasRouteDefinition> routes = [")
route_end = shell.find("\n  ];", route_start)
routes = shell[route_start:route_end] if route_start >= 0 and route_end > route_start else ""

handling_start = backend.find('def execute_farm_handling_batch(')
handling_end = backend.find(
    '@router.post("/animals/{animal_id}/weights"',
    handling_start,
)
handling = (
    backend[handling_start:handling_end]
    if handling_start >= 0 and handling_end > handling_start
    else ""
)

checks = {}

def check(name, condition):
    checks[name] = bool(condition)

check("menu contém Realizar manejo", "label: 'Realizar manejo'" in routes)
check(
    "menu ordena manejo após rebanho",
    routes.find("label: 'Rebanho'") < routes.find("label: 'Realizar manejo'")
    < routes.find("label: 'Sanidade'"),
)
check(
    "manejo é farm scoped",
    "'Realizar manejo'," in shell[shell.find("farmScopedModules"):],
)
check(
    "manejo abre tela canônica",
    "FarmHandlingScreen(farm: farm, embedded: true)" in shell,
)
check(
    "ferramentas técnicas fora do menu",
    all(
        f"label: '{label}'" not in routes
        for label in (
            "Precision Hub",
            "Enterprise",
            "SaaS",
            "Dados",
            "Segurança",
            "Qualidade",
            "Prontidão",
            "Releases",
            "Comercial",
            "Piloto",
            "Publicação",
            "Escala",
        )
    ),
)
check("offline preservado", "label: 'Offline'" in routes)
check("inteligência preservada", "label: 'Inteligência'" in routes)
check("relatórios preservados", "label: 'Relatórios'" in routes)

check("seleção lote inteiro", "_SelectionMode.wholeLot" in screen)
check("seleção intervalo brincos", "_SelectionMode.earringRange" in screen)
check("seleção manual", "_SelectionMode.manualSelection" in screen)
check("rfid não é fingido como seleção disponível", "_SelectionMode.rfid" not in screen)
check("prévia dos animais", "animal(is) selecionado(s)" in screen)
check("confirmação antes de executar", "'Confirmar manejo'" in screen)

for action, token in {
    "venda/saída": "_HandlingAction.saleOrExit",
    "movimentação lote": "_HandlingAction.lotMovement",
    "pesagem": "_HandlingAction.weighing",
    "sanidade": "_HandlingAction.health",
    "reprodução": "_HandlingAction.reproduction",
    "categoria": "_HandlingAction.categoryChange",
}.items():
    check(f"UI suporta {action}", token in screen)

check("serviço usa endpoint batch", "'/livestock/handling/batch'" in service)
check("schema batch existe", "class FarmHandlingBatchRequest" in schemas)
check("schema resposta existe", "class FarmHandlingBatchResponse" in schemas)
check("backend endpoint único", backend.count('"/handling/batch"') == 1)
check("backend valida fazenda/animais", "_handling_animals(" in handling)
check("backend valida permissão por ação", "_require_handling_permission" in handling)
check("backend suporta seis ações", all(code in handling for code in (
    '"sale_or_exit"',
    '"lot_movement"',
    '"weighing"',
    '"health"',
    '"reproduction"',
    '"category_change"',
)))
check("backend commit único", handling.count("db.commit()") == 1)
check("venda gera movimentação", 'movement_type="sale"' in handling)
check("venda baixa lote/status", 'animal.lot_id = None' in handling and 'animal.status = "sale"' in handling)
check("venda integra financeiro", 'category="livestock_sale"' in handling and 'reference_type="farm_handling"' in handling)
check("venda não finge recebimento", 'status="pending"' in handling)
check("movimentação atualiza lote", 'animal.lot_id = target_lot.id' in handling)
check("categoria deixa rastro", 'movement_type="category_change"' in handling)
check("pesagem atualiza peso animal", "animal.current_weight = entry.weight" in handling)
check("pesagem sincroniza tarefa", "_sync_weight_schedule_task" in handling)
check("sanidade cria evento", "item = HealthEvent(" in handling)
check("sanidade integra financeiro", 'category="health"' in handling)
check("sanidade integra agenda", 'source_type="health_event"' in handling)
check("reprodução cria evento", "item = ReproductionEvent(" in handling)
check("reprodução atualiza status", "animal.reproductive_status = status_value" in handling)
check("reprodução integra agenda", 'source_type="reproduction_event"' in handling)

full_audit = (ROOT / "scripts/quality/atlas_full_project_audit.py").read_text(
    encoding="utf-8",
    errors="ignore",
)
check(
    "telas técnicas retiradas são migração explícita",
    all(
        name in full_audit
        for name in (
            "AtlasFlutterQualityScreen",
            "AtlasOperationalReadinessScreen",
            "AtlasCommercialReadinessScreen",
            "AtlasScaleCenterScreen",
        )
    ),
)

bad = ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â")
check(
    "novos arquivos sem mojibake",
    not any(token in (screen + service + handling) for token in bad),
)

failed = [name for name, ok in checks.items() if not ok]
print(f"ATLAS POST-V21 PACKAGE 2: {len(checks)-len(failed)}/{len(checks)}")
for name in failed:
    print("FAIL:", name)
sys.exit(1 if failed else 0)
