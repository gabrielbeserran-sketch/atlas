from __future__ import annotations

import asyncio

from ..config import get_settings
from ..database import SessionLocal
from .monthly_bulletins import process_due_schedules


settings = get_settings()


def run_due_bulletins_once() -> dict[str, int]:
    with SessionLocal() as db:
        try:
            return process_due_schedules(db)
        except Exception:
            db.rollback()
            raise


async def bulletin_scheduler_loop() -> None:
    """Scheduler resiliente dentro do serviço web.

    Se o host dormir, nenhum boletim é perdido: `next_run_at` continua vencido
    e o processamento é retomado quando o serviço acordar novamente.
    """
    while True:
        try:
            await asyncio.to_thread(run_due_bulletins_once)
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            print(
                f"ATLAS BULLETINS: falha no ciclo do scheduler: {exc}",
                flush=True,
            )

        await asyncio.sleep(settings.atlas_bulletin_poll_seconds)
