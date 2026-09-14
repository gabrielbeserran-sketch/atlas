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


def test_stable_context_returns_an_analysis_confirmation():
    context={
        'payload':{
            'herd':{'active_animals':10,'females':6},
            'reproduction':{'pregnant':4},
            'health':{'events':1},
            'nutrition':{'events':1},
            'finance':{'entries':1},
        },
        'quality':{'weight_coverage_percent':100},
    }

    rows=generate_recommendations(context)

    assert len(rows) == 1
    assert rows[0]['priority'] == 'low'
    assert rows[0]['title'] == 'Manter acompanhamento da operação'
