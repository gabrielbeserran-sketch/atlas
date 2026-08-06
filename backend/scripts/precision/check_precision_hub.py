from app.main import app
from app.database import Base
required={'precision_device_adapters','animal_rfid_bindings','precision_events','precision_geofences','vision_human_reviews','remote_sensing_scenes'}
missing=required-set(Base.metadata.tables)
paths={r.path for r in app.routes}
assert not missing, f'Tabelas ausentes: {sorted(missing)}'
assert '/api/v1/precision-hub/farms/{farm_id}/dashboard' in paths
print('Precision Hub aprovado:',len(required),'tabelas e endpoints registrados.')
