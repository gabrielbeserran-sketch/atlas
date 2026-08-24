from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
EDGE = ROOT / "edge/camera_gateway"

required = [
    EDGE / "atlas_camera_gateway/hardware_profile.py",
    EDGE / "atlas_camera_gateway/cli.py",
    EDGE / "README.md",
    EDGE / "scripts/selftest.py",
]

errors = []
for path in required:
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")

hardware = required[0].read_text(encoding="utf-8", errors="ignore") if required[0].exists() else ""
cli = required[1].read_text(encoding="utf-8", errors="ignore") if required[1].exists() else ""
readme = required[2].read_text(encoding="utf-8", errors="ignore") if required[2].exists() else ""

def check(label, condition):
    if not condition:
        errors.append(label)

check("probe-camera ausente no CLI", '"probe-camera"' in cli)
check("perfilador não testa RTSP", "rtsp_port_reachable" in hardware)
check("perfilador não testa ONVIF", "probe_onvif(" in hardware)
check("perfilador não usa GetCapabilities", "GetCapabilities" in hardware)
check("relatório não separa autenticação", "onvif_authenticated" in hardware)
check("senha pode aparecer no relatório", '"password"' not in hardware.split("class CameraCompatibilityReport", 1)[1].split("def _safe_host", 1)[0])
check("senha não vem de env", 'os.getenv("ATLAS_CAMERA_PASSWORD"' in hardware)
check("host aceita URL arbitrária", '"Informe apenas IP ou hostname da câmera."' in hardware)
check("porta RTSP aberta é tratada como prova absoluta", "Uma porta aberta **não é tratada como prova de recurso**" in readme)

for forbidden in ("cv2", "ultralytics", "tensorflow", "torch", "face_recognition"):
    check(
        f"8C introduziu detector não homologado: {forbidden}",
        forbidden not in (hardware + cli).lower(),
    )

check(
    "probe exige credenciais do backend Atlas",
    'if args.command == "probe-camera":' in cli
    and cli.find('if args.command == "probe-camera":') < cli.find("GatewayConfig.from_env()"),
)

if errors:
    print(f"ATLAS POS-V21 PACOTE 8C: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 8C: APROVADO")
print("ONVIF/RTSP compatibility profiler: OK")
print("Driver específico inventado: NÃO")
print("Senha em relatório/linha de comando: NÃO")
