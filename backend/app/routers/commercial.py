
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    CommercialContract,
    CommercialCustomer,
    CommercialInvoice,
    CommercialOpportunity,
    CommercialPlan,
    CommercialProposal,
    CommercialSubscription,
    new_id,
)
from ..schemas import (
    CommercialContractCreateRequest,
    CommercialContractResponse,
    CommercialCustomerCreateRequest,
    CommercialCustomerResponse,
    CommercialInvoiceCreateRequest,
    CommercialInvoiceResponse,
    CommercialOpportunityCreateRequest,
    CommercialOpportunityResponse,
    CommercialOpportunityUpdateRequest,
    CommercialPlanCreateRequest,
    CommercialPlanResponse,
    CommercialProposalCreateRequest,
    CommercialProposalResponse,
    CommercialSubscriptionCreateRequest,
    CommercialSubscriptionResponse,
)
from ..services.commercial_service import (
    create_due_notifications,
    create_invoice_for_subscription,
    proposal_totals,
)
from ..services.realtime_hub import realtime_hub

router = APIRouter(prefix="/commercial", tags=["commercial"])


@router.post("/customers", response_model=CommercialCustomerResponse, status_code=201)
def create_customer(
    payload: CommercialCustomerCreateRequest,
    principal: Principal = Depends(require_permission("commercial.manage")),
    db: Session = Depends(get_db),
) -> CommercialCustomer:
    item = CommercialCustomer(
        id=new_id("customer"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="lead",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/customers", response_model=list[CommercialCustomerResponse])
def list_customers(
    status_filter: str | None = Query(default=None, alias="status"),
    search: str | None = None,
    principal: Principal = Depends(require_permission("commercial.read")),
    db: Session = Depends(get_db),
) -> list[CommercialCustomer]:
    query = select(CommercialCustomer).where(
        CommercialCustomer.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(CommercialCustomer.status == status_filter)
    if search:
        pattern = f"%{search.strip()}%"
        query = query.where(
            CommercialCustomer.name.ilike(pattern)
            | CommercialCustomer.email.ilike(pattern)
            | CommercialCustomer.document.ilike(pattern)
        )
    return list(db.scalars(query.order_by(CommercialCustomer.name)).all())


@router.post("/opportunities", response_model=CommercialOpportunityResponse, status_code=201)
def create_opportunity(
    payload: CommercialOpportunityCreateRequest,
    principal: Principal = Depends(require_permission("commercial.manage")),
    db: Session = Depends(get_db),
) -> CommercialOpportunity:
    customer = db.get(CommercialCustomer, payload.customer_id)
    if customer is None or customer.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Cliente não encontrado.")

    item = CommercialOpportunity(
        id=new_id("opportunity"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        stage="qualification",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/opportunities", response_model=list[CommercialOpportunityResponse])
def list_opportunities(
    stage: str | None = None,
    principal: Principal = Depends(require_permission("commercial.read")),
    db: Session = Depends(get_db),
) -> list[CommercialOpportunity]:
    query = select(CommercialOpportunity).where(
        CommercialOpportunity.company_id == principal.company.id
    )
    if stage:
        query = query.where(CommercialOpportunity.stage == stage)
    return list(
        db.scalars(
            query.order_by(CommercialOpportunity.updated_at.desc())
        ).all()
    )


@router.patch("/opportunities/{opportunity_id}", response_model=CommercialOpportunityResponse)
def update_opportunity(
    opportunity_id: str,
    payload: CommercialOpportunityUpdateRequest,
    principal: Principal = Depends(require_permission("commercial.manage")),
    db: Session = Depends(get_db),
) -> CommercialOpportunity:
    item = db.get(CommercialOpportunity, opportunity_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Oportunidade não encontrada.")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return item


@router.post("/proposals", response_model=CommercialProposalResponse, status_code=201)
def create_proposal(
    payload: CommercialProposalCreateRequest,
    principal: Principal = Depends(require_permission("commercial.manage")),
    db: Session = Depends(get_db),
) -> CommercialProposal:
    customer = db.get(CommercialCustomer, payload.customer_id)
    if customer is None or customer.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Cliente não encontrado.")

    subtotal, total = proposal_totals(payload.items, payload.discount)
    item = CommercialProposal(
        id=new_id("proposal"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        subtotal=subtotal,
        total=total,
        status="draft",
        created_by=principal.user.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/proposals", response_model=list[CommercialProposalResponse])
def list_proposals(
    customer_id: str | None = None,
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("commercial.read")),
    db: Session = Depends(get_db),
) -> list[CommercialProposal]:
    query = select(CommercialProposal).where(
        CommercialProposal.company_id == principal.company.id
    )
    if customer_id:
        query = query.where(CommercialProposal.customer_id == customer_id)
    if status_filter:
        query = query.where(CommercialProposal.status == status_filter)
    return list(
        db.scalars(
            query.order_by(CommercialProposal.created_at.desc())
        ).all()
    )


@router.patch("/proposals/{proposal_id}/status", response_model=CommercialProposalResponse)
def update_proposal_status(
    proposal_id: str,
    status: str,
    principal: Principal = Depends(require_permission("commercial.manage")),
    db: Session = Depends(get_db),
) -> CommercialProposal:
    allowed = {"draft", "sent", "accepted", "rejected", "expired"}
    if status not in allowed:
        raise HTTPException(status_code=422, detail="Status inválido.")

    item = db.get(CommercialProposal, proposal_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Proposta não encontrada.")

    item.status = status
    if status == "accepted":
        item.accepted_at = datetime.now(timezone.utc)
    if status == "rejected":
        item.rejected_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(item)
    return item


@router.post("/contracts", response_model=CommercialContractResponse, status_code=201)
def create_contract(
    payload: CommercialContractCreateRequest,
    principal: Principal = Depends(require_permission("commercial.manage")),
    db: Session = Depends(get_db),
) -> CommercialContract:
    customer = db.get(CommercialCustomer, payload.customer_id)
    if customer is None or customer.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Cliente não encontrado.")

    item = CommercialContract(
        id=new_id("contract"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="draft",
        signature_metadata={},
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.patch("/contracts/{contract_id}/sign", response_model=CommercialContractResponse)
def sign_contract(
    contract_id: str,
    signer: str,
    principal: Principal = Depends(require_permission("commercial.manage")),
    db: Session = Depends(get_db),
) -> CommercialContract:
    item = db.get(CommercialContract, contract_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Contrato não encontrado.")

    now = datetime.now(timezone.utc)
    if signer == "customer":
        item.signed_by_customer_at = now
    elif signer == "company":
        item.signed_by_company_at = now
    else:
        raise HTTPException(status_code=422, detail="Assinante inválido.")

    if item.signed_by_customer_at and item.signed_by_company_at:
        item.status = "active"
    else:
        item.status = "awaiting_signature"

    item.signature_metadata = {
        **item.signature_metadata,
        signer: {
            "user_id": principal.user.id,
            "signed_at": now.isoformat(),
        },
    }
    db.commit()
    db.refresh(item)
    return item


@router.post("/plans", response_model=CommercialPlanResponse, status_code=201)
def create_plan(
    payload: CommercialPlanCreateRequest,
    principal: Principal = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
) -> CommercialPlan:
    item = CommercialPlan(
        id=new_id("plan"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Código de plano duplicado.") from exc
    db.refresh(item)
    return item


@router.get("/plans", response_model=list[CommercialPlanResponse])
def list_plans(
    principal: Principal = Depends(require_permission("commercial.read")),
    db: Session = Depends(get_db),
) -> list[CommercialPlan]:
    return list(
        db.scalars(
            select(CommercialPlan)
            .where(
                CommercialPlan.company_id == principal.company.id,
                CommercialPlan.active.is_(True),
            )
            .order_by(CommercialPlan.price)
        ).all()
    )


@router.post("/subscriptions", response_model=CommercialSubscriptionResponse, status_code=201)
def create_subscription(
    payload: CommercialSubscriptionCreateRequest,
    principal: Principal = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
) -> CommercialSubscription:
    customer = db.get(CommercialCustomer, payload.customer_id)
    plan = db.get(CommercialPlan, payload.plan_id)
    if customer is None or customer.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Cliente não encontrado.")
    if plan is None or plan.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Plano não encontrado.")

    item = CommercialSubscription(
        id=new_id("subscription"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="trial" if payload.trial_ends_at else "active",
        **payload.model_dump(),
    )
    db.add(item)
    db.flush()
    create_invoice_for_subscription(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        subscription=item,
        plan=plan,
    )
    db.commit()
    db.refresh(item)
    return item


@router.get("/subscriptions", response_model=list[CommercialSubscriptionResponse])
def list_subscriptions(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("billing.read")),
    db: Session = Depends(get_db),
) -> list[CommercialSubscription]:
    query = select(CommercialSubscription).where(
        CommercialSubscription.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(CommercialSubscription.status == status_filter)
    return list(
        db.scalars(
            query.order_by(CommercialSubscription.created_at.desc())
        ).all()
    )


@router.post("/invoices", response_model=CommercialInvoiceResponse, status_code=201)
def create_invoice(
    payload: CommercialInvoiceCreateRequest,
    principal: Principal = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
) -> CommercialInvoice:
    item = CommercialInvoice(
        id=new_id("invoice"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="open",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/invoices", response_model=list[CommercialInvoiceResponse])
def list_invoices(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("billing.read")),
    db: Session = Depends(get_db),
) -> list[CommercialInvoice]:
    query = select(CommercialInvoice).where(
        CommercialInvoice.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(CommercialInvoice.status == status_filter)
    return list(
        db.scalars(
            query.order_by(CommercialInvoice.due_at.desc())
        ).all()
    )


@router.patch("/invoices/{invoice_id}/pay", response_model=CommercialInvoiceResponse)
def pay_invoice(
    invoice_id: str,
    payment_method: str,
    principal: Principal = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
) -> CommercialInvoice:
    item = db.get(CommercialInvoice, invoice_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Fatura não encontrada.")
    item.status = "paid"
    item.payment_method = payment_method
    item.paid_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


@router.post("/notifications/due")
async def generate_due_notifications(
    principal: Principal = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
) -> dict:
    items = create_due_notifications(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
    )
    db.commit()

    for item in items:
        await realtime_hub.publish(
            f"company:{principal.company.id}",
            {
                "type": "notification",
                "notification": {
                    "id": item.id,
                    "category": item.category,
                    "severity": item.severity,
                    "title": item.title,
                    "message": item.message,
                    "payload": item.payload,
                    "created_at": item.created_at.isoformat(),
                },
            },
        )
    return {"generated": len(items)}


@router.get("/dashboard")
def commercial_dashboard(
    principal: Principal = Depends(require_permission("commercial.read")),
    db: Session = Depends(get_db),
) -> dict:
    company_id = principal.company.id

    leads = db.scalar(
        select(func.count())
        .select_from(CommercialCustomer)
        .where(
            CommercialCustomer.company_id == company_id,
            CommercialCustomer.status == "lead",
        )
    ) or 0

    opportunities = list(
        db.scalars(
            select(CommercialOpportunity).where(
                CommercialOpportunity.company_id == company_id,
                CommercialOpportunity.stage.notin_(["won", "lost"]),
            )
        ).all()
    )

    open_invoices = list(
        db.scalars(
            select(CommercialInvoice).where(
                CommercialInvoice.company_id == company_id,
                CommercialInvoice.status == "open",
            )
        ).all()
    )

    active_subscriptions = db.scalar(
        select(func.count())
        .select_from(CommercialSubscription)
        .where(
            CommercialSubscription.company_id == company_id,
            CommercialSubscription.status.in_(["trial", "active"]),
        )
    ) or 0

    return {
        "leads": int(leads),
        "open_opportunities": len(opportunities),
        "pipeline_value": round(
            sum(item.estimated_value for item in opportunities),
            2,
        ),
        "weighted_pipeline": round(
            sum(
                item.estimated_value * item.probability_percent / 100
                for item in opportunities
            ),
            2,
        ),
        "open_invoices": len(open_invoices),
        "accounts_receivable": round(
            sum(item.amount for item in open_invoices),
            2,
        ),
        "active_subscriptions": int(active_subscriptions),
    }
