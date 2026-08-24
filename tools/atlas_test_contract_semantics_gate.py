from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
TEST_ROOT = ROOT / "test"

errors: list[str] = []

for path in TEST_ROOT.rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")

    if "Abrir relatórios gerenciais" in text:
        errors.append(
            f"{path.relative_to(ROOT)}: texto antigo "
            "'Abrir relatórios gerenciais'"
        )

target = (
    TEST_ROOT
    / "features/module_centers/"
    "post_v21_package3_complete_centers_contract_test.dart"
)
if not target.exists():
    errors.append("teste de contrato das centrais ausente")
else:
    text = target.read_text(encoding="utf-8", errors="ignore")
    required = (
        "void openReports()",
        "onPressed: openReports",
        "ReportsScreen()",
    )
    for token in required:
        if token not in text:
            errors.append(
                f"teste de Relatórios não valida comportamento: {token}"
            )

    if "'Abrir relatórios gerenciais'" in text:
        errors.append(
            "teste voltou a depender do texto antigo do botão"
        )


# Known navigation/connection tests must validate destinations or callbacks,
# not button copy.
navigation_test = (
    TEST_ROOT
    / "features/animal/animal_central_navigation_cleanup_test.dart"
)
if navigation_test.exists():
    text = navigation_test.read_text(encoding="utf-8", errors="ignore")
    for stale_copy in ("'Abrir fotos'", "'Abrir documentos'"):
        if stale_copy in text:
            errors.append(
                f"{navigation_test.relative_to(ROOT)}: "
                f"contrato depende de texto de botão {stale_copy}"
            )
    for token in (
        "AnimalPhotoGalleryScreen(",
        "Future<void> openDocuments()",
        "AnimalDocumentListScreen(",
    ):
        if token not in text:
            errors.append(
                f"teste de Arquivos não valida destino/comportamento: {token}"
            )

# Dr. Beserra contextual tests must not depend on a phrase crossing adjacent
# Dart string literals. Validate each semantic fragment independently instead.
contextual_test = (
    TEST_ROOT
    / "features/dr_beserra/"
    "post_v21_package7f_contextual_intelligence_contract_test.dart"
)
if contextual_test.exists():
    text = contextual_test.read_text(encoding="utf-8", errors="ignore")
    fragile_fragments = (
        "Sem essa classificação eu não vou inferir quais fêmeas",
    )
    for fragment in fragile_fragments:
        if fragment in text:
            errors.append(
                f"{contextual_test.relative_to(ROOT)}: "
                "contrato textual atravessa literais Dart adjacentes; "
                f"divida a validação semântica: {fragment}"
            )

# Consultancy tests must validate the remote farm-scoped contact contract,
# not require personal/default contact literals inside the HTTP service.
consultancy_test = (
    TEST_ROOT
    / "features/consultancy_client/"
    "post_v21_package4_consultancy_contract_test.dart"
)
if consultancy_test.exists():
    text = consultancy_test.read_text(encoding="utf-8", errors="ignore")
    fragile_contact_assertions = (
        'contact.contains("role: \'Veterinário responsável\'")',
        "contact.contains(\"whatsappNumber:",
    )
    for assertion in fragile_contact_assertions:
        if assertion in text:
            errors.append(
                f"{consultancy_test.relative_to(ROOT)}: "
                "contrato voltou a exigir contato hardcoded no serviço Flutter"
            )

    required = (
        "contact.contains(\"'/consultancy/contact'\")",
        "contact.contains('loadForFarm(')",
        "screen.contains('contact.role')",
        "screen.contains('contact.displayName')",
        "screen.contains('whatsAppService.openConversation(')",
    )
    for token in required:
        if token not in text:
            errors.append(
                f"{consultancy_test.relative_to(ROOT)}: "
                f"contrato remoto da consultoria não é validado: {token}"
            )

if errors:
    print(
        f"ATLAS TEST CONTRACT SEMANTICS: FAIL ({len(errors)} erro(s))"
    )
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS TEST CONTRACT SEMANTICS: OK")
print("Contrato Inteligência → Relatórios validado por comportamento.")
