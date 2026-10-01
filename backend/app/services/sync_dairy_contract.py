"""Opt-in wire contract for dated dairy records in generic sync.

The entity id is farm-scoped and date-stable so two devices cannot create two
different records for the same farm/day. Other sync entity types are unchanged.
"""

from datetime import date
from math import isfinite
import re
from typing import Any

from ..schemas import SyncPushRequest


DAILY_PRODUCTION = "dairy_daily_production"
HERD_SNAPSHOT = "dairy_herd_snapshot"
_DAIRY_TYPES = {DAILY_PRODUCTION, HERD_SNAPSHOT}
_MIDNIGHT = re.compile(r"^(\d{4}-\d{2}-\d{2})(?:T00:00:00(?:\.0+)?Z?)?$")


def _day(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    match = _MIDNIGHT.fullmatch(value)
    if match is None:
        return None
    try:
        parsed = date.fromisoformat(match.group(1))
    except ValueError:
        return None
    if parsed.year < 1900:
        return None
    return parsed.isoformat()


def _nonnegative_number(value: Any) -> bool:
    if not isinstance(value, (int, float)) or isinstance(value, bool) or value < 0:
        return False
    try:
        return isfinite(value)
    except OverflowError:
        return False


def _nonnegative_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def validate_dairy_entity(
    *, entity_type: str, entity_id: str, farm_id: str | None,
    operation_type: str, payload: dict[str, Any],
) -> str | None:
    if entity_type not in _DAIRY_TYPES:
        return None
    if not farm_id or not farm_id.strip():
        return "Registro de leite exige farm_id."
    if operation_type not in {"create", "update", "delete"}:
        return "Operação de leite inválida."
    prefix = f"{farm_id}:"
    identity_day = _day(entity_id[len(prefix):]) if entity_id.startswith(prefix) else None
    if identity_day is None or entity_id != f"{farm_id}:{identity_day}":
        return "ID de leite deve ser farm_id:AAAA-MM-DD válido."
    if operation_type == "delete":
        return None if not payload else "Exclusão de leite exige payload vazio."
    if _day(payload.get("date")) != identity_day:
        return "Data do registro de leite difere do ID."
    if "farm_id" in payload and payload["farm_id"] != farm_id:
        return "Fazenda do registro de leite difere da operação."

    if entity_type == DAILY_PRODUCTION:
        morning = payload.get("morning_liters")
        afternoon = payload.get("afternoon_liters")
        cows = payload.get("cows_milked")
        if (
            not _nonnegative_number(morning)
            or not _nonnegative_number(afternoon)
            or not _finite_sum(morning, afternoon)
            or not isinstance(cows, int)
            or isinstance(cows, bool)
            or cows <= 0
            or not isinstance(payload.get("notes", ""), str)
        ):
            return "Ordenha exige volumes finitos, vacas positivas e notas textuais."
        return None

    fields = (
        "eligible_cows", "lactating_cows", "dry_cows",
        "pregnancies_monitored", "pregnancy_losses",
    )
    values = {name: payload.get(name, 0) for name in fields}
    if not all(_nonnegative_int(value) for value in values.values()):
        return "Estado do lote exige contagens inteiras não negativas."
    if "eligible_cows" not in payload or "lactating_cows" not in payload or "dry_cows" not in payload:
        return "Estado do lote exige contagens de aptas, lactantes e secas."
    if (values["lactating_cows"] + values["dry_cows"] > values["eligible_cows"]
            or values["pregnancy_losses"] > values["pregnancies_monitored"]):
        return "Contagens do lote são inconsistentes."
    return None


def _finite_sum(left: int | float, right: int | float) -> bool:
    try:
        return isfinite(left + right)
    except OverflowError:
        return False


def validate_dairy_push(request: SyncPushRequest) -> str | None:
    return validate_dairy_entity(
        entity_type=request.entity_type, entity_id=request.entity_id,
        farm_id=request.farm_id, operation_type=request.operation_type,
        payload=request.payload,
    )
