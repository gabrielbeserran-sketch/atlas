import os

os.environ["ATLAS_DATABASE_URL"] = "sqlite:///./atlas_test.db"
os.environ["ATLAS_JWT_SECRET"] = "test-secret"
os.environ["ATLAS_BOOTSTRAP_ADMIN_EMAIL"] = "admin@test.local"
os.environ["ATLAS_BOOTSTRAP_ADMIN_PASSWORD"] = "Test@123456"
os.environ["ATLAS_BACKUP_DIR"] = "./test_backups"

import pytest
from fastapi.testclient import TestClient

from app.config import get_settings

get_settings.cache_clear()

from app.database import Base, engine
from app.main import app


@pytest.fixture()
def client():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as test_client:
        yield test_client
    Base.metadata.drop_all(bind=engine)
