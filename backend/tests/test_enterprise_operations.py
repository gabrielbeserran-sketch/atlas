from app.enterprise_operations_models import ConsultantVisit,FarmTeam,AssetUsage,PurchaseRequest,SalesOpportunity,CrmLead,SupportTicket,WorkflowDefinition,WorkflowInstance,EnterpriseDocument
from app.routers.enterprise_operations import router

def test_tables_and_routes():
    assert {ConsultantVisit.__tablename__,FarmTeam.__tablename__,AssetUsage.__tablename__,PurchaseRequest.__tablename__,SalesOpportunity.__tablename__,CrmLead.__tablename__,SupportTicket.__tablename__,WorkflowDefinition.__tablename__,WorkflowInstance.__tablename__,EnterpriseDocument.__tablename__} == {'consultant_visits','farm_teams','asset_usage_records','purchase_requests','sales_opportunities','crm_leads','support_tickets_v2','enterprise_workflow_definitions','enterprise_workflow_instances','enterprise_documents'}
    paths={r.path for r in router.routes}
    assert '/enterprise-operations/dashboard' in paths
    assert '/enterprise-operations/documents' in paths
    assert '/enterprise-operations/workflows/definitions' in paths
