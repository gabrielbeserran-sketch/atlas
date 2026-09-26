from datetime import datetime, timedelta, timezone
from typing import Literal

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, field_validator
from pydantic_core import PydanticCustomError


class GrazingBasisCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    client_operation_id: str = Field(min_length=8, max_length=180)
    effective_area_ha: float = Field(gt=0, allow_inf_nan=False)
    grazing_animals: int = Field(gt=0, strict=True)
    unique_area_confirmed: Literal[True]
    recorded_at: AwareDatetime

    @field_validator("client_operation_id")
    @classmethod
    def clean_operation_id(cls, value: str) -> str:
        value = value.strip()
        if len(value) < 8:
            raise PydanticCustomError("operation_id", "Identificador da operação inválido.")
        return value

    @field_validator("recorded_at")
    @classmethod
    def valid_date(cls, value: datetime) -> datetime:
        value = value.astimezone(timezone.utc)
        if value > datetime.now(timezone.utc) + timedelta(minutes=1):
            raise PydanticCustomError("future_date", "Data da confirmação no futuro.")
        return value


class GrazingBasisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    tenant_id: str
    company_id: str
    farm_id: str
    client_operation_id: str
    effective_area_ha: float
    grazing_animals: int
    unique_area_confirmed: bool
    recorded_at: datetime
    created_at: datetime
    created_by: str

    @field_validator("recorded_at", "created_at")
    @classmethod
    def utc_dates(cls, value: datetime) -> datetime:
        # SQLite devolve datas sem timezone; os valores são gravados em UTC.
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)
