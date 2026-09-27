"""Contrato explícito de resolução; não infere baixa por outro evento clínico."""
from copy import deepcopy
from datetime import datetime, timezone
import json

KEY = "atlas_return_resolution"


def _same_time(left, right):
    if left is None or right is None:
        return left is right
    return left.replace(tzinfo=left.tzinfo or timezone.utc).astimezone(timezone.utc) == right.replace(tzinfo=right.tzinfo or timezone.utc).astimezone(timezone.utc)


def resolution_from_task(event, task, changes, *, user_id, now=None):
    """Prepara sem mutar ORM; a rota grava fonte e tarefa na mesma transação."""
    reference = now or datetime.now(timezone.utc)
    previous = event.metadata_json or {}
    audit = previous.get(KEY)
    terminal = isinstance(audit, dict) and audit.get("status") in {"completed", "cancelled"}
    requested = changes.get("status", task.status)
    due = changes.get("due_at", event.expected_date)
    if terminal:
        if requested != audit["status"]:
            raise ValueError("Retorno resolvido não pode ser reaberto ou ter sua baixa substituída pela Agenda.")
        if not _same_time(due, event.expected_date):
            raise ValueError("Previsão de retorno resolvido não pode ser alterada.")
        if "evidence" in changes and changes["evidence"] not in {task.evidence, audit.get("reason", "")}:
            raise ValueError("Evidência de retorno resolvido deve ser preservada.")
        return validate_resolution(previous, previous, event_id=event.id,
            occurred_at=event.occurred_at, expected_at=event.expected_date,
            user_id=user_id, now=reference)
    # Uma tarefa antiga já encerrada não vira baixa clínica por uma edição de título.
    if "due_at" in changes and due is not None and due.date() < event.occurred_at.date():
        raise ValueError("Previsão não pode anteceder o evento de origem.")
    if "status" not in changes or requested not in {"completed", "cancelled"}:
        return previous
    if task.status in {"completed", "cancelled"} and task.status != requested:
        raise ValueError("Tarefa antiga tem outro encerramento; confira o retorno antes de mudar sua baixa.")
    if "due_at" in changes and not _same_time(due, event.expected_date):
        raise ValueError("Reagende e confira o retorno antes de encerrá-lo.")
    evidence = str(changes.get("evidence", task.evidence) or "").strip()
    payload = {**previous, KEY: {
        "event_id": event.id,
        "occurred_date": event.occurred_at.strftime("%d/%m/%Y"),
        "expected_date": event.expected_date.strftime("%d/%m/%Y") if event.expected_date else "",
        "status": requested, "responsible": user_id,
        "resolved_at": reference.isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        "reason": evidence,
    }}
    return validate_resolution(payload, previous, event_id=event.id,
        occurred_at=event.occurred_at, expected_at=event.expected_date,
        user_id=user_id, now=reference)


def ensure_task_resolution_compatible(tasks, metadata):
    audit = (metadata or {}).get(KEY)
    if not isinstance(audit, dict):
        return
    for task in tasks:
        if task.status in {"completed", "cancelled"} and task.status != audit["status"]:
            raise ValueError("Tarefa vinculada tem outro encerramento. Confira a divergência antes de confirmar o retorno.")


def validate_resolution(metadata, previous, *, event_id, occurred_at, expected_at, user_id, now=None):
    result = deepcopy({key: value for key, value in (previous or {}).items() if key != KEY})
    result.update(deepcopy(metadata or {}))
    old = (previous or {}).get(KEY)
    audit = result.get(KEY)
    if isinstance(old, dict) and old.get("status") in {"completed", "cancelled"}:
        old_payload = {k: v for k, v in old.items() if k != "authenticated_user_id"}
        new_payload = {k: v for k, v in audit.items() if k != "authenticated_user_id"} if isinstance(audit, dict) else None
        if old_payload != new_payload:
            raise ValueError("Resolução terminal não pode ser removida ou sobrescrita.")
    if audit is None:
        return result
    if not isinstance(audit, dict) or audit.get("status") not in {"completed", "cancelled"}:
        raise ValueError("Estado de resolução inválido.")
    if not event_id or expected_at is None or occurred_at is None:
        raise ValueError("Resolução exige evento e previsão existentes.")
    if audit.get("event_id") != event_id or audit.get("occurred_date") != occurred_at.strftime("%d/%m/%Y") or audit.get("expected_date") != expected_at.strftime("%d/%m/%Y"):
        raise ValueError("A resolução não corresponde ao evento/previsão atual.")
    actor = audit.get("responsible")
    if not isinstance(actor, str) or not actor.strip():
        raise ValueError("Responsável obrigatório.")
    if audit["status"] == "cancelled" and (not isinstance(audit.get("reason"), str) or not audit["reason"].strip()):
        raise ValueError("Motivo obrigatório no cancelamento.")
    try:
        resolved = datetime.fromisoformat(audit["resolved_at"].replace("Z", "+00:00"))
    except (ValueError, TypeError, KeyError, AttributeError):
        raise ValueError("Data de resolução inválida.") from None
    reference = now or datetime.now(timezone.utc)
    fraction = f"{resolved.microsecond // 1000:03d}"
    if resolved.microsecond % 1000:
        fraction += f"{resolved.microsecond % 1000:03d}"
    canonical = resolved.strftime("%Y-%m-%dT%H:%M:%S") + "." + fraction + "Z"
    if resolved.utcoffset() is None or resolved.utcoffset().total_seconds() != 0 or audit["resolved_at"] != canonical:
        raise ValueError("Data de resolução deve usar UTC canônico compatível com o aplicativo.")
    if resolved.tzinfo is None or resolved.utcoffset() is None or resolved > reference or resolved.date() < occurred_at.date() or expected_at.date() < occurred_at.date():
        raise ValueError("Cronologia da resolução inválida.")
    # O cliente não escolhe a autoria autenticada. Repetição preserva o autor original.
    audit["authenticated_user_id"] = old["authenticated_user_id"] if isinstance(old, dict) and old.get("authenticated_user_id") else user_id
    return result


def apply_resolution_to_task(task, metadata):
    audit = (metadata or {}).get(KEY)
    if task is None or not isinstance(audit, dict):
        return
    task.status = audit["status"]
    task.completed_at = datetime.fromisoformat(audit["resolved_at"].replace("Z", "+00:00")) if audit["status"] == "completed" else None
    marker = "Resolução do retorno: " + json.dumps(audit, ensure_ascii=False, sort_keys=True)
    if marker not in (task.evidence or ""):
        task.evidence = ((task.evidence or "") + "\n" + marker).strip()
