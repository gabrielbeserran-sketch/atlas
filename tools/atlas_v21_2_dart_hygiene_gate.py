from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

errors = []

# Known stale field that escaped the previous preflight.
nutrition = LIB / "features/nutrition/presentation/screens/nutrition_overview_screen.dart"
nutrition_text = nutrition.read_text(encoding="utf-8", errors="ignore")
if re.search(r"\bforestGreen\b", nutrition_text):
    errors.append("Nutrição ainda contém o campo obsoleto forestGreen.")

# Conservative parser: private classes + static const declared once in their own class
# are highly likely to trigger unused_field and are safe to block for review.
def extract_classes(text: str):
    output = []
    for match in re.finditer(r"class\s+([A-Za-z_]\w*)[^{]*\{", text):
        name = match.group(1)
        open_pos = text.find("{", match.start())
        depth = 0
        in_single = False
        in_double = False
        escaped = False
        index = open_pos
        while index < len(text):
            char = text[index]
            if escaped:
                escaped = False
                index += 1
                continue
            if char == "\\" and (in_single or in_double):
                escaped = True
                index += 1
                continue
            if not in_double and char == "'":
                in_single = not in_single
                index += 1
                continue
            if not in_single and char == '"':
                in_double = not in_double
                index += 1
                continue
            if in_single or in_double:
                index += 1
                continue
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    output.append((name, text[open_pos + 1:index]))
                    break
            index += 1
    return output

for path in LIB.rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    for class_name, body in extract_classes(text):
        if not class_name.startswith("_"):
            continue
        for match in re.finditer(
            r"^\s*static\s+const(?:\s+[A-Za-z_<>,? ]+)?\s+([A-Za-z]\w*)\s*=",
            body,
            re.MULTILINE,
        ):
            field = match.group(1)
            occurrences = len(re.findall(rf"\b{re.escape(field)}\b", body))
            if occurrences == 1:
                errors.append(
                    f"{path.relative_to(ROOT)}: {class_name}.{field} "
                    "é static const e não possui uso dentro da classe."
                )

# UI source must also stay free from the common mojibake signatures.
bad_tokens = ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â")
for path in LIB.rglob("*.dart"):
    if "/presentation/" not in str(path).replace("\\", "/"):
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    if any(token in text for token in bad_tokens):
        errors.append(f"{path.relative_to(ROOT)} contém assinatura de mojibake.")

if errors:
    print("ATLAS V21.2 DART HYGIENE: FAIL")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS V21.2 DART HYGIENE: OK")
