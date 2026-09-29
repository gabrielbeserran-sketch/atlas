from ..models import ProcessedOperation
from ..schemas import SyncPushRequest, SyncPushResponse


def replay_processed_operation(
    processed: ProcessedOperation | None,
    request: SyncPushRequest,
) -> SyncPushResponse | None:
    """Only replay a stored response to its original company and operation."""
    if processed is None:
        return None
    if (
        processed.company_id != request.company_id
        or processed.operation_id != request.operation_id
    ):
        return SyncPushResponse(
            accepted=False,
            conflict=False,
            remote_version=0,
            remote_payload={},
            error="Chave de idempotência já utilizada por outra operação.",
        )
    return SyncPushResponse(**processed.result_payload)
