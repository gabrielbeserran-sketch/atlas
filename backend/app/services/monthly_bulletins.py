from __future__ import annotations

import re
from collections import Counter
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..models import (
    BulletinDispatch,
    BulletinSchedule,
    Farm,
    FinancialEntry,
    HealthEvent,
    LivestockAnimal,
    NutritionEvent,
    OperationalTask,
    ReproductionEvent,
    WeightRecord,
    new_id,
)
from .whatsapp_provider import MetaWhatsAppProvider, WhatsAppProviderError


BULLETIN_TYPES = ("zootechnical", "operations", "financial")
BULLETIN_LABELS = {
    "zootechnical": "Boletim Zootécnico",
    "operations": "Boletim de Operação e Equipe",
    "financial": "Boletim Financeiro",
}
DEFAULT_TIMES = {
    "zootechnical": (8, 0),
    "operations": (8, 10),
    "financial": (8, 20),
}
DEFAULT_TIMEZONE = "America/Sao_Paulo"


class BulletinConfigurationError(ValueError):
    pass


def normalize_phone(value: str) -> str:
    return "".join(ch for ch in (value or "") if ch.isdigit())


def previous_month_period(
    now: datetime | None = None,
    timezone_name: str = DEFAULT_TIMEZONE,
) -> tuple[datetime, datetime]:
    zone = _local_zone(timezone_name)
    current = (now or datetime.now(timezone.utc)).astimezone(zone)
    first_current_local = datetime(
        current.year,
        current.month,
        1,
        tzinfo=zone,
    )
    last_previous_local = first_current_local - timedelta(microseconds=1)
    first_previous_local = datetime(
        last_previous_local.year,
        last_previous_local.month,
        1,
        tzinfo=zone,
    )
    return (
        first_previous_local.astimezone(timezone.utc),
        last_previous_local.astimezone(timezone.utc),
    )


def period_key(period_start: datetime) -> str:
    return period_start.astimezone(timezone.utc).strftime("%Y-%m")


def _money(value: float) -> str:
    formatted = f"{value:,.2f}"
    formatted = formatted.replace(",", "X").replace(".", ",").replace("X", ".")
    return f"R$ {formatted}"


def _decimal(value: float, digits: int = 1) -> str:
    return f"{value:.{digits}f}".replace(".", ",")


def _percent(value: float) -> str:
    return f"{value:.1f}%".replace(".", ",")


def _is_active_status(value: str) -> bool:
    return (value or "").strip().lower() in {"active", "ativo"}


def _is_female(value: str) -> bool:
    return (value or "").strip().lower() in {
        "fêmea",
        "femea",
        "female",
    }


def _is_pregnant(value: str) -> bool:
    return (value or "").strip().lower() in {"pregnant", "prenhe"}


def _local_zone(name: str) -> ZoneInfo:
    try:
        return ZoneInfo(name)
    except ZoneInfoNotFoundError as exc:
        raise BulletinConfigurationError(
            f"Fuso horário inválido: {name}"
        ) from exc


def _as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def compute_next_run(
    *,
    day_of_month: int,
    hour: int,
    minute: int,
    timezone_name: str,
    after: datetime | None = None,
) -> datetime:
    if not 1 <= day_of_month <= 28:
        raise BulletinConfigurationError(
            "Dia do mês precisa estar entre 1 e 28."
        )
    if not 0 <= hour <= 23 or not 0 <= minute <= 59:
        raise BulletinConfigurationError("Horário inválido.")

    zone = _local_zone(timezone_name)
    reference = (after or datetime.now(timezone.utc)).astimezone(zone)

    candidate = datetime(
        reference.year,
        reference.month,
        day_of_month,
        hour,
        minute,
        tzinfo=zone,
    )
    if candidate <= reference:
        if reference.month == 12:
            year, month = reference.year + 1, 1
        else:
            year, month = reference.year, reference.month + 1
        candidate = datetime(
            year,
            month,
            day_of_month,
            hour,
            minute,
            tzinfo=zone,
        )
    return candidate.astimezone(timezone.utc)


def ensure_default_schedules(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str,
) -> list[BulletinSchedule]:
    existing = list(
        db.scalars(
            select(BulletinSchedule).where(
                BulletinSchedule.company_id == company_id,
                BulletinSchedule.farm_id == farm_id,
            )
        ).all()
    )
    by_type = {item.bulletin_type: item for item in existing}
    changed = False

    for bulletin_type in BULLETIN_TYPES:
        if bulletin_type in by_type:
            continue
        hour, minute = DEFAULT_TIMES[bulletin_type]
        schedule = BulletinSchedule(
            id=new_id("bulletin_schedule"),
            tenant_id=tenant_id,
            company_id=company_id,
            farm_id=farm_id,
            bulletin_type=bulletin_type,
            recipient_whatsapp="",
            whatsapp_opt_in_at=None,
            enabled=False,
            day_of_month=1,
            hour=hour,
            minute=minute,
            timezone_name=DEFAULT_TIMEZONE,
            next_run_at=compute_next_run(
                day_of_month=1,
                hour=hour,
                minute=minute,
                timezone_name=DEFAULT_TIMEZONE,
            ),
        )
        db.add(schedule)
        by_type[bulletin_type] = schedule
        changed = True

    if changed:
        db.commit()

    return [by_type[item] for item in BULLETIN_TYPES]


def update_schedule(
    db: Session,
    schedule: BulletinSchedule,
    *,
    recipient_whatsapp: str | None = None,
    whatsapp_opt_in_confirmed: bool | None = None,
    enabled: bool | None = None,
    day_of_month: int | None = None,
    hour: int | None = None,
    minute: int | None = None,
    timezone_name: str | None = None,
) -> BulletinSchedule:
    if recipient_whatsapp is not None:
        normalized = normalize_phone(recipient_whatsapp)
        if normalized and not 10 <= len(normalized) <= 15:
            raise BulletinConfigurationError(
                "WhatsApp do destinatário deve conter de 10 a 15 dígitos."
            )
        schedule.recipient_whatsapp = normalized

    if whatsapp_opt_in_confirmed is not None:
        schedule.whatsapp_opt_in_at = (
            datetime.now(timezone.utc)
            if whatsapp_opt_in_confirmed
            else None
        )

    if enabled is not None:
        schedule.enabled = enabled
    if day_of_month is not None:
        schedule.day_of_month = day_of_month
    if hour is not None:
        schedule.hour = hour
    if minute is not None:
        schedule.minute = minute
    if timezone_name is not None:
        schedule.timezone_name = timezone_name.strip()

    if schedule.enabled and not schedule.recipient_whatsapp:
        raise BulletinConfigurationError(
            "Informe o WhatsApp do produtor antes de ativar o envio automático."
        )
    if schedule.enabled and schedule.whatsapp_opt_in_at is None:
        raise BulletinConfigurationError(
            "Confirme a autorização do produtor para receber boletins no WhatsApp."
        )

    schedule.next_run_at = compute_next_run(
        day_of_month=schedule.day_of_month,
        hour=schedule.hour,
        minute=schedule.minute,
        timezone_name=schedule.timezone_name,
    )
    db.commit()
    db.refresh(schedule)
    return schedule


def _active_animals(
    db: Session,
    *,
    company_id: str,
    farm_id: str,
) -> list[LivestockAnimal]:
    return [
        item
        for item in db.scalars(
            select(LivestockAnimal).where(
                LivestockAnimal.company_id == company_id,
                LivestockAnimal.farm_id == farm_id,
            )
        ).all()
        if _is_active_status(item.status)
    ]


def _average_gmd(
    db: Session,
    *,
    company_id: str,
    farm_id: str,
    period_start: datetime,
    period_end: datetime,
) -> float:
    animal_ids = list(
        db.scalars(
            select(LivestockAnimal.id).where(
                LivestockAnimal.company_id == company_id,
                LivestockAnimal.farm_id == farm_id,
            )
        ).all()
    )
    if not animal_ids:
        return 0.0

    records = list(
        db.scalars(
            select(WeightRecord)
            .where(
                WeightRecord.company_id == company_id,
                WeightRecord.farm_id == farm_id,
                WeightRecord.measured_at <= period_end,
            )
            .order_by(
                WeightRecord.animal_id,
                WeightRecord.measured_at.desc(),
            )
        ).all()
    )
    grouped: dict[str, list[WeightRecord]] = {}
    for record in records:
        bucket = grouped.setdefault(record.animal_id, [])
        if len(bucket) < 2:
            bucket.append(record)

    values: list[float] = []
    for recent in grouped.values():
        if len(recent) < 2:
            continue
        latest, previous = recent[0], recent[1]
        latest_at = _as_utc(latest.measured_at)
        previous_at = _as_utc(previous.measured_at)
        if latest_at is None or previous_at is None:
            continue
        days = (latest_at - previous_at).total_seconds() / 86400
        if days <= 0:
            continue
        if latest_at < period_start:
            continue
        values.append((float(latest.weight) - float(previous.weight)) / days)
    return sum(values) / len(values) if values else 0.0


def _zootechnical_content(
    db: Session,
    *,
    farm: Farm,
    period_start: datetime,
    period_end: datetime,
) -> str:
    animals = _active_animals(
        db,
        company_id=farm.company_id,
        farm_id=farm.id,
    )
    females = [item for item in animals if _is_female(item.sex)]
    pregnant = [
        item for item in females if _is_pregnant(item.reproductive_status)
    ]
    weights = [
        float(item.current_weight or 0)
        for item in animals
        if float(item.current_weight or 0) > 0
    ]
    average_weight = sum(weights) / len(weights) if weights else 0.0
    pregnancy_rate = (
        len(pregnant) / len(females) * 100 if females else 0.0
    )
    average_gmd = _average_gmd(
        db,
        company_id=farm.company_id,
        farm_id=farm.id,
        period_start=period_start,
        period_end=period_end,
    )

    health_events = db.scalar(
        select(func.count(HealthEvent.id)).where(
            HealthEvent.company_id == farm.company_id,
            HealthEvent.farm_id == farm.id,
            HealthEvent.occurred_at >= period_start,
            HealthEvent.occurred_at <= period_end,
        )
    ) or 0
    reproduction_events = db.scalar(
        select(func.count(ReproductionEvent.id)).where(
            ReproductionEvent.company_id == farm.company_id,
            ReproductionEvent.farm_id == farm.id,
            ReproductionEvent.occurred_at >= period_start,
            ReproductionEvent.occurred_at <= period_end,
        )
    ) or 0
    nutrition_cost = db.scalar(
        select(func.coalesce(func.sum(NutritionEvent.estimated_cost), 0)).where(
            NutritionEvent.company_id == farm.company_id,
            NutritionEvent.farm_id == farm.id,
            NutritionEvent.occurred_at >= period_start,
            NutritionEvent.occurred_at <= period_end,
        )
    ) or 0

    return (
        f"*{BULLETIN_LABELS['zootechnical']} — {farm.name}*\n"
        f"Período: {period_start:%m/%Y}\n\n"
        f"🐄 Animais ativos: {len(animals)}\n"
        f"⚖️ Peso médio atual: {_decimal(average_weight)} kg\n"
        f"📈 GMD médio observado: {_decimal(average_gmd, 3)} kg/dia\n"
        f"❤️ Fêmeas acompanhadas: {len(females)}\n"
        f"🤰 Prenhes: {len(pregnant)} "
        f"({_percent(pregnancy_rate)})\n"
        f"🩺 Eventos sanitários no mês: {health_events}\n"
        f"🧬 Eventos reprodutivos no mês: {reproduction_events}\n"
        f"🌱 Custo nutricional registrado: {_money(float(nutrition_cost))}\n\n"
        "Leitura Atlas: indicadores devem ser interpretados em conjunto com "
        "categoria, fase produtiva, lotação, dieta e objetivo do rebanho."
    )


_RESPONSIBLE_RE = re.compile(
    r"Respons[aá]vel\s*:\s*(.+?)\s*$",
    re.IGNORECASE | re.MULTILINE,
)


def _task_responsible(task: OperationalTask) -> str:
    match = _RESPONSIBLE_RE.search(task.description or "")
    if match:
        return match.group(1).strip()
    if task.responsible_user_id:
        return task.responsible_user_id
    return "Sem responsável informado"


def _operations_content(
    db: Session,
    *,
    farm: Farm,
    period_start: datetime,
    period_end: datetime,
) -> str:
    now = datetime.now(timezone.utc)
    open_tasks = list(
        db.scalars(
            select(OperationalTask).where(
                OperationalTask.company_id == farm.company_id,
                OperationalTask.farm_id == farm.id,
                OperationalTask.status.in_(["open", "in_progress"]),
            )
        ).all()
    )
    completed = list(
        db.scalars(
            select(OperationalTask).where(
                OperationalTask.company_id == farm.company_id,
                OperationalTask.farm_id == farm.id,
                OperationalTask.status == "completed",
                OperationalTask.completed_at >= period_start,
                OperationalTask.completed_at <= period_end,
            )
        ).all()
    )
    overdue = [
        item
        for item in open_tasks
        if _as_utc(item.due_at) is not None and _as_utc(item.due_at) < now
    ]
    by_responsible = Counter(_task_responsible(item) for item in completed)
    leaders = by_responsible.most_common(3)
    team_lines = "\n".join(
        f"• {name}: {count} concluída(s)"
        for name, count in leaders
    )
    if not team_lines:
        team_lines = "• Sem conclusão com responsável identificado no período"

    return (
        f"*{BULLETIN_LABELS['operations']} — {farm.name}*\n"
        f"Período: {period_start:%m/%Y}\n\n"
        f"📋 Tarefas abertas agora: {len(open_tasks)}\n"
        f"⏰ Tarefas atrasadas: {len(overdue)}\n"
        f"✅ Tarefas concluídas no mês: {len(completed)}\n\n"
        "*Execução por responsável*\n"
        f"{team_lines}\n\n"
        "Leitura Atlas: atraso deve ser tratado por prioridade, impacto e "
        "disponibilidade de equipe; quantidade de tarefas isolada não mede "
        "qualidade do trabalho."
    )


def _financial_content(
    db: Session,
    *,
    farm: Farm,
    period_start: datetime,
    period_end: datetime,
) -> str:
    competence_entries = list(
        db.scalars(
            select(FinancialEntry).where(
                FinancialEntry.company_id == farm.company_id,
                FinancialEntry.farm_id == farm.id,
                or_(
                    FinancialEntry.competence_date.between(
                        period_start,
                        period_end,
                    ),
                    and_(
                        FinancialEntry.competence_date.is_(None),
                        FinancialEntry.created_at.between(
                            period_start,
                            period_end,
                        ),
                    ),
                ),
            )
        ).all()
    )
    cash_entries = list(
        db.scalars(
            select(FinancialEntry).where(
                FinancialEntry.company_id == farm.company_id,
                FinancialEntry.farm_id == farm.id,
                FinancialEntry.paid_at.is_not(None),
                FinancialEntry.paid_at >= period_start,
                FinancialEntry.paid_at <= period_end,
            )
        ).all()
    )
    outstanding = list(
        db.scalars(
            select(FinancialEntry).where(
                FinancialEntry.company_id == farm.company_id,
                FinancialEntry.farm_id == farm.id,
                FinancialEntry.status != "paid",
            )
        ).all()
    )

    income = sum(
        float(item.amount or 0)
        for item in competence_entries
        if item.entry_type == "income"
    )
    expense = sum(
        float(item.amount or 0)
        for item in competence_entries
        if item.entry_type == "expense"
    )
    paid_income = sum(
        float(item.amount or 0)
        for item in cash_entries
        if item.entry_type == "income"
    )
    paid_expense = sum(
        float(item.amount or 0)
        for item in cash_entries
        if item.entry_type == "expense"
    )
    receivable = sum(
        float(item.amount or 0)
        for item in outstanding
        if item.entry_type == "income"
    )
    payable = sum(
        float(item.amount or 0)
        for item in outstanding
        if item.entry_type == "expense"
    )
    now = datetime.now(timezone.utc)
    overdue_payables = [
        item
        for item in outstanding
        if item.entry_type == "expense"
        and _as_utc(item.due_date) is not None
        and _as_utc(item.due_date) < now
    ]

    competence_balance = income - expense
    cash_balance = paid_income - paid_expense

    return (
        f"*{BULLETIN_LABELS['financial']} — {farm.name}*\n"
        f"Período: {period_start:%m/%Y}\n\n"
        f"💰 Receitas por competência: {_money(income)}\n"
        f"💸 Despesas por competência: {_money(expense)}\n"
        f"📊 Resultado por competência: {_money(competence_balance)}\n\n"
        f"✅ Recebido no período: {_money(paid_income)}\n"
        f"✅ Pago no período: {_money(paid_expense)}\n"
        f"🏦 Movimento de caixa registrado: {_money(cash_balance)}\n"
        f"📥 A receber atualmente: {_money(receivable)}\n"
        f"📤 A pagar atualmente: {_money(payable)}\n"
        f"⚠️ Contas vencidas a pagar: {len(overdue_payables)}\n\n"
        "Leitura Atlas: pecuária é atividade de ciclo longo. Resultado mensal "
        "negativo, especialmente em fases de compra, formação ou retenção de "
        "animais, não deve ser interpretado isoladamente como prejuízo do "
        "investimento. Compare com o planejamento do ciclo e o valor dos "
        "ativos produtivos."
    )

def generate_bulletin(
    db: Session,
    *,
    company_id: str,
    farm_id: str,
    bulletin_type: str,
    period_start: datetime | None = None,
    period_end: datetime | None = None,
) -> str:
    if bulletin_type not in BULLETIN_TYPES:
        raise BulletinConfigurationError("Tipo de boletim inválido.")

    farm = db.scalar(
        select(Farm).where(
            Farm.id == farm_id,
            Farm.company_id == company_id,
            Farm.active.is_(True),
        )
    )
    if farm is None:
        raise BulletinConfigurationError("Fazenda ativa não encontrada.")

    start, end = (
        (period_start, period_end)
        if period_start is not None and period_end is not None
        else previous_month_period()
    )

    if bulletin_type == "zootechnical":
        return _zootechnical_content(
            db,
            farm=farm,
            period_start=start,
            period_end=end,
        )
    if bulletin_type == "operations":
        return _operations_content(
            db,
            farm=farm,
            period_start=start,
            period_end=end,
        )
    return _financial_content(
        db,
        farm=farm,
        period_start=start,
        period_end=end,
    )


def _idempotency_key(
    *,
    farm_id: str,
    bulletin_type: str,
    period_start: datetime,
) -> str:
    return f"monthly:{farm_id}:{bulletin_type}:{period_key(period_start)}"


def get_or_create_dispatch(
    db: Session,
    *,
    schedule: BulletinSchedule,
    period_start: datetime,
    period_end: datetime,
) -> BulletinDispatch:
    key = _idempotency_key(
        farm_id=schedule.farm_id,
        bulletin_type=schedule.bulletin_type,
        period_start=period_start,
    )
    existing = db.scalar(
        select(BulletinDispatch).where(
            BulletinDispatch.idempotency_key == key,
        )
    )
    if existing is not None:
        return existing

    content = generate_bulletin(
        db,
        company_id=schedule.company_id,
        farm_id=schedule.farm_id,
        bulletin_type=schedule.bulletin_type,
        period_start=period_start,
        period_end=period_end,
    )
    dispatch = BulletinDispatch(
        id=new_id("bulletin_dispatch"),
        tenant_id=schedule.tenant_id,
        company_id=schedule.company_id,
        farm_id=schedule.farm_id,
        schedule_id=schedule.id,
        bulletin_type=schedule.bulletin_type,
        recipient_whatsapp=schedule.recipient_whatsapp,
        period_start=period_start,
        period_end=period_end,
        content=content,
        status="queued",
        provider="meta_cloud",
        provider_message_id="",
        idempotency_key=key,
        attempt_count=0,
        scheduled_for=schedule.next_run_at,
        error_message="",
    )
    db.add(dispatch)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = db.scalar(
            select(BulletinDispatch).where(
                BulletinDispatch.idempotency_key == key,
            )
        )
        if existing is None:
            raise
        return existing
    db.refresh(dispatch)
    return dispatch


def attempt_dispatch(
    db: Session,
    dispatch: BulletinDispatch,
    *,
    provider: MetaWhatsAppProvider | None = None,
) -> BulletinDispatch:
    sender = provider or MetaWhatsAppProvider()
    now = datetime.now(timezone.utc)

    db.refresh(dispatch)
    if dispatch.status in {"provider_accepted", "delivered", "read"}:
        return dispatch

    if not sender.configured:
        if dispatch.status != "processing":
            dispatch.status = "blocked_provider"
            dispatch.error_message = (
                "Boletim gerado, mas WhatsApp Business ainda não está configurado."
            )
            dispatch.last_attempt_at = now
            db.commit()
            db.refresh(dispatch)
        return dispatch

    # Reserva atômica: só uma instância do backend pode assumir o envio.
    claim = db.execute(
        update(BulletinDispatch)
        .where(
            BulletinDispatch.id == dispatch.id,
            BulletinDispatch.status.in_(
                ["queued", "failed", "blocked_provider"]
            ),
        )
        .values(
            status="processing",
            attempt_count=BulletinDispatch.attempt_count + 1,
            last_attempt_at=now,
            error_message="",
        )
    )
    db.commit()
    if not claim.rowcount:
        db.refresh(dispatch)
        return dispatch

    db.refresh(dispatch)

    try:
        result = sender.send_bulletin(
            recipient=dispatch.recipient_whatsapp,
            bulletin_type=dispatch.bulletin_type,
            content=dispatch.content,
        )
    except WhatsAppProviderError as exc:
        db.execute(
            update(BulletinDispatch)
            .where(
                BulletinDispatch.id == dispatch.id,
                BulletinDispatch.status == "processing",
            )
            .values(
                status="failed",
                error_message=str(exc)[:2000],
            )
        )
        db.commit()
        db.refresh(dispatch)
        return dispatch

    # O webhook pode chegar muito rápido. Só muda processing -> accepted;
    # se a Meta já informou delivered/read, não rebaixa o status.
    db.execute(
        update(BulletinDispatch)
        .where(
            BulletinDispatch.id == dispatch.id,
            BulletinDispatch.status == "processing",
        )
        .values(
            status="provider_accepted",
            provider_message_id=result.message_id,
            error_message="",
            sent_at=now,
        )
    )
    db.commit()
    db.refresh(dispatch)
    return dispatch

def retry_failed_dispatches(
    db: Session,
    *,
    now: datetime,
    provider: MetaWhatsAppProvider | None = None,
) -> dict[str, int]:
    threshold = now - timedelta(minutes=15)

    # Se o processo caiu depois de reservar a mensagem, libera a tentativa
    # somente após uma janela segura. O contador continua limitando retries.
    db.execute(
        update(BulletinDispatch)
        .where(
            BulletinDispatch.status == "processing",
            BulletinDispatch.last_attempt_at.is_not(None),
            BulletinDispatch.last_attempt_at <= threshold,
            BulletinDispatch.attempt_count < 3,
        )
        .values(
            status="failed",
            error_message=(
                "Tentativa anterior foi interrompida antes da confirmação "
                "do provedor; preparada para retry seguro."
            ),
        )
    )
    db.commit()

    items = list(
        db.scalars(
            select(BulletinDispatch)
            .where(
                BulletinDispatch.status == "failed",
                BulletinDispatch.attempt_count < 3,
                or_(
                    BulletinDispatch.last_attempt_at.is_(None),
                    BulletinDispatch.last_attempt_at <= threshold,
                ),
            )
            .order_by(BulletinDispatch.created_at)
            .limit(20)
        ).all()
    )
    result = {"retried": len(items), "recovered": 0, "failed": 0}
    for item in items:
        updated = attempt_dispatch(db, item, provider=provider)
        if updated.status in {"provider_accepted", "delivered", "read"}:
            result["recovered"] += 1
        else:
            result["failed"] += 1
    return result

def process_due_schedules(
    db: Session,
    *,
    now: datetime | None = None,
) -> dict[str, int]:
    current = now or datetime.now(timezone.utc)
    schedules = list(
        db.scalars(
            select(BulletinSchedule).where(
                BulletinSchedule.enabled.is_(True),
                BulletinSchedule.next_run_at.is_not(None),
                BulletinSchedule.next_run_at <= current,
            )
        ).all()
    )

    retries = retry_failed_dispatches(db, now=current)
    result = {
        "due": len(schedules),
        "accepted": 0,
        "blocked": 0,
        "failed": 0,
        "retried": retries["retried"],
        "recovered": retries["recovered"],
    }
    for schedule in schedules:
        if not schedule.recipient_whatsapp or schedule.whatsapp_opt_in_at is None:
            result["blocked"] += 1
            continue

        period_start, period_end = previous_month_period(
            current,
            schedule.timezone_name,
        )
        dispatch = get_or_create_dispatch(
            db,
            schedule=schedule,
            period_start=period_start,
            period_end=period_end,
        )
        dispatch = attempt_dispatch(db, dispatch)

        if dispatch.status in {"provider_accepted", "delivered", "read"}:
            schedule.last_run_at = current
            schedule.next_run_at = compute_next_run(
                day_of_month=schedule.day_of_month,
                hour=schedule.hour,
                minute=schedule.minute,
                timezone_name=schedule.timezone_name,
                after=current,
            )
            db.commit()
            result["accepted"] += 1
        elif dispatch.status == "blocked_provider":
            result["blocked"] += 1
        else:
            result["failed"] += 1

    return result
