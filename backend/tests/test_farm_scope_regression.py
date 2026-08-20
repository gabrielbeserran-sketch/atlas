from types import SimpleNamespace

from app.authz import require_farm_scope
from app.routers.livestock import _farm_allowed


class FakeDb:
    def __init__(self, farm_exists=True):
        self.farm_exists = farm_exists

    def scalar(self, _query):
        return object() if self.farm_exists else None


def principal(role="consultant", farm_ids=None):
    return SimpleNamespace(
        company=SimpleNamespace(id="company_1", tenant_id="tenant_1"),
        membership=SimpleNamespace(
            role=role,
            farm_ids=[] if farm_ids is None else farm_ids,
        ),
    )


def test_empty_farm_scope_means_all_company_farms():
    p = principal(farm_ids=[])
    require_farm_scope(p, "farm_any")
    _farm_allowed(FakeDb(), p, "farm_any")


def test_restricted_farm_scope_accepts_member_farm():
    p = principal(farm_ids=["farm_1"])
    require_farm_scope(p, "farm_1")
    _farm_allowed(FakeDb(), p, "farm_1")


def test_missing_or_cross_company_farm_is_rejected():
    p = principal(farm_ids=[])
    try:
        _farm_allowed(FakeDb(farm_exists=False), p, "farm_other_company")
    except Exception as exc:
        assert getattr(exc, "status_code", None) == 404
    else:
        raise AssertionError("Fazenda externa deveria ser rejeitada.")
