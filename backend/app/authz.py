from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import get_db
from .models import Company, Membership, User
from .security import decode_access_token

bearer = HTTPBearer(auto_error=True)

KNOWN_PERMISSIONS: set[str] = {
    "companies.read",
    "companies.create",
    "companies.manage",
    "members.read",
    "members.manage",
    "farms.read",
    "farms.create",
    "farms.update",
    "animals.delete",
    "animals.update",
    "animals.create",
    "animals.read",
    "sync.read",
    "sync.manage",
    "audit.read",
    "backup.read",
    "backup.run",
    "system.read",
    "reports.read",
    "analytics.read",
    "analytics.manage",
    "ai.use",
    "ai.read",
    "ai.manage",
    "realtime.read",
    "realtime.publish",
    "notifications.read",
    "notifications.manage",
    "iot.read",
    "iot.manage",
    "iot.command",
    "commercial.read",
    "commercial.manage",
    "billing.read",
    "billing.manage",
    "ml.read",
    "ml.manage",
    "ml.train",
    "ml.deploy",
    "ml.predict",
    "ml.feedback",
    "atlas_ai.use",
    "atlas_ai.read",
    "atlas_ai.manage",
    "automation.read",
    "automation.manage",
    "automation.execute",
    "strategy.read",
    "strategy.manage",
    "governance.read",
    "governance.manage",
    "compliance.read",
    "compliance.manage",
    "resilience.read",
    "resilience.manage",
    "integrations.read",
    "integrations.manage",
    "integrations.execute",
    "partners.read",
    "partners.manage",
    "security_enterprise.read",
    "security_enterprise.manage",
    "privacy.read",
    "privacy.manage",
    "continuity.read",
    "continuity.manage",
    "release.read",
    "release.manage",
    "release.execute",
    "release.approve",
    "herd.read",
    "herd.write",
    "reproduction.read",
    "reproduction.write",
    "health.read",
    "health.write",
    "nutrition.read",
    "nutrition.write",
    "inventory.read",
    "inventory.write",
    "finance.read",
    "finance.write",
    "platform.read",
    "platform.manage",
}

ROLE_PERMISSIONS: dict[str, set[str]] = {
    "superAdministrator": {"*"},
    "companyAdministrator": {"*"},
    "owner": {"*"},
    "manager": {
        "companies.read",
        "members.read",
        "farms.read",
        "farms.create",
        "farms.update",
        "sync.read",
        "sync.manage",
        "audit.read",
        "backup.read",
        "system.read",
        "reports.read",
        "animals.read",
        "animals.create",
        "animals.update",
        "animals.delete",

        "analytics.read",
        "analytics.manage",    },
    "consultant": {
        "farms.read",
        "sync.read",
        "sync.manage",
        "reports.read",
        "animals.read",
        "animals.create",
        "animals.update",

        "analytics.read",    },
    "veterinarian": {
        "farms.read",
        "sync.read",
        "sync.manage",
        "animals.read",
        "animals.create",
        "animals.update",
    },
    "technician": {
        "farms.read",
        "sync.read",
        "sync.manage",
        "animals.read",
        "animals.create",
        "animals.update",
    },
    "financial": {
        "farms.read",
        "sync.read",
        "reports.read",

        "analytics.read",    },
    "operator": {
        "farms.read",
        "sync.read",
        "sync.manage",
        "animals.read",
        "animals.create",
        "animals.update",
    },
    "viewer": {
        "farms.read",
        "sync.read",
        "animals.read",
    },
    "auditor": {
        "companies.read",
        "members.read",
        "farms.read",
        "sync.read",
        "audit.read",
        "reports.read",
        "backup.read",
        "system.read",
        "animals.read",

        "analytics.read",    },
}

# Permissões pecuárias consolidadas das Fases 4 e 5.
_DOMAIN_READ = {
    "herd.read", "reproduction.read", "health.read", "nutrition.read",
    "inventory.read", "finance.read", "platform.read",
}
_DOMAIN_WRITE = {
    "herd.write", "reproduction.write", "health.write", "nutrition.write",
    "inventory.write", "finance.write", "platform.manage",
}
for _role in ("manager", "consultant"):
    ROLE_PERMISSIONS.setdefault(_role, set()).update(_DOMAIN_READ | _DOMAIN_WRITE)
for _role in ("veterinarian", "technician", "operator"):
    ROLE_PERMISSIONS.setdefault(_role, set()).update(
        {"herd.read", "herd.write", "reproduction.read", "reproduction.write",
         "health.read", "health.write", "nutrition.read", "nutrition.write",
         "inventory.read", "platform.read"}
    )
ROLE_PERMISSIONS.setdefault("financial", set()).update(
    {"finance.read", "finance.write", "inventory.read", "platform.read"}
)
for _role in ("viewer", "auditor"):
    ROLE_PERMISSIONS.setdefault(_role, set()).update(_DOMAIN_READ)


MANAGEABLE_ROLES: tuple[str, ...] = (
    "companyAdministrator",
    "manager",
    "consultant",
    "veterinarian",
    "technician",
    "financial",
    "operator",
    "viewer",
    "auditor",
)


@dataclass(frozen=True)
class Principal:
    user: User
    company: Company
    membership: Membership
    permissions: set[str]


def resolve_permissions(membership: Membership) -> set[str]:
    role_permissions = ROLE_PERMISSIONS.get(membership.role, set())
    permissions = (
        set(KNOWN_PERMISSIONS)
        if "*" in role_permissions
        else set(role_permissions)
    )

    for key, effect in (membership.permission_overrides or {}).items():
        if key not in KNOWN_PERMISSIONS:
            continue
        if effect == "allow":
            permissions.add(key)
        elif effect == "deny":
            permissions.discard(key)

    return permissions


def get_principal(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
) -> Principal:
    claims = decode_access_token(credentials.credentials)
    user_id = str(claims.get("sub", ""))
    company_id = str(claims.get("company_id", ""))

    user = db.get(User, user_id)
    company = db.get(Company, company_id)

    membership = db.scalar(
        select(Membership).where(
            Membership.user_id == user_id,
            Membership.company_id == company_id,
            Membership.active.is_(True),
        )
    )

    if (
        user is None
        or company is None
        or membership is None
        or not user.active
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sessão sem vínculo empresarial válido.",
        )

    if claims.get("tenant_id") != company.tenant_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tenant inválido para a empresa ativa.",
        )

    return Principal(
        user=user,
        company=company,
        membership=membership,
        permissions=resolve_permissions(membership),
    )


def require_permission(permission: str):
    def dependency(
        principal: Principal = Depends(get_principal),
    ) -> Principal:
        if permission not in principal.permissions:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permissão necessária: {permission}",
            )
        return principal

    return dependency


def require_farm_scope(
    principal: Principal,
    farm_id: str | None,
) -> None:
    if farm_id is None:
        return
    allowed = principal.membership.farm_ids or []
    if allowed and farm_id not in allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Fazenda fora da carteira autorizada.",
        )
