from app import innovation_models
from app.routers import sprints_11_15
def test_tables():
 assert innovation_models.AtlasBrainMemory.__tablename__=='atlas_brain_memories'
 assert innovation_models.AtlasVisionAnalysis.__tablename__=='atlas_vision_analyses'
 assert innovation_models.AtlasIotDevice.__tablename__=='atlas_iot_devices_v2'
 assert innovation_models.AtlasCloudJob.__tablename__=='atlas_cloud_jobs'
 assert innovation_models.AtlasWebWorkspace.__tablename__=='atlas_web_workspaces'
def test_router_paths():
 paths={r.path for r in sprints_11_15.router.routes}
 assert '/sprints/brain/farms/{farm_id}/context' in paths
 assert '/sprints/vision/farms/{farm_id}/analyze' in paths
 assert '/sprints/iot/farms/{farm_id}/dashboard' in paths
 assert '/sprints/cloud/readiness' in paths
 assert '/sprints/web/dashboard' in paths
