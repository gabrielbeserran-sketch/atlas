from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import Company, Farm, Membership, new_id
from ..schemas import (
    CompanyCreateRequest,
    CompanyDetailsResponse,
    CompanyUpdateRequest,
)
from ..services.audit import record_audit

router = APIRouter(prefix="/companies", tags=["companies"])


def _authorized_membership(
    db: Session,
    principal: Principal,
    company_id: str,
) -> Membership:
    membership = db.scalar(
        select(Membership).where(
            Membership.user_id == principal.user.id,
            Membership.company_id == company_id,
            Membership.active.is_(True),
        )
    )
    if membership is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário sem vínculo ativo com esta empresa.",
        )
    return membership


def _details(
    db: Session,
    company: Company,
    membership: Membership,
) -> CompanyDetailsResponse:
    farm_count = db.scalar(
        select(func.count())
        .select_from(Farm)
        .where(
            Farm.company_id == company.id,
            Farm.tenant_id == company.tenant_id,
            Farm.active.is_(True),
        )
    ) or 0

    member_count = db.scalar(
        select(func.count())
        .select_from(Membership)
        .where(
            Membership.company_id == company.id,
            Membership.active.is_(True),
        )
    ) or 0

    return CompanyDetailsResponse(
        id=company.id,
        tenant_id=company.tenant_id,
        name=company.name,
        document=company.document,
        status=company.status,
        subscription_plan=company.subscription_plan,
        created_at=company.created_at,
        role=membership.role,
        farm_count=int(farm_count),
        member_count=int(member_count),
        active=company.id == membership.company_id,
    )


@router.get("", response_model=list[CompanyDetailsResponse])
def list_companies(
    principal: Principal = Depends(
        require_permission("companies.read")
    ),
    db: Session = Depends(get_db),
) -> list[CompanyDetailsResponse]:
    memberships = db.scalars(
        select(Membership).where(
            Membership.user_id == principal.user.id,
            Membership.active.is_(True),
        )
    ).all()

    result: list[CompanyDetailsResponse] = []
    for membership in memberships:
        company = db.get(Company, membership.company_id)
        if company is None:
            continue
        details = _details(db, company, membership)
        details.active = company.id == principal.company.id
        result.append(details)

    result.sort(key=lambda item: (not item.active, item.name.lower()))
    return result


@router.get("/{company_id}", response_model=CompanyDetailsResponse)
def get_company(
    company_id: str,
    principal: Principal = Depends(
        require_permission("companies.read")
    ),
    db: Session = Depends(get_db),
) -> CompanyDetailsResponse:
    membership = _authorized_membership(db, principal, company_id)
    company = db.get(Company, company_id)
    if company is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Empresa não encontrada.",
        )
    details = _details(db, company, membership)
    details.active = company.id == principal.company.id
    return details


@router.post("", response_model=CompanyDetailsResponse)
def create_company(
    request: CompanyCreateRequest,
    principal: Principal = Depends(
        require_permission("companies.create")
    ),
    db: Session = Depends(get_db),
) -> CompanyDetailsResponse:
    name = request.name.strip()
    if not name:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Informe o nome da empresa.",
        )

    company = Company(
        id=new_id("company"),
        tenant_id=new_id("tenant"),
        name=name,
        document=request.document.strip(),
        status="active",
        subscription_plan=request.subscription_plan.strip() or "enterprise",
    )
    db.add(company)
    db.flush()

    membership = Membership(
        id=new_id("membership"),
        user_id=principal.user.id,
        company_id=company.id,
        role="companyAdministrator",
        permission_overrides={},
        farm_ids=[],
        active=True,
    )
    db.add(membership)

    record_audit(
        db,
        principal=principal,
        action="create",
        module="companies",
        entity_type="company",
        entity_id=company.id,
        description=f'Empresa "{company.name}" criada.',
        after={
            "name": company.name,
            "document": company.document,
            "subscription_plan": company.subscription_plan,
        },
    )

    db.commit()
    db.refresh(company)
    db.refresh(membership)

    details = _details(db, company, membership)
    details.active = False
    return details


@router.patch("/{company_id}", response_model=CompanyDetailsResponse)
def update_company(
    company_id: str,
    request: CompanyUpdateRequest,
    principal: Principal = Depends(
        require_permission("companies.manage")
    ),
    db: Session = Depends(get_db),
) -> CompanyDetailsResponse:
    if company_id != principal.company.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Para editar outra empresa, altere primeiro a empresa ativa "
                "da sessão."
            ),
        )

    company = db.get(Company, company_id)
    if company is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Empresa não encontrada.",
        )

    membership = _authorized_membership(db, principal, company_id)

    before = {
        "name": company.name,
        "document": company.document,
        "subscription_plan": company.subscription_plan,
    }

    if request.name is not None:
        name = request.name.strip()
        if not name:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="O nome da empresa não pode ficar vazio.",
            )
        company.name = name

    if request.document is not None:
        company.document = request.document.strip()

    if request.subscription_plan is not None:
        plan = request.subscription_plan.strip()
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Informe o plano da empresa.",
            )
        company.subscription_plan = plan

    after = {
        "name": company.name,
        "document": company.document,
        "subscription_plan": company.subscription_plan,
    }

    record_audit(
        db,
        principal=principal,
        action="update",
        module="companies",
        entity_type="company",
        entity_id=company.id,
        description=f'Empresa "{company.name}" atualizada.',
        before=before,
        after=after,
    )

    db.commit()
    db.refresh(company)

    details = _details(db, company, membership)
    details.active = True
    return details
