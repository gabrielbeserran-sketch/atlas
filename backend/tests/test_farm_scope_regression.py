from types import SimpleNamespace

from app.authz import require_farm_scope
from app.routers.livestock import _farm_allowed


def principal(role="consultant", farm_ids=None):
    return SimpleNamespace(
        membership=SimpleNamespace(role=role, farm_ids=[] if farm_ids is None else farm_ids)
    )

def test_empty_farm_scope_means_all_farms():
    p = principal(farm_ids=[])
    require_farm_scope(p, "farm_any")
    _farm_allowed(p, "farm_any")

def test_restricted_farm_scope_accepts_member_farm():
    p = principal(farm_ids=["farm_1"])
    require_farm_scope(p, "farm_1")
    _farm_allowed(p, "farm_1")
