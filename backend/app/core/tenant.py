from dataclasses import dataclass
from fastapi import HTTPException, status


@dataclass(frozen=True)
class TenantScope:
    tenant_id: str
    company_id: str
    farm_ids: frozenset[str]

    def assert_company(self, company_id: str) -> None:
        if company_id != self.company_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="empresa fora do escopo")

    def assert_farm(self, farm_id: str | None) -> None:
        if farm_id and self.farm_ids and farm_id not in self.farm_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="fazenda fora do escopo")
