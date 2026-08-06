from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..authz import (
    KNOWN_PERMISSIONS,
    MANAGEABLE_ROLES,
    Principal,
    require_permission,
    resolve_permissions,
)
from ..database import get_db
from ..models import Farm, Membership, User, new_id
from ..schemas import (
    MemberCreateRequest,
    MemberPasswordResetRequest,
    MemberResponse,
    MemberUpdateRequest,
    PermissionCatalogResponse,
)
from ..security import hash_password
from ..services.audit import record_audit

router = APIRouter(prefix="/members", tags=["members"])

ADMIN_ROLES = {"superAdministrator", "companyAdministrator", "owner"}


def _validate_role(role: str) -> str:
    normalized = role.strip()
    if normalized not in MANAGEABLE_ROLES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Perfil de acesso inválido.",
        )
    return normalized


def _validate_overrides(overrides: dict[str, str]) -> dict[str, str]:
    cleaned: dict[str, str] = {}
    for permission, effect in overrides.items():
        if permission not in KNOWN_PERMISSIONS:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Permissão desconhecida: {permission}",
            )
        if effect not in {"allow", "deny"}:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    f"Override inválido para {permission}. "
                    "Use allow ou deny."
                ),
            )
        cleaned[permission] = effect
    return cleaned


def _validate_farms(
    db: Session,
    principal: Principal,
    farm_ids: list[str],
) -> list[str]:
    unique = list(dict.fromkeys(farm_ids))
    if not unique:
        return []

    found = db.scalars(
        select(Farm.id).where(
            Farm.company_id == principal.company.id,
            Farm.tenant_id == principal.company.tenant_id,
            Farm.active.is_(True),
            Farm.id.in_(unique),
        )
    ).all()

    if set(found) != set(unique):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Uma ou mais fazendas não pertencem à empresa ativa.",
        )
    return unique


def _member_response(
    principal: Principal,
    membership: Membership,
    user: User,
) -> MemberResponse:
    return MemberResponse(
        membership_id=membership.id,
        user_id=user.id,
        name=user.name,
        email=user.email,
        role=membership.role,
        active=membership.active and user.active,
        farm_ids=list(membership.farm_ids or []),
        permission_overrides=dict(membership.permission_overrides or {}),
        effective_permissions=sorted(resolve_permissions(membership)),
        started_at=membership.started_at,
        is_self=user.id == principal.user.id,
    )


def _get_membership(
    db: Session,
    principal: Principal,
    membership_id: str,
) -> Membership:
    membership = db.scalar(
        select(Membership).where(
            Membership.id == membership_id,
            Membership.company_id == principal.company.id,
        )
    )
    if membership is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vínculo não encontrado na empresa ativa.",
        )
    return membership


def _ensure_admin_remains(
    db: Session,
    principal: Principal,
    membership: Membership,
    *,
    next_role: str,
    next_active: bool,
) -> None:
    if not membership.active or membership.role not in ADMIN_ROLES:
        return
    if next_active and next_role in ADMIN_ROLES:
        return

    admin_count = db.scalar(
        select(func.count())
        .select_from(Membership)
        .where(
            Membership.company_id == principal.company.id,
            Membership.active.is_(True),
            Membership.role.in_(ADMIN_ROLES),
        )
    ) or 0

    if int(admin_count) <= 1:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A empresa deve manter ao menos um administrador ativo.",
        )


@router.get("/catalog", response_model=PermissionCatalogResponse)
def permission_catalog(
    principal: Principal = Depends(require_permission("members.read")),
) -> PermissionCatalogResponse:
    return PermissionCatalogResponse(
        roles=list(MANAGEABLE_ROLES),
        permissions=sorted(KNOWN_PERMISSIONS),
    )


@router.get("", response_model=list[MemberResponse])
def list_members(
    principal: Principal = Depends(require_permission("members.read")),
    db: Session = Depends(get_db),
) -> list[MemberResponse]:
    memberships = db.scalars(
        select(Membership).where(
            Membership.company_id == principal.company.id,
        )
    ).all()

    result: list[MemberResponse] = []
    for membership in memberships:
        user = db.get(User, membership.user_id)
        if user is None:
            continue
        result.append(_member_response(principal, membership, user))

    result.sort(key=lambda item: (not item.active, item.name.lower()))
    return result


@router.post("", response_model=MemberResponse)
def create_member(
    request: MemberCreateRequest,
    principal: Principal = Depends(require_permission("members.manage")),
    db: Session = Depends(get_db),
) -> MemberResponse:
    name = request.name.strip()
    email = request.email.strip().lower()
    role = _validate_role(request.role)
    farm_ids = _validate_farms(db, principal, request.farm_ids)
    overrides = _validate_overrides(request.permission_overrides)

    if not name or "@" not in email:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Informe nome e e-mail válidos.",
        )

    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        password = request.password or ""
        if len(password) < 8:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="A senha inicial deve possuir ao menos 8 caracteres.",
            )
        user = User(
            id=new_id("user"),
            name=name,
            email=email,
            password_hash=hash_password(password),
            active=True,
        )
        db.add(user)
        db.flush()
    else:
        existing = db.scalar(
            select(Membership).where(
                Membership.user_id == user.id,
                Membership.company_id == principal.company.id,
            )
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Este usuário já possui vínculo com a empresa ativa.",
            )

    membership = Membership(
        id=new_id("membership"),
        user_id=user.id,
        company_id=principal.company.id,
        role=role,
        permission_overrides=overrides,
        farm_ids=farm_ids,
        active=True,
    )
    db.add(membership)

    record_audit(
        db,
        principal=principal,
        action="create",
        module="members",
        entity_type="membership",
        entity_id=membership.id,
        description=f'Usuário "{user.email}" vinculado à empresa.',
        after={
            "user_id": user.id,
            "email": user.email,
            "role": membership.role,
            "farm_ids": membership.farm_ids,
            "permission_overrides": membership.permission_overrides,
        },
    )

    db.commit()
    db.refresh(user)
    db.refresh(membership)
    return _member_response(principal, membership, user)


@router.patch("/{membership_id}", response_model=MemberResponse)
def update_member(
    membership_id: str,
    request: MemberUpdateRequest,
    principal: Principal = Depends(require_permission("members.manage")),
    db: Session = Depends(get_db),
) -> MemberResponse:
    membership = _get_membership(db, principal, membership_id)
    user = db.get(User, membership.user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário do vínculo não encontrado.",
        )

    next_role = (
        _validate_role(request.role)
        if request.role is not None
        else membership.role
    )
    next_active = (
        request.active if request.active is not None else membership.active
    )

    if user.id == principal.user.id and (
        next_role != membership.role or not next_active
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "O administrador não pode alterar o próprio perfil ou "
                "desativar o próprio vínculo nesta sessão."
            ),
        )

    _ensure_admin_remains(
        db,
        principal,
        membership,
        next_role=next_role,
        next_active=next_active,
    )

    next_farms = (
        _validate_farms(db, principal, request.farm_ids)
        if request.farm_ids is not None
        else list(membership.farm_ids or [])
    )
    next_overrides = (
        _validate_overrides(request.permission_overrides)
        if request.permission_overrides is not None
        else dict(membership.permission_overrides or {})
    )

    before = {
        "role": membership.role,
        "active": membership.active,
        "farm_ids": list(membership.farm_ids or []),
        "permission_overrides": dict(membership.permission_overrides or {}),
    }

    membership.role = next_role
    membership.active = next_active
    membership.farm_ids = next_farms
    membership.permission_overrides = next_overrides

    after = {
        "role": membership.role,
        "active": membership.active,
        "farm_ids": list(membership.farm_ids or []),
        "permission_overrides": dict(membership.permission_overrides or {}),
    }

    record_audit(
        db,
        principal=principal,
        action="update",
        module="members",
        entity_type="membership",
        entity_id=membership.id,
        description=f'Permissões de "{user.email}" atualizadas.',
        before=before,
        after=after,
    )

    db.commit()
    db.refresh(membership)
    return _member_response(principal, membership, user)


@router.post("/{membership_id}/reset-password")
def reset_member_password(
    membership_id: str,
    request: MemberPasswordResetRequest,
    principal: Principal = Depends(require_permission("members.manage")),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    membership = _get_membership(db, principal, membership_id)
    user = db.get(User, membership.user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário do vínculo não encontrado.",
        )

    if len(request.password) < 8:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="A nova senha deve possuir ao menos 8 caracteres.",
        )

    user.password_hash = hash_password(request.password)
    user.active = True

    record_audit(
        db,
        principal=principal,
        action="reset_password",
        module="members",
        entity_type="user",
        entity_id=user.id,
        description=f'Senha de "{user.email}" redefinida pelo administrador.',
    )

    db.commit()
    return {"status": "ok", "message": "Senha redefinida com sucesso."}
