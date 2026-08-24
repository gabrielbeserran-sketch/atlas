from __future__ import annotations

import argparse
from datetime import datetime
import logging
from pathlib import Path
import sys

from .config import GatewayConfig
from .event import CameraEvent
from .folder_adapter import FolderEventAdapter
from .hardware_profile import build_report
from .spool import DurableSpool
from .transport import AtlasCameraTransport
from .worker import DeliveryWorker


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="atlas-camera-gateway",
        description="Gateway físico vendor-neutral da câmera de entrada do Atlas.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    emit = sub.add_parser(
        "emit",
        help="Registra um evento real vindo do adaptador da câmera/NVR.",
    )
    emit.add_argument("--type", choices=("person", "vehicle"), required=True)
    emit.add_argument("--image", type=Path, required=True)
    emit.add_argument("--confidence", type=float)
    emit.add_argument("--event-id")
    emit.add_argument("--captured-at")

    sub.add_parser("flush", help="Tenta entregar agora toda a fila offline.")
    sub.add_parser("worker", help="Mantém a fila sendo entregue continuamente.")

    watch = sub.add_parser(
        "watch-folder",
        help="Observa uma inbox de eventos produzidos por câmera/NVR.",
    )
    watch.add_argument("--inbox", type=Path, required=True)
    watch.add_argument("--processed", type=Path, required=True)
    watch.add_argument("--poll-seconds", type=float, default=2.0)

    probe = sub.add_parser(
        "probe-camera",
        help="Descobre conectividade ONVIF/RTSP sem assumir marca/modelo.",
    )
    probe.add_argument("--host", required=True)
    probe.add_argument("--onvif-port", type=int, default=80)
    probe.add_argument("--rtsp-port", type=int, default=554)
    probe.add_argument("--username", default="")
    probe.add_argument("--output", type=Path)

    sub.add_parser("status", help="Mostra quantidade de eventos pendentes/enviados.")

    return parser


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s - %(message)s",
    )
    args = _build_parser().parse_args(argv)

    if args.command == "probe-camera":
        try:
            report = build_report(
                host=args.host,
                onvif_port=args.onvif_port,
                rtsp_port=args.rtsp_port,
                username=args.username,
            )
        except (ValueError, RuntimeError) as exc:
            print(f"Falha no diagnóstico da câmera: {exc}", file=sys.stderr)
            return 2

        payload = report.to_json()
        print(payload)
        if args.output is not None:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(payload, encoding="utf-8")
        return 0

    try:
        config = GatewayConfig.from_env()
    except ValueError as exc:
        print(f"Configuração inválida: {exc}", file=sys.stderr)
        return 2

    spool = DurableSpool(config.spool_dir)
    transport = AtlasCameraTransport(config)
    worker = DeliveryWorker(config, spool, transport)

    if args.command == "status":
        print(f"pending={len(spool.list_pending())}")
        print(
            "sent="
            f"{len([p for p in spool.sent.iterdir() if p.is_dir()])}"
        )
        return 0

    if args.command == "emit":
        captured_at = (
            datetime.fromisoformat(args.captured_at)
            if args.captured_at
            else None
        )
        try:
            event = CameraEvent.create(
                event_type=args.type,
                image_path=args.image,
                confidence=args.confidence,
                captured_at=captured_at,
                event_external_id=args.event_id,
            )
            item = spool.enqueue(event)
        except (ValueError, FileNotFoundError) as exc:
            print(f"Evento recusado localmente: {exc}", file=sys.stderr)
            return 2

        print(f"queued={item.name}")
        delivered = worker.flush_once()
        if delivered:
            print("delivery=confirmed")
        else:
            print("delivery=pending_offline")
        return 0

    if args.command == "flush":
        delivered = worker.flush_once()
        print(f"delivered={delivered}")
        print(f"pending={len(spool.list_pending())}")
        return 0

    if args.command == "worker":
        worker.run_forever()
        return 0

    if args.command == "watch-folder":
        if args.poll_seconds < 0.5:
            print(
                "--poll-seconds deve ser pelo menos 0.5.",
                file=sys.stderr,
            )
            return 2

        import time

        adapter = FolderEventAdapter(
            inbox=args.inbox,
            processed=args.processed,
        )
        while True:
            for event in adapter.poll():
                spool.enqueue(event)
            worker.flush_once()
            time.sleep(args.poll_seconds)

    return 2


if __name__ == "__main__":
    raise SystemExit(main())
