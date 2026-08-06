from app.database import Base
import app.ai_governance_models  # noqa
required={'ai_context_snapshots','ai_recommendation_records','ai_supervised_automations','ai_model_governance'}
missing=required-set(Base.metadata.tables)
if missing: raise SystemExit(f'Tabelas ausentes: {sorted(missing)}')
print('IA operacional e governança: estrutura pronta.')
