from datetime import datetime, timezone

from app.models import OperationalNote
from app.routers.operational_notes import NoteCreatePayload, _note_payload


def test_intelligence_decision_note_keeps_a_persistent_reference() -> None:
    payload = NoteCreatePayload(
        farm_id="farm-1",
        content="Decisão vinculada à análise",
        source="intelligence_decision",
        reference_type="ai_recommendation",
        reference_id="recommendation-1",
    )
    note = OperationalNote(
        id="note-1",
        tenant_id="tenant-1",
        company_id="company-1",
        farm_id=payload.farm_id,
        author_user_id="user-1",
        content=payload.content,
        source=payload.source,
        transcript="",
        reference_type=payload.reference_type,
        reference_id=payload.reference_id,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )

    serialized = _note_payload(note)

    assert serialized["source"] == "intelligence_decision"
    assert serialized["reference_type"] == "ai_recommendation"
    assert serialized["reference_id"] == "recommendation-1"
