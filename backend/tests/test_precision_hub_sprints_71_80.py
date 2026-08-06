from app.precision_hub_models import AnimalRfidBinding, DeviceAdapter, PrecisionEvent, PrecisionGeoFence, RemoteSensingScene, VisionHumanReview
from app.services.precision_hub_service import point_in_polygon, thi

def test_tables():
    assert AnimalRfidBinding.__tablename__=='animal_rfid_bindings'
    assert DeviceAdapter.__tablename__=='precision_device_adapters'
    assert PrecisionEvent.__tablename__=='precision_events'
    assert PrecisionGeoFence.__tablename__=='precision_geofences'
    assert VisionHumanReview.__tablename__=='vision_human_reviews'
    assert RemoteSensingScene.__tablename__=='remote_sensing_scenes'
def test_thi_and_polygon():
    assert thi(35,70)>79
    square=[[-48,-16],[-47,-16],[-47,-15],[-48,-15]]
    assert point_in_polygon(-15.5,-47.5,square)
    assert not point_in_polygon(-14,-47.5,square)
def test_router_registered():
    from app.main import app
    paths={r.path for r in app.routes}
    assert '/api/v1/precision-hub/farms/{farm_id}/dashboard' in paths
    assert '/api/v1/precision-hub/devices/{device_id}/telemetry' in paths
