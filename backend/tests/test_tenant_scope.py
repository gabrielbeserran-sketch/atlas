import pytest
from fastapi import HTTPException
from app.core.tenant import TenantScope


def test_tenant_scope_blocks_other_company():
    scope = TenantScope("tenant_a", "company_a", frozenset())
    with pytest.raises(HTTPException): scope.assert_company("company_b")


def test_tenant_scope_blocks_unlisted_farm():
    scope = TenantScope("tenant_a", "company_a", frozenset({"farm_a"}))
    with pytest.raises(HTTPException): scope.assert_farm("farm_b")
