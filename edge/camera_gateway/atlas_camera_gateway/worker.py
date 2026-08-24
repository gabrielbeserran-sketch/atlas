from __future__ import annotations

import logging
import time

from .config import GatewayConfig
from .spool import DurableSpool
from .transport import AtlasCameraTransport


logger = logging.getLogger("atlas.camera_gateway")


class DeliveryWorker:
    def __init__(
        self,
        config: GatewayConfig,
        spool: DurableSpool,
        transport: AtlasCameraTransport,
    ) -> None:
        self.config = config
        self.spool = spool
        self.transport = transport

    def flush_once(self) -> int:
        delivered = 0
        for item in self.spool.list_pending():
            event = self.spool.load(item)
            try:
                result = self.transport.deliver(event)
            except Exception as exc:
                self.spool.mark_failed(item, str(exc))
                logger.warning(
                    "Evento %s permanece na fila: %s",
                    event.event_external_id,
                    exc,
                )
                continue

            self.spool.mark_sent(item)
            delivered += 1
            logger.info(
                "Evento %s confirmado pelo Atlas: %s / %s",
                event.event_external_id,
                result.event_id,
                result.alert_status,
            )
        return delivered

    def run_forever(self) -> None:
        delay = self.config.retry_base_seconds
        while True:
            delivered = self.flush_once()
            pending = len(self.spool.list_pending())

            if pending == 0:
                delay = self.config.retry_base_seconds
            elif delivered > 0:
                delay = self.config.retry_base_seconds
            else:
                delay = min(
                    self.config.retry_max_seconds,
                    max(
                        self.config.retry_base_seconds,
                        delay * 2,
                    ),
                )

            time.sleep(delay)
