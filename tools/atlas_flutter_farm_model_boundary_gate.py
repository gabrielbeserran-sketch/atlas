from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

# Platform/remote-session screens use AtlasRemoteFarm. Reusable children mounted
# from those screens must not silently require the legacy FarmData model.
platform_roots = (
    ROOT / "lib/features/precision_hub/presentation",
    ROOT / "lib/features/platform_hubs/presentation",
)

for base in platform_roots:
    if not base.exists():
        continue
    for path in base.rglob("*.dart"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        if "AtlasRemoteFarm" in text or "activeFarm" in text:
            # Find child constructors fed directly with `farm: farm`.
            for match in re.finditer(
                r"([A-Z][A-Za-z0-9_]*)\s*\(\s*[^)]*\bfarm\s*:\s*farm\b",
                text,
                re.S,
            ):
                widget_name = match.group(1)
                candidate_files = list(
                    (ROOT / "lib").rglob(
                        re.sub(r"(?<!^)(?=[A-Z])", "_", widget_name).lower()
                        + ".dart"
                    )
                )
                for candidate in candidate_files:
                    child = candidate.read_text(
                        encoding="utf-8",
                        errors="ignore",
                    )
                    if "final FarmData farm;" in child:
                        errors.append(
                            f"{path.relative_to(ROOT)} monta {widget_name} "
                            "com AtlasRemoteFarm/activeFarm, mas "
                            f"{candidate.relative_to(ROOT)} exige FarmData"
                        )

# Explicit regression that triggered Package 8A failure.
camera = ROOT / (
    "lib/features/security_camera/presentation/widgets/"
    "atlas_security_camera_card.dart"
)
if camera.exists():
    text = camera.read_text(encoding="utf-8", errors="ignore")
    if "final FarmData farm;" in text:
        errors.append(
            "AtlasSecurityCameraCard voltou a exigir FarmData; "
            "use farmId/farmName na fronteira."
        )

if errors:
    print(f"ATLAS FARM MODEL BOUNDARY: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS FARM MODEL BOUNDARY: OK")
print("Precision/remote session -> reusable widgets: sem FarmData incompatível")
