from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.database import Base
from app.models import Company, Farm, HerdLot, LivestockAnimal, WeightRecord, new_id
from app.services.core_livestock_validation import ValidationContext, validate_all


def _session() -> Session:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    return Session(engine)


def test_core_validation_reports_consistent_farm() -> None:
    db = _session()
    company = Company(id=new_id("company"), tenant_id=new_id("tenant"), name="Atlas", document="", status="active", subscription_plan="enterprise")
    farm = Farm(id=new_id("farm"), tenant_id=company.tenant_id, company_id=company.id, name="Fazenda Teste", city="Brasília", state="DF", area=100, active=True)
    lot = HerdLot(id=new_id("lot"), tenant_id=company.tenant_id, company_id=company.id, farm_id=farm.id, name="Lote 1", status="active", capacity=50)
    animal = LivestockAnimal(id=new_id("animal"), tenant_id=company.tenant_id, company_id=company.id, farm_id=farm.id, lot_id=lot.id, tag="001", status="active", current_weight=350)
    weight = WeightRecord(id=new_id("weight"), tenant_id=company.tenant_id, company_id=company.id, farm_id=farm.id, animal_id=animal.id, weight=350, measured_at=datetime.now(timezone.utc), created_by="test")
    db.add_all([company, farm, lot, animal, weight])
    db.commit()
    result = validate_all(db, ValidationContext(company_id=company.id, farm_id=farm.id))
    assert result["status"] == "ready"
    assert result["issue_count"] == 0
    assert result["domains"]["animals"]["total_active"] == 1


def test_core_validation_detects_weight_mismatch() -> None:
    db = _session()
    company = Company(id=new_id("company"), tenant_id=new_id("tenant"), name="Atlas", document="", status="active", subscription_plan="enterprise")
    farm = Farm(id=new_id("farm"), tenant_id=company.tenant_id, company_id=company.id, name="Fazenda Teste", active=True)
    animal = LivestockAnimal(id=new_id("animal"), tenant_id=company.tenant_id, company_id=company.id, farm_id=farm.id, tag="002", status="active", current_weight=300)
    weight = WeightRecord(id=new_id("weight"), tenant_id=company.tenant_id, company_id=company.id, farm_id=farm.id, animal_id=animal.id, weight=350, measured_at=datetime.now(timezone.utc), created_by="test")
    db.add_all([company, farm, animal, weight])
    db.commit()
    result = validate_all(db, ValidationContext(company_id=company.id, farm_id=farm.id))
    assert result["status"] == "attention"
    assert any(item.startswith("current_weight_mismatch") for item in result["domains"]["weights"]["issues"])
