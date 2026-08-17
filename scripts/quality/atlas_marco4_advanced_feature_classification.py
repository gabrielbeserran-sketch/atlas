from __future__ import annotations

import csv
import json
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[2]
PERSISTENCE = ROOT / "ATLAS_MARCO4_PERSISTENCIA.csv"
SHELL = ROOT / "lib/core/navigation/atlas_home_shell.dart"
BASELINE_ADVANCED_COMPONENTS_MINIMUM = 98

OFFICIAL_V1_ROOTS = {
    "animal", "animal_health", "animal_reproduction", "farm", "farm_agenda",
    "farm_finance", "farm_inventory", "herd", "lot", "nutrition",
    "paddock", "weight", "animal_weight", "animal_photo", "animal_document",
}

INTERNAL_TOKENS = (
    "quality", "release", "publication", "commercial", "pilot", "observability",
    "governance", "saas", "platform_resilience", "system_center", "release_candidate",
)

ADVANCED_VALIDATION_TOKENS = (
    "ai", "intelligence", "enterprise", "predict", "digital_twin", "precision",
    "strategy", "scenario", "sustainability", "supply", "integration", "command_center",
    "consultancy", "benefits", "investment", "knowledge", "workflow", "performance",
)


def root_name(rel: str) -> str:
    p = PurePosixPath(rel)
    parts = p.parts
    if len(parts) >= 3 and parts[0] == "lib" and parts[1] == "features":
        return parts[2]
    if len(parts) >= 3 and parts[0] == "lib" and parts[1] == "core":
        return f"core/{parts[2]}"
    return "other"


def tier_for(rel: str, category: str) -> tuple[str, str]:
    low = rel.lower()
    if category == "advanced_local_planning":
        return (
            "advanced_validation",
            "Planejamento/inteligência derivada: pode existir na V1 como apoio, mas não é cadastro oficial e permanece em validação.",
        )
    if any(token in low for token in INTERNAL_TOKENS):
        return (
            "internal_tool",
            "Ferramenta de plataforma, governança, qualidade, release ou operação interna; não é módulo produtivo da fazenda.",
        )
    if any(token in low for token in ADVANCED_VALIDATION_TOKENS):
        return (
            "advanced_validation",
            "Feature avançada preservada para evolução; dados locais não podem ser apresentados como autoridade operacional V1.",
        )
    return (
        "advanced_validation",
        "Feature avançada ainda local; mantida fora da autoridade dos módulos operacionais V1.",
    )



def importer_is_official_v1(rel: str) -> bool:
    p = PurePosixPath(rel)
    parts = p.parts
    return len(parts) >= 3 and parts[:2] == ("lib", "features") and parts[2] in OFFICIAL_V1_ROOTS

def feature_root_is_official_v1(rel: str) -> bool:
    p = PurePosixPath(rel)
    parts = p.parts
    return len(parts) >= 3 and parts[:2] == ("lib", "features") and parts[2] in OFFICIAL_V1_ROOTS


def build_import_index() -> dict[str, list[str]]:
    index: dict[str, list[str]] = {}
    prefix = "package:projeto_atlas/"
    for dart in (ROOT / "lib").rglob("*.dart"):
        dart_rel = dart.relative_to(ROOT).as_posix()
        text = dart.read_text(encoding="utf-8", errors="ignore")
        for line in text.splitlines():
            if prefix not in line:
                continue
            start = line.find(prefix)
            end = line.find("'", start)
            if end < 0:
                end = line.find('"', start)
            if end < 0:
                continue
            imported = "lib/" + line[start + len(prefix):end]
            index.setdefault(imported, []).append(dart_rel)
    return index


def main() -> int:
    rows = list(csv.DictReader(PERSISTENCE.open(encoding="utf-8-sig")))
    advanced = [
        row for row in rows
        if row["category"] in {"advanced_local_planning", "advanced_local_feature"}
    ]

    import_index = build_import_index()
    output = []
    blockers: list[dict[str, str]] = []
    tier_counts: dict[str, int] = {}
    root_counts: dict[str, int] = {}

    for row in advanced:
        rel = row["file"]
        tier, reason = tier_for(rel, row["category"])
        root = root_name(rel)
        importers = sorted(item for item in import_index.get(rel, []) if item != rel)
        official_root = feature_root_is_official_v1(rel)
        if official_root:
            blockers.append({"file": rel, "reason": "Persistência local avançada encontrada dentro de raiz oficial V1."})
        official_importers = [item for item in importers if importer_is_official_v1(item)]
        if official_importers:
            blockers.append({
                "file": rel,
                "reason": "Persistência local avançada importada diretamente por tela/feature oficial V1: " + ", ".join(official_importers),
            })
        output.append({
            "file": rel,
            "feature_root": root,
            "previous_category": row["category"],
            "v1_disposition": tier,
            "reason": reason,
            "direct_external_importers": " | ".join(importers),
            "official_v1_root": official_root,
        })
        tier_counts[tier] = tier_counts.get(tier, 0) + 1
        root_counts[root] = root_counts.get(root, 0) + 1

    shell = SHELL.read_text(encoding="utf-8", errors="ignore")
    required_markers = {
        "advanced_validation": ["Inteligência", "Precision Hub", "Enterprise", "SaaS", "Dados"],
        "internal_tool": ["Segurança", "Qualidade", "Prontidão", "Releases", "Comercial", "Piloto", "Publicação", "Escala"],
    }
    navigation_errors: list[str] = []
    for maturity, labels in required_markers.items():
        enum_name = "AtlasRouteMaturity." + ("advancedValidation" if maturity == "advanced_validation" else "internalTool")
        for label in labels:
            label_pos = shell.find(f"label: '{label}'")
            if label_pos < 0:
                navigation_errors.append(f"Rota principal ausente: {label}")
                continue
            chunk = shell[label_pos:label_pos + 500]
            if enum_name not in chunk:
                navigation_errors.append(f"Rota {label} sem maturidade {maturity}")

    if "_AtlasMaturityNotice" not in shell:
        navigation_errors.append("Aviso visual de maturidade não encontrado no AtlasHomeShell.")

    digital_twin = ROOT / "lib/features/digital_twin/presentation/screens/atlas_digital_twin_screen.dart"
    demo_explicit = digital_twin.exists() and "Modo demonstrativo" in digital_twin.read_text(encoding="utf-8", errors="ignore")

    report = {
        "advanced_local_components_total": len(output),
        "advanced_local_components_baseline_minimum": BASELINE_ADVANCED_COMPONENTS_MINIMUM,
        "advanced_local_components_delta_from_baseline": len(output) - BASELINE_ADVANCED_COMPONENTS_MINIMUM,
        "disposition_counts": tier_counts,
        "feature_roots_total": len(root_counts),
        "official_v1_local_advanced_blockers": blockers,
        "navigation_maturity_errors": navigation_errors,
        "digital_twin_demo_is_explicit": demo_explicit,
        "decision": (
            "Os componentes locais avançados permanecem fora da autoridade dos cadastros V1. "
            "Módulos avançados e ferramentas internas devem ser identificados visualmente até terem backend e homologação próprios."
        ),
    }

    (ROOT / "ATLAS_MARCO4_FEATURES_AVANCADAS_CLASSIFICADAS.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    with (ROOT / "ATLAS_MARCO4_FEATURES_AVANCADAS.csv").open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(output[0].keys()) if output else ["file"])
        writer.writeheader()
        writer.writerows(output)

    print(json.dumps(report, ensure_ascii=False, indent=2))
    # O valor 98 é o piso homologado do Marco 4D, não um teto imutável.
    # Crescimento da classificação não é regressão por si só. A auditoria
    # continua reprovando perda de cobertura, invasão da autoridade V1,
    # importação direta por módulos oficiais, maturidade incorreta de
    # navegação e Digital Twin sem identificação explícita de demonstração.
    if len(output) < BASELINE_ADVANCED_COMPONENTS_MINIMUM:
        print(
            "ERRO: cobertura de componentes avançados regrediu; "
            f"mínimo homologado {BASELINE_ADVANCED_COMPONENTS_MINIMUM}, "
            f"encontrados {len(output)}"
        )
        return 1

    if len(output) > BASELINE_ADVANCED_COMPONENTS_MINIMUM:
        print(
            "INFO: classificação avançada ampliada sem reduzir cobertura: "
            f"baseline mínima {BASELINE_ADVANCED_COMPONENTS_MINIMUM}, "
            f"encontrados {len(output)}."
        )

    if blockers or navigation_errors or not demo_explicit:
        print("ATLAS MARCO 4 ADVANCED FEATURES: FAIL")
        return 1
    print("ATLAS MARCO 4 ADVANCED FEATURES: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
