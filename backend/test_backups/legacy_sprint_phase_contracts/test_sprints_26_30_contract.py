from pathlib import Path
from app import enterprise_growth_models

def test_domain_model_architecture():
 assert enterprise_growth_models.AnnualBudget.__tablename__=="annual_budgets"
 assert enterprise_growth_models.InventoryCount.__tablename__=="inventory_counts"
 assert enterprise_growth_models.EcosystemPartner.__tablename__=="ecosystem_partners"
 assert enterprise_growth_models.StrategicPlan.__tablename__=="strategic_plans_v2"
 assert enterprise_growth_models.LocalizationProfile.__tablename__=="localization_profiles"

def test_generic_model_files_removed():
 root=Path(__file__).parents[1]/"app"
 assert not (root/"sprint_models.py").exists()
 assert not (root/"sprints_16_20_models.py").exists()
 assert not (root/"sprints_21_25_models.py").exists()

def test_routers_are_domain_named():
 root=Path(__file__).parents[1]/"app"/"routers"
 for name in ["finance_enterprise.py","inventory_enterprise.py","ecosystem.py","corporate_intelligence.py","global_platform.py"]:
  assert (root/name).exists()
