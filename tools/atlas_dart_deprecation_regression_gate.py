from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
voice = (
    ROOT
    / "lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart"
).read_text(encoding="utf-8")

if "import 'dart:ui';" in main:
    errors.append(
        "lib/main.dart voltou a importar dart:ui desnecessariamente"
    )

deprecated_direct_locale = re.search(
    r"_speech\.listen\(\s*"
    r"onResult\s*:\s*_onResult\s*,\s*"
    r"localeId\s*:",
    voice,
    flags=re.S,
)
if deprecated_direct_locale is not None:
    errors.append(
        "localeId voltou a ser passado como argumento depreciado de listen"
    )

if "listenOptions: SpeechListenOptions(" not in voice:
    errors.append(
        "SpeechListenOptions deixou de ser usado em _speech.listen"
    )

if "SpeechListenOptions(" not in voice:
    errors.append("SpeechListenOptions ausente")
if "localeId: _preferredLocaleId" not in voice:
    errors.append("locale pt-BR deixou de ser preservado dentro das opções")
if "ListenMode.dictation" not in voice:
    errors.append("modo de ditado ausente")

if errors:
    print(f"ATLAS DART DEPRECATION REGRESSION: FAIL ({len(errors)})")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS DART DEPRECATION REGRESSION: 6/6")
print("deprecated listen localeId: bloqueado")
print("dart:ui redundante no main: bloqueado")
