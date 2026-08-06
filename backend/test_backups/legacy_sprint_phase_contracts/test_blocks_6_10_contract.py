from app.business_models import AtlasBusinessParty, AtlasCommercialDocument, AtlasConsultingVisit, AtlasActionPlanItem, AtlasWorkflowDefinition, AtlasSubscription, AtlasAnalyticsSnapshot

def test_blocks_6_10_tables():
    assert AtlasBusinessParty.__tablename__ == "atlas_business_parties"
    assert AtlasCommercialDocument.__tablename__ == "atlas_commercial_documents"
    assert AtlasConsultingVisit.__tablename__ == "atlas_consulting_visits"
    assert AtlasActionPlanItem.__tablename__ == "atlas_action_plan_items"
    assert AtlasWorkflowDefinition.__tablename__ == "atlas_workflow_definitions"
    assert AtlasSubscription.__tablename__ == "atlas_subscriptions"
    assert AtlasAnalyticsSnapshot.__tablename__ == "atlas_analytics_snapshots"

def test_business_router_registered():
    from app.main import app
    paths = app.openapi()["paths"]
    assert "/api/v1/business/dashboard" in paths
    assert "/api/v1/business/bi/dashboard" in paths
    assert "/api/v1/business/product/readiness" in paths
