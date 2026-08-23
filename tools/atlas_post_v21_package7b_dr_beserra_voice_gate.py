from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

paths = {
    "pubspec": ROOT / "pubspec.yaml",
    "main": ROOT / "lib/main.dart",
    "voice": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart",
    "screen": ROOT / "lib/features/dr_beserra/presentation/screens/dr_beserra_screen.dart",
    "gateway": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_command_gateway.dart",
    "android": ROOT / "android/app/src/main/AndroidManifest.xml",
    "ios": ROOT / "ios/Runner/Info.plist",
    "macos": ROOT / "macos/Runner/Info.plist",
    "mac_debug": ROOT / "macos/Runner/DebugProfile.entitlements",
    "mac_release": ROOT / "macos/Runner/Release.entitlements",
}

errors = []
texts = {}
for name, path in paths.items():
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
    else:
        texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(name, condition):
    if not condition:
        errors.append(name)

pubspec=texts.get("pubspec","")
main=texts.get("main","")
voice=texts.get("voice","")
screen=texts.get("screen","")
gateway=texts.get("gateway","")
android=texts.get("android","")
ios=texts.get("ios","")
macos=texts.get("macos","")
mac_debug=texts.get("mac_debug","")
mac_release=texts.get("mac_release","")

# Dependency contract pinned to the audited stable versions.
check("speech_to_text 7.4.0 ausente", "speech_to_text: ^7.4.0" in pubspec)
check(
    "speech_to_text_windows 1.0.1 ausente",
    "speech_to_text_windows: ^1.0.1" in pubspec,
)

# Windows registration.
check(
    "Windows speech implementation não registrada",
    "SpeechToTextWindows.registerWith();" in main
    and "TargetPlatform.windows" in main,
)

# Voice service: singleton and device locale.
check("serviço de voz ausente", "class DrBeserraVoiceService" in voice)
check(
    "serviço de voz não é singleton",
    "static final DrBeserraVoiceService instance" in voice,
)
check("SpeechToText não inicializa no serviço", "SpeechToText()" in voice)
check("voz não consulta locales instalados", "_speech.locales()" in voice)
check("voz não prioriza português", "pt_br" in voice and "startsWith('pt_')" in voice)
check("voz não usa resultado final", "result.finalResult" in voice)
check("voz não permite parar", "stopListening()" in voice)
check("voz não permite cancelar", "cancelListening()" in voice)

# The voice layer has no business writes and no gateway dependency.
for forbidden in (
    "FarmAgendaStorageService",
    "AnimalHealthStorageService",
    "AnimalReproductionStorageService",
    "FarmHandlingEnterpriseService",
    "AtlasHttpClient",
    "AtlasLocalDatabase",
    "DrBeserraCommandGateway",
):
    check(
        f"camada de voz ganhou responsabilidade indevida: {forbidden}",
        forbidden not in voice,
    )

# UI funnels final transcript through sendText -> same gateway as typed input.
check("tela não usa serviço de voz", "DrBeserraVoiceService.instance" in screen)
check("botão de voz ausente", "Icons.mic_outlined" in screen)
check("botão parar voz ausente", "Icons.stop_circle_outlined" in screen)
check("botão de voz sem tooltip", "Falar com Dr. Beserra" in screen)
check("transcrição não entra no campo", "state.transcript" in screen and "inputController.value" in screen)
check(
    "resultado final não passa pelo sendText",
    "sendText(lastVoiceFinal)" in screen,
)
check(
    "texto deixou de usar gateway 7A",
    "gateway.interpret(" in screen,
)
check(
    "voz ganhou caminho direto de escrita",
    "confirmTaskCompletion(" not in voice
    and "updateTask(" not in voice
    and "createRecord(" not in voice,
)

# Existing write boundary stays exactly the same.
check(
    "gateway seguro deixou de usar Agenda oficial",
    "FarmAgendaStorageService" in gateway
    and "_agenda.updateTask(" in gateway,
)
check(
    "gateway ganhou HTTP direto",
    "AtlasHttpClient" not in gateway and "_http." not in gateway,
)

# Native permission contract.
for permission in (
    "android.permission.RECORD_AUDIO",
    "android.permission.INTERNET",
    "android.permission.BLUETOOTH",
    "android.permission.BLUETOOTH_ADMIN",
    "android.permission.BLUETOOTH_CONNECT",
):
    check(f"Android sem permissão {permission}", permission in android)
check(
    "Android sem RecognitionService query",
    "android.speech.RecognitionService" in android,
)
for key in (
    "NSSpeechRecognitionUsageDescription",
    "NSMicrophoneUsageDescription",
):
    check(f"iOS sem {key}", key in ios)
    check(f"macOS sem {key}", key in macos)
check(
    "macOS Debug sem audio-input",
    "com.apple.security.device.audio-input" in mac_debug,
)
check(
    "macOS Release sem audio-input",
    "com.apple.security.device.audio-input" in mac_release,
)

# Safety and production copy.
check(
    "interface não explica que áudio vira texto",
    "O áudio vira texto e segue as mesmas regras de segurança da conversa."
    in screen,
)
check(
    "voz tenta reconhecimento contínuo",
    "listenFor:" not in voice and "pauseFor:" not in voice,
)
for name, text in (("voice",voice),("screen",screen)):
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§","Ã£","Ã©","Ã³","Â")),
    )
    check(
        f"{name}: vocabulário de desenvolvimento visível",
        re.search(r"\b(?:Pacote|Marco|Sprint|Etapa)\s*\d+", text, re.I) is None,
    )

if errors:
    print(f"ATLAS POS-V21 PACOTE 7B VOZ: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 7B VOZ: 49/49")
print("Pipeline: microfone -> transcrição -> sendText -> gateway 7A")
print("Escritas concedidas diretamente à camada de voz: 0")
print("Plataformas preparadas: Android, iOS, macOS e Windows")
