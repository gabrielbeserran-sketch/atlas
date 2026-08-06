from app.ai_governance_models import AiContextSnapshot, AiModelGovernance, AiRecommendationRecord, AiSupervisedAutomation
from app.services.ai_operational_service import generate_recommendations

def test_tables_have_expected_names():
    assert AiContextSnapshot.__tablename__=='ai_context_snapshots'
    assert AiRecommendationRecord.__tablename__=='ai_recommendation_records'
    assert AiSupervisedAutomation.__tablename__=='ai_supervised_automations'
    assert AiModelGovernance.__tablename__=='ai_model_governance'

def test_recommendations_are_explainable():
    context={'payload':{'herd':{'active_animals':10,'females':6},'reproduction':{'pregnant':1},'health':{'events':0},'nutrition':{'events':0},'finance':{'entries':0}},'quality':{'weight_coverage_percent':20}}
    rows=generate_recommendations(context)
    assert rows
    assert all(r.get('evidence') is not None and r.get('recommended_action') for r in rows)
