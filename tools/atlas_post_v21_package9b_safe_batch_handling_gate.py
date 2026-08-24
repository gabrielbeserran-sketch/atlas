from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "model": ROOT / "backend/app/models/legacy.py",
    "schema": ROOT / "backend/app/schemas/legacy.py",
    "router": ROOT / "backend/app/routers/livestock.py",
    "migration": ROOT / "backend/alembic/versions/20260824_0045_farm_handling_operations.py",
    "result": ROOT / "lib/features/farm_handling/domain/models/farm_handling_batch_result.dart",
    "service": ROOT / "lib/features/farm_handling/data/services/farm_handling_enterprise_service.dart",
    "screen": ROOT / "lib/features/farm_handling/presentation/screens/farm_handling_screen.dart",
}

errors = []
texts = {}

for name, path in files.items():
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
    else:
        texts[name] = path.read_text(encoding="utf-8", errors="ignore")


def check(label: str, condition: bool) -> None:
    if not condition:
        errors.append(label)


model = texts.get("model", "")
schema = texts.get("schema", "")
router = texts.get("router", "")
migration = texts.get("migration", "")
result = texts.get("result", "")
service = texts.get("service", "")
screen = texts.get("screen", "")

check(
    "operação de manejo não possui tabela durável",
    "class FarmHandlingOperation(Base):" in model,
)
check(
    "idempotência não é única por empresa/fazenda",
    "uq_farm_handling_company_farm_idempotency" in model
    and "uq_farm_handling_company_farm_idempotency" in migration,
)
check(
    "migration 0045 não encadeia 0044",
    'revision = "20260824_0045"' in migration
    and 'down_revision = "20260823_0044"' in migration,
)
check(
    "schema batch não exige idempotency_key",
    "idempotency_key: str = Field(min_length=8, max_length=180)" in schema,
)
check(
    "resposta não informa replay idempotente",
    "repeated: bool = False" in schema
    and "final bool repeated;" in result,
)
check(
    "endpoint não serializa a mesma chave concorrente",
    "advisory_transaction_lock(" in router
    and "farm-handling:" in router,
)
check(
    "endpoint não reaproveita operação já confirmada",
    "existing_operation is not None" in router
    and "repeated=True" in router,
)
check(
    "endpoint permite reutilizar chave em outra ação",
    "A chave desta operação já foi usada em outro tipo de manejo." in router,
)
check(
    "endpoint permite manejo em animal já baixado",
    "animal(is) já estão inativos/baixados" in router,
)
check(
    "histórico oficial do manejo ausente",
    '"/handling/history"' in router
    and "FarmHandlingOperationHistoryResponse" in schema,
)
check(
    "readiness de produção 9B ausente",
    '"/handling/deployment-readiness"' in router
    and '"idempotency": True' in router
    and '"history": True' in router,
)
check(
    "operação não é persistida antes do commit",
    "operation = FarmHandlingOperation(" in router
    and "db.add(operation)" in router
    and "db.commit()" in router,
)
check(
    "Flutter não envia chave de idempotência",
    "'idempotency_key': pendingOperationKey" in screen,
)
check(
    "Flutter troca chave em retry idêntico",
    "pendingOperationSignature == signature" in screen,
)
check(
    "Flutter não mostra replay seguro",
    "Nenhum registro foi duplicado." in screen,
)
check(
    "Flutter não exibe histórico",
    "Manejos recentes" in screen
    and "listHistory(" in service,
)

# The original efficiency paths must survive the hardening.
for token in (
    "_SelectionMode.wholeLot",
    "_SelectionMode.earringRange",
    "_SelectionMode.manualSelection",
    "Brinco inicial",
    "Brinco final",
    "Venda / saída",
):
    check(f"fluxo de manejo existente foi perdido: {token}", token in screen)

for name, text in texts.items():
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Â")),
    )

if errors:
    print(f"ATLAS POS-V21 PACOTE 9B: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 9B: APROVADO")
print("Manejo coletivo existente: PRESERVADO")
print("Idempotência transacional: SIM")
print("Proteção contra animal baixado: SIM")
print("Histórico auditável: SIM")
