from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models import (
    AnimalMovement,
    Farm,
    FinancialEntry,
    HealthEvent,
    HerdLot,
    InventoryMovement,
    InventoryProduct,
    LivestockAnimal,
    NutritionEvent,
    ReproductionEvent,
    WeightRecord,
)

ACTIVE_STATUSES = {"active", "ativo"}
EXIT_MOVEMENTS = {"sale", "sold", "exit", "death", "cull", "discard"}


@dataclass(frozen=True)
class ValidationContext:
    company_id: str
    farm_id: str


def _count(db: Session, model: type, *conditions: Any) -> int:
    return int(db.scalar(select(func.count()).select_from(model).where(*conditions)) or 0)


def _farm(db: Session, ctx: ValidationContext) -> Farm | None:
    return db.scalar(
        select(Farm).where(
            Farm.id == ctx.farm_id,
            Farm.company_id == ctx.company_id,
        )
    )


def _active_animals(db: Session, ctx: ValidationContext) -> list[LivestockAnimal]:
    return list(
        db.scalars(
            select(LivestockAnimal).where(
                LivestockAnimal.company_id == ctx.company_id,
                LivestockAnimal.farm_id == ctx.farm_id,
                LivestockAnimal.status.in_(ACTIVE_STATUSES),
            )
        )
    )


def validate_farm(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    farm = _farm(db, ctx)
    if farm is None:
        return {"status": "error", "issues": ["farm_not_found"], "score": 0}
    issues: list[str] = []
    if not farm.name.strip():
        issues.append("missing_name")
    if farm.area < 0:
        issues.append("negative_area")
    return {
        "status": "ok" if not issues else "warning",
        "score": max(0, 100 - 20 * len(issues)),
        "issues": issues,
        "farm": {"id": farm.id, "name": farm.name, "active": farm.active},
    }


def validate_lots(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    lots = list(
        db.scalars(
            select(HerdLot).where(
                HerdLot.company_id == ctx.company_id,
                HerdLot.farm_id == ctx.farm_id,
            )
        )
    )
    animals = _active_animals(db, ctx)
    counts = Counter(a.lot_id for a in animals if a.lot_id)
    over_capacity = [lot.id for lot in lots if lot.capacity > 0 and counts[lot.id] > lot.capacity]
    inactive_with_animals = [
        lot.id for lot in lots if lot.status not in ACTIVE_STATUSES and counts[lot.id] > 0
    ]
    issues = [
        *[f"over_capacity:{item}" for item in over_capacity],
        *[f"inactive_with_animals:{item}" for item in inactive_with_animals],
    ]
    return {
        "status": "ok" if not issues else "warning",
        "score": max(0, 100 - 15 * len(issues)),
        "issues": issues,
        "total": len(lots),
        "active": sum(1 for lot in lots if lot.status in ACTIVE_STATUSES),
        "animal_count_by_lot": dict(counts),
    }


def validate_animals(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    animals = _active_animals(db, ctx)
    tags = Counter(a.tag.strip().lower() for a in animals if a.tag.strip())
    duplicate_tags = [tag for tag, count in tags.items() if count > 1]
    missing_tag = [a.id for a in animals if not a.tag.strip()]
    invalid_weight = [a.id for a in animals if a.current_weight < 0]
    issues = [
        *[f"duplicate_tag:{tag}" for tag in duplicate_tags],
        *[f"missing_tag:{item}" for item in missing_tag],
        *[f"negative_weight:{item}" for item in invalid_weight],
    ]
    return {
        "status": "ok" if not issues else "warning",
        "score": max(0, 100 - 10 * len(issues)),
        "issues": issues,
        "total_active": len(animals),
        "without_lot": sum(1 for a in animals if not a.lot_id),
        "without_weight": sum(1 for a in animals if a.current_weight <= 0),
    }


def validate_weights(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    records = list(
        db.scalars(
            select(WeightRecord).where(
                WeightRecord.company_id == ctx.company_id,
                WeightRecord.farm_id == ctx.farm_id,
            )
        )
    )
    invalid = [r.id for r in records if r.weight <= 0 or r.weight > 2500]
    latest: dict[str, WeightRecord] = {}
    for record in records:
        current = latest.get(record.animal_id)
        if current is None or record.measured_at > current.measured_at:
            latest[record.animal_id] = record
    mismatches: list[str] = []
    if latest:
        animals = {
            a.id: a
            for a in db.scalars(
                select(LivestockAnimal).where(LivestockAnimal.id.in_(latest.keys()))
            )
        }
        for animal_id, record in latest.items():
            animal = animals.get(animal_id)
            if animal and abs(animal.current_weight - record.weight) > 0.01:
                mismatches.append(animal_id)
    issues = [*[f"invalid_weight:{item}" for item in invalid], *[f"current_weight_mismatch:{item}" for item in mismatches]]
    return {
        "status": "ok" if not issues else "warning",
        "score": max(0, 100 - 10 * len(issues)),
        "issues": issues,
        "records": len(records),
        "animals_with_history": len(latest),
    }


def validate_movements(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    movements = list(
        db.scalars(
            select(AnimalMovement).where(
                AnimalMovement.company_id == ctx.company_id,
                AnimalMovement.farm_id == ctx.farm_id,
            )
        )
    )
    invalid_same_lot = [
        m.id
        for m in movements
        if m.movement_type in {"lot_change", "change_lot"}
        and m.from_lot_id
        and m.from_lot_id == m.to_lot_id
    ]
    missing_destination = [
        m.id
        for m in movements
        if m.movement_type in {"lot_change", "change_lot"} and not m.to_lot_id
    ]
    issues = [*[f"same_lot:{item}" for item in invalid_same_lot], *[f"missing_destination:{item}" for item in missing_destination]]
    return {
        "status": "ok" if not issues else "warning",
        "score": max(0, 100 - 15 * len(issues)),
        "issues": issues,
        "records": len(movements),
        "exits": sum(1 for m in movements if m.movement_type in EXIT_MOVEMENTS),
    }


def validate_reproduction(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    events = list(db.scalars(select(ReproductionEvent).where(ReproductionEvent.company_id == ctx.company_id, ReproductionEvent.farm_id == ctx.farm_id)))
    animals = {a.id: a for a in _active_animals(db, ctx)}
    male_events = [e.id for e in events if animals.get(e.animal_id) and animals[e.animal_id].sex.lower() in {"male", "macho", "m"}]
    future_events = sum(1 for e in events if e.expected_date and e.expected_date > datetime.now(timezone.utc))
    issues = [f"event_for_male:{item}" for item in male_events]
    return {"status": "ok" if not issues else "warning", "score": max(0, 100 - 15 * len(issues)), "issues": issues, "records": len(events), "future_actions": future_events}


def validate_health(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    events = list(db.scalars(select(HealthEvent).where(HealthEvent.company_id == ctx.company_id, HealthEvent.farm_id == ctx.farm_id)))
    now = datetime.now(timezone.utc)
    active_withdrawal = sum(1 for e in events if (e.withdrawal_meat_until and e.withdrawal_meat_until > now) or (e.withdrawal_milk_until and e.withdrawal_milk_until > now))
    return {"status": "ok", "score": 100, "issues": [], "records": len(events), "active_withdrawal": active_withdrawal}


def validate_nutrition(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    events = list(db.scalars(select(NutritionEvent).where(NutritionEvent.company_id == ctx.company_id, NutritionEvent.farm_id == ctx.farm_id)))
    invalid = [e.id for e in events if e.total_quantity < 0 or e.estimated_cost < 0]
    issues = [f"negative_value:{item}" for item in invalid]
    return {"status": "ok" if not issues else "warning", "score": max(0, 100 - 15 * len(issues)), "issues": issues, "records": len(events), "total_quantity": round(sum(e.total_quantity for e in events), 3), "total_cost": round(sum(e.estimated_cost for e in events), 2)}


def validate_inventory(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    products = list(db.scalars(select(InventoryProduct).where(InventoryProduct.company_id == ctx.company_id, InventoryProduct.farm_id == ctx.farm_id)))
    movements = list(db.scalars(select(InventoryMovement).where(InventoryMovement.company_id == ctx.company_id, InventoryMovement.farm_id == ctx.farm_id)))
    negative = [p.id for p in products if p.quantity < 0]
    below_minimum = [p.id for p in products if p.minimum_quantity > 0 and p.quantity <= p.minimum_quantity]
    issues = [f"negative_stock:{item}" for item in negative]
    return {"status": "ok" if not issues else "warning", "score": max(0, 100 - 20 * len(issues)), "issues": issues, "products": len(products), "movements": len(movements), "below_minimum": below_minimum}


def validate_finance(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    entries = list(db.scalars(select(FinancialEntry).where(FinancialEntry.company_id == ctx.company_id, FinancialEntry.farm_id == ctx.farm_id)))
    invalid = [e.id for e in entries if e.amount < 0]
    revenues = sum(e.amount for e in entries if e.entry_type in {"income", "revenue", "receita"})
    expenses = sum(e.amount for e in entries if e.entry_type in {"expense", "despesa"})
    issues = [f"negative_amount:{item}" for item in invalid]
    return {"status": "ok" if not issues else "warning", "score": max(0, 100 - 15 * len(issues)), "issues": issues, "entries": len(entries), "revenues": round(revenues, 2), "expenses": round(expenses, 2), "balance": round(revenues - expenses, 2)}


def validate_all(db: Session, ctx: ValidationContext) -> dict[str, Any]:
    domains = {
        "farm": validate_farm(db, ctx),
        "lots": validate_lots(db, ctx),
        "animals": validate_animals(db, ctx),
        "weights": validate_weights(db, ctx),
        "movements": validate_movements(db, ctx),
        "reproduction": validate_reproduction(db, ctx),
        "health": validate_health(db, ctx),
        "nutrition": validate_nutrition(db, ctx),
        "inventory": validate_inventory(db, ctx),
        "finance": validate_finance(db, ctx),
    }
    score = round(sum(item["score"] for item in domains.values()) / len(domains), 2)
    issues = sum(len(item["issues"]) for item in domains.values())
    return {
        "farm_id": ctx.farm_id,
        "company_id": ctx.company_id,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "score": score,
        "status": "ready" if issues == 0 else "attention",
        "issue_count": issues,
        "domains": domains,
    }
