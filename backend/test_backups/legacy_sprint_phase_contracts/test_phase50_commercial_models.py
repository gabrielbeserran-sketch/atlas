
from app.models import (
    CommercialContract,
    CommercialCustomer,
    CommercialInvoice,
    CommercialOpportunity,
    CommercialPlan,
    CommercialProposal,
    CommercialSubscription,
)


def test_phase50_tables():
    assert CommercialCustomer.__tablename__ == "commercial_customers"
    assert CommercialOpportunity.__tablename__ == "commercial_opportunities"
    assert CommercialProposal.__tablename__ == "commercial_proposals"
    assert CommercialContract.__tablename__ == "commercial_contracts"
    assert CommercialPlan.__tablename__ == "commercial_plans"
    assert CommercialSubscription.__tablename__ == "commercial_subscriptions"
    assert CommercialInvoice.__tablename__ == "commercial_invoices"
