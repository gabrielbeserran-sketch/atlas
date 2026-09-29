import hashlib
import json

from ..models import EntityState, ProcessedOperation
from ..schemas import SyncPushRequest, SyncPushResponse


def request_fingerprint(request: SyncPushRequest) -> str:
    serialized = json.dumps(
        request.model_dump(), sort_keys=True, separators=(",", ":"),
        ensure_ascii=False,
    )
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def stored_result(request: SyncPushRequest, response: SyncPushResponse) -> dict:
    return {
        **response.model_dump(),
        "_request_fingerprint": request_fingerprint(request),
    }


def replay_processed_operation(
    processed: ProcessedOperation | None,
    request: SyncPushRequest,
    state: EntityState | None = None,
) -> SyncPushResponse | None:
    """Replay only the original request; tolerate verifiable old successes."""
    if processed is None:
        return None
    mismatched_identity = (
        processed.company_id != request.company_id
        or processed.operation_id != request.operation_id
    )
    saved_hash = processed.result_payload.get("_request_fingerprint")
    legacy_safe = (
        saved_hash is None
        and processed.result_payload.get("accepted") is True
        and processed.result_payload.get("remote_payload") == request.payload
        and state is not None
        and state.farm_id == request.farm_id
    )
    if mismatched_identity or not (
        saved_hash == request_fingerprint(request) or legacy_safe
    ):
        return SyncPushResponse(
            accepted=False,
            conflict=False,
            remote_version=0,
            remote_payload={},
            error="Chave de idempotência já utilizada por outra operação.",
        )
    return SyncPushResponse(**processed.result_payload)
