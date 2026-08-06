
from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models import (
    LivestockAnimal,
    CommercialInvoice,
    Farm,
    IotDevice,
    MlPrediction,
    RealtimeNotification,
)


def build_farm_context(
    db: Session,
    *,
    company_id: str,
    farm_id: str | None,
) -> dict:
    context: dict = {
        "farm_id": farm_id,
        "animals": 0,
        "active_alerts": 0,
        "iot_devices": 0,
        "ml_predictions": 0,
        "open_invoices": 0,
    }

    if farm_id:
        farm = db.get(Farm, farm_id)
        if farm is not None and farm.company_id == company_id:
            context["farm"] = {
                "id": farm.id,
                "name": farm.name,
            }

        context["animals"] = int(
            db.scalar(
                select(func.count())
                .select_from(LivestockAnimal)
                .where(
                    LivestockAnimal.company_id == company_id,
                    LivestockAnimal.farm_id == farm_id,
                )
            )
            or 0
        )

        context["iot_devices"] = int(
            db.scalar(
                select(func.count())
                .select_from(IotDevice)
                .where(
                    IotDevice.company_id == company_id,
                    IotDevice.farm_id == farm_id,
                )
            )
            or 0
        )

        context["active_alerts"] = int(
            db.scalar(
                select(func.count())
                .select_from(RealtimeNotification)
                .where(
                    RealtimeNotification.company_id == company_id,
                    RealtimeNotification.farm_id == farm_id,
                    RealtimeNotification.status.in_(["pending", "delivered"]),
                )
            )
            or 0
        )

    context["ml_predictions"] = int(
        db.scalar(
            select(func.count())
            .select_from(MlPrediction)
            .where(MlPrediction.company_id == company_id)
        )
        or 0
    )

    context["open_invoices"] = int(
        db.scalar(
            select(func.count())
            .select_from(CommercialInvoice)
            .where(
                CommercialInvoice.company_id == company_id,
                CommercialInvoice.status == "open",
            )
        )
        or 0
    )

    return context
