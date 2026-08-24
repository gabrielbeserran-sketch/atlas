from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
EDGE = ROOT / "edge/camera_gateway"

files = {
    "config": EDGE / "atlas_camera_gateway/config.py",
    "event": EDGE / "atlas_camera_gateway/event.py",
    "adapter": EDGE / "atlas_camera_gateway/adapter.py",
    "folder": EDGE / "atlas_camera_gateway/folder_adapter.py",
    "spool": EDGE / "atlas_camera_gateway/spool.py",
    "transport": EDGE / "atlas_camera_gateway/transport.py",
    "worker": EDGE / "atlas_camera_gateway/worker.py",
    "cli": EDGE / "atlas_camera_gateway/cli.py",
    "readme": EDGE / "README.md",
    "dockerfile": EDGE / "Dockerfile",
    "compose": EDGE / "docker-compose.yml",
    "env": EDGE / ".env.example",
    "backend_router": ROOT / "backend/app/routers/security_camera.py",
    "backend_alerts": ROOT / "backend/app/services/security_camera_alerts.py",
}

errors = []
texts = {}
for name, path in files.items():
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
    else:
        texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(label, condition):
    if not condition:
        errors.append(label)

config = texts.get("config", "")
event = texts.get("event", "")
adapter = texts.get("adapter", "")
folder = texts.get("folder", "")
spool = texts.get("spool", "")
transport = texts.get("transport", "")
worker = texts.get("worker", "")
cli = texts.get("cli", "")
readme = texts.get("readme", "")
dockerfile = texts.get("dockerfile", "")
compose = texts.get("compose", "")
env = texts.get("env", "")
backend_router = texts.get("backend_router", "")
backend_alerts = texts.get("backend_alerts", "")

# Must reuse 8A contract, not create a second backend.
check(
    "gateway não usa contrato 8A",
    "/security-camera/events/ingest" in transport,
)
check(
    "header IoT ausente",
    '"X-Atlas-Iot-Key"' in transport,
)
check(
    "backend 8A perdeu idempotência",
    "event_external_id" in backend_router
    and "if existing is not None" in backend_alerts,
)

# Physical truth: gateway does not claim to detect on its own.
for forbidden in (
    "cv2",
    "opencv",
    "yolo",
    "ultralytics",
    "tensorflow",
    "torch",
    "face_recognition",
):
    check(
        f"gateway ganhou detector não homologado: {forbidden}",
        forbidden not in " ".join(
            (config, event, adapter, folder, spool, transport, worker, cli)
        ).lower(),
    )
check(
    "README finge detecção própria",
    "não presume uma marca de câmera" in readme
    and "não inventa detecção" in readme.lower(),
)

# Adapter contract + vendor neutrality.
check(
    "contrato de adapter ausente",
    "class CameraEventAdapter(Protocol)" in adapter,
)
check(
    "adapter de pasta ausente",
    "class FolderEventAdapter" in folder,
)
check(
    "adapter aceita path escape",
    "relative_to(resolved_root)" in adapter,
)
check(
    "eventos não limitados a pessoa/veículo",
    'ALLOWED_EVENT_TYPES = {"person", "vehicle"}' in event,
)

# Offline durability.
check(
    "spool não copia imagem antes da rede",
    "shutil.copy2" in spool and "event.json" in spool,
)
check(
    "spool não é idempotente",
    "if item_dir.exists()" in spool,
)
check(
    "worker não mantém falha pendente",
    "mark_failed" in worker
    and "continue" in worker,
)
check(
    "worker não faz backoff",
    "retry_max_seconds" in worker and "delay * 2" in worker,
)
check(
    "fila não possui volume Docker",
    'VOLUME ["/data"]' in dockerfile
    and "atlas_camera_spool:/data" in compose,
)

# Transport correctness.
check(
    "httpx timeout configurado de forma inválida",
    "httpx.Timeout(" in transport
    and "connect=self.config.connect_timeout_seconds" in transport
    and "connect_timeout=" not in transport,
)
check(
    "transport não exige confirmação de ID",
    "Atlas não confirmou o ID do evento." in transport,
)
check(
    "transport remove evento antes da confirmação",
    "mark_sent(item)" in worker
    and worker.find("result = self.transport.deliver(event)")
    < worker.find("self.spool.mark_sent(item)"),
)
check(
    "captura sem limite de tamanho",
    "max_image_bytes" in transport,
)

# Secret hygiene.
check(
    "gateway aceita chave curta",
    "if len(ingest_key) < 32" in config,
)
check(
    "chave real foi versionada no exemplo",
    "ATLAS_IOT_INGEST_KEY=\n" in env,
)
for text_name, text in texts.items():
    if text_name == "backend_alerts":
        continue
    check(
        f"possível segredo hardcoded em {text_name}",
        "Bearer ey" not in text
        and "ATLAS_IOT_INGEST_KEY=atlas-" not in text,
    )

# Deploy independent of app/backend.
check(
    "gateway sem pacote instalável",
    "[project]" in (EDGE / "pyproject.toml").read_text(encoding="utf-8")
    and "atlas-camera-gateway" in (EDGE / "pyproject.toml").read_text(encoding="utf-8"),
)
check(
    "gateway sem modo worker",
    '"worker"' in cli and "run_forever" in cli,
)
check(
    "gateway sem integração por pasta",
    '"watch-folder"' in cli,
)

# Production hygiene.
for name, text in texts.items():
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Â")),
    )

if errors:
    print(f"ATLAS POS-V21 PACOTE 8B GATEWAY: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 8B GATEWAY: APROVADO")
print("Contrato 8A reutilizado: SIM")
print("Fila offline durável: SIM")
print("Adapter vendor-neutral: SIM")
print("Detecção inventada pelo Atlas: NÃO")
print("Segredo IoT no Flutter/repositório: NÃO")
