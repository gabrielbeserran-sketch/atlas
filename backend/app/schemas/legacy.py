from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    email: str
    password: str
    company_id: str | None = None


class CompanySummary(BaseModel):
    id: str
    tenant_id: str
    name: str
    document: str
    status: str
    subscription_plan: str
    role: str


class CompanyCreateRequest(BaseModel):
    name: str
    document: str = ""
    subscription_plan: str = "enterprise"


class CompanyUpdateRequest(BaseModel):
    name: str | None = None
    document: str | None = None
    subscription_plan: str | None = None


class CompanyDetailsResponse(BaseModel):
    id: str
    tenant_id: str
    name: str
    document: str
    status: str
    subscription_plan: str
    created_at: datetime
    role: str
    farm_count: int
    member_count: int
    active: bool


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    expires_in_seconds: int = 3600
    mfa_required: bool = False
    challenge_token: str | None = None
    token_type: str = "bearer"
    user_id: str
    user_name: str
    email: str
    company_id: str
    tenant_id: str
    role: str
    companies: list[CompanySummary]
    effective_permissions: list[str] = Field(default_factory=list)
    farm_ids: list[str] = Field(default_factory=list)


class SwitchCompanyRequest(BaseModel):
    company_id: str


class FarmCreateRequest(BaseModel):
    name: str
    city: str = ""
    state: str = ""
    animals: int = Field(default=0, ge=0)
    area: int = Field(default=0, ge=0)


class FarmUpdateRequest(BaseModel):
    name: str | None = None
    city: str | None = None
    state: str | None = None
    animals: int | None = Field(default=None, ge=0)
    area: int | None = Field(default=None, ge=0)
    active: bool | None = None


class FarmResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    tenant_id: str
    company_id: str
    name: str
    city: str
    state: str
    animals: int
    area: int
    active: bool


class SyncPushRequest(BaseModel):
    operation_id: str
    idempotency_key: str
    tenant_id: str
    company_id: str
    farm_id: str | None = None
    entity_type: str
    entity_id: str
    operation_type: str
    payload: dict[str, Any] = Field(default_factory=dict)
    base_version: int
    device_id: str = "unknown"


class SyncPushResponse(BaseModel):
    accepted: bool
    conflict: bool
    remote_version: int
    remote_payload: dict[str, Any] = Field(default_factory=dict)
    error: str = ""


class SyncChangeResponse(BaseModel):
    entity_type: str
    entity_id: str
    version: int
    payload: dict[str, Any]
    deleted: bool
    cursor: str


class AuditResponse(BaseModel):
    id: str
    company_id: str
    farm_id: str | None
    user_id: str
    action: str
    module: str
    entity_type: str
    entity_id: str
    description: str
    before: dict[str, Any]
    after: dict[str, Any]
    result: str
    justification: str
    occurred_at: datetime


class BackupResponse(BaseModel):
    filename: str
    created_at: datetime
    size_bytes: int
    engine: str


class MemberCreateRequest(BaseModel):
    name: str
    email: str
    password: str | None = None
    role: str = "viewer"
    farm_ids: list[str] = Field(default_factory=list)
    permission_overrides: dict[str, str] = Field(default_factory=dict)


class MemberUpdateRequest(BaseModel):
    role: str | None = None
    active: bool | None = None
    farm_ids: list[str] | None = None
    permission_overrides: dict[str, str] | None = None


class MemberPasswordResetRequest(BaseModel):
    password: str


class MemberResponse(BaseModel):
    membership_id: str
    user_id: str
    name: str
    email: str
    role: str
    active: bool
    farm_ids: list[str]
    permission_overrides: dict[str, str]
    effective_permissions: list[str]
    started_at: datetime
    is_self: bool


class PermissionCatalogResponse(BaseModel):
    roles: list[str]
    permissions: list[str]


class AnimalCreateRequest(BaseModel):
    farm_id: str
    group_name: str = ""
    tag: str
    name: str = ""
    sisbov: str = ""
    category: str = "Não informada"
    sex: str = "Fêmea"
    breed: str = "Não informada"
    birth_date: str = ""
    weight: float = 0
    body_condition_score: float = 0
    status: str = "Ativo"
    mother_tag: str = ""
    father_tag: str = ""
    origin: str = ""
    photo_reference: str = ""
    notes: str = ""
    acquisition_type: str = "Nascido na fazenda"
    acquisition_date: str = ""
    acquisition_value: float = 0
    acquisition_counterparty: str = ""
    acquisition_document: str = ""
    sale_date: str = ""
    sale_value: float = 0
    sale_counterparty: str = ""
    sale_document: str = ""


class AnimalUpdateRequest(BaseModel):
    group_name: str | None = None
    tag: str | None = None
    name: str | None = None
    sisbov: str | None = None
    category: str | None = None
    sex: str | None = None
    breed: str | None = None
    birth_date: str | None = None
    weight: float | None = None
    body_condition_score: float | None = None
    status: str | None = None
    mother_tag: str | None = None
    father_tag: str | None = None
    origin: str | None = None
    photo_reference: str | None = None
    notes: str | None = None
    acquisition_type: str | None = None
    acquisition_date: str | None = None
    acquisition_value: float | None = None
    acquisition_counterparty: str | None = None
    acquisition_document: str | None = None
    sale_date: str | None = None
    sale_value: float | None = None
    sale_counterparty: str | None = None
    sale_document: str | None = None
    active: bool | None = None


class AnimalResponse(BaseModel):
    id: str
    tenant_id: str
    company_id: str
    farm_id: str
    group_name: str
    tag: str
    name: str
    sisbov: str
    category: str
    sex: str
    breed: str
    birth_date: str
    weight: float
    body_condition_score: float
    status: str
    mother_tag: str
    father_tag: str
    origin: str
    photo_reference: str
    notes: str
    acquisition_type: str
    acquisition_date: str
    acquisition_value: float
    acquisition_counterparty: str
    acquisition_document: str
    sale_date: str
    sale_value: float
    sale_counterparty: str
    sale_document: str
    active: bool
    version: int
    updated_at: datetime


class AnimalHistoryResponse(BaseModel):
    version: int
    payload: dict[str, Any]
    deleted: bool
    changed_at: datetime


class AnimalTimelineResponse(BaseModel):
    id: str
    action: str
    category: str
    title: str
    description: str
    before: dict[str, Any]
    after: dict[str, Any]
    user_id: str
    occurred_at: datetime


class AnimalGenealogyNodeResponse(BaseModel):
    id: str
    farm_id: str
    group_name: str
    tag: str
    name: str
    sex: str
    breed: str
    category: str
    birth_date: str
    status: str
    relation: str
    registered: bool


class AnimalGenealogyResponse(BaseModel):
    animal: AnimalGenealogyNodeResponse
    father: AnimalGenealogyNodeResponse | None = None
    mother: AnimalGenealogyNodeResponse | None = None
    paternal_grandfather: AnimalGenealogyNodeResponse | None = None
    paternal_grandmother: AnimalGenealogyNodeResponse | None = None
    maternal_grandfather: AnimalGenealogyNodeResponse | None = None
    maternal_grandmother: AnimalGenealogyNodeResponse | None = None
    siblings: list[AnimalGenealogyNodeResponse]
    half_siblings: list[AnimalGenealogyNodeResponse]
    children: list[AnimalGenealogyNodeResponse]
    descendants: list[AnimalGenealogyNodeResponse]
    unresolved_tags: list[str]

class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=180)
    email: str = Field(min_length=5, max_length=180)
    password: str = Field(min_length=10, max_length=128)
    company_name: str = Field(min_length=2, max_length=180)
    company_document: str = Field(default="", max_length=40)
    accept_terms: bool


class RegistrationResponse(BaseModel):
    user_id: str
    company_id: str
    email: str
    email_verification_required: bool = True
    verification_token: str | None = None


class ConfirmEmailRequest(BaseModel):
    token: str = Field(min_length=20)


class MessageResponse(BaseModel):
    message: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=20)
    device_name: str = ""


class LogoutRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class SessionResponse(BaseModel):
    id: str
    device_name: str
    ip_address: str
    user_agent: str
    expires_at: datetime
    last_used_at: datetime | None
    created_at: datetime
    current: bool = False


class PasswordResetRequest(BaseModel):
    email: str


class PasswordResetConfirmRequest(BaseModel):
    token: str = Field(min_length=20)
    new_password: str = Field(min_length=10, max_length=128)


class MfaSetupResponse(BaseModel):
    secret: str
    provisioning_uri: str
    recovery_codes: list[str]


class MfaVerifyRequest(BaseModel):
    code: str = Field(min_length=6, max_length=20)


class MfaChallengeRequest(BaseModel):
    challenge_token: str
    code: str = Field(min_length=6, max_length=20)


class SecurityEventResponse(BaseModel):
    id: str
    user_id: str | None
    company_id: str | None
    event_type: str
    success: bool
    ip_address: str
    user_agent: str
    details: dict[str, Any]
    occurred_at: datetime


class HerdLotCreateRequest(BaseModel):
    farm_id: str
    name: str = Field(min_length=1, max_length=180)
    category: str = ""
    capacity: int = Field(default=0, ge=0)
    paddock: str = ""
    notes: str = ""


class HerdLotUpdateRequest(BaseModel):
    name: str | None = None
    category: str | None = None
    status: str | None = None
    capacity: int | None = Field(default=None, ge=0)
    paddock: str | None = None
    notes: str | None = None


class HerdLotResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    tenant_id: str
    company_id: str
    farm_id: str
    name: str
    category: str
    status: str
    capacity: int
    paddock: str
    notes: str
    created_at: datetime
    updated_at: datetime


class LivestockAnimalCreateRequest(BaseModel):
    farm_id: str
    lot_id: str | None = None
    tag: str = Field(min_length=1, max_length=120)
    sisbov: str = ""
    name: str = ""
    sex: str = ""
    breed: str = ""
    category: str = ""
    birth_date: str = ""
    status: str = "active"
    current_weight: float = Field(default=0, ge=0)
    body_condition_score: float = Field(default=0, ge=0, le=5)
    mother_id: str | None = None
    father_id: str | None = None
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class LivestockAnimalUpdateRequest(BaseModel):
    lot_id: str | None = None
    tag: str | None = None
    sisbov: str | None = None
    name: str | None = None
    sex: str | None = None
    breed: str | None = None
    category: str | None = None
    birth_date: str | None = None
    status: str | None = None
    current_weight: float | None = Field(default=None, ge=0)
    body_condition_score: float | None = Field(default=None, ge=0, le=5)
    mother_id: str | None = None
    father_id: str | None = None
    metadata_json: dict[str, Any] | None = None


class LivestockAnimalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    tenant_id: str
    company_id: str
    farm_id: str
    lot_id: str | None
    tag: str
    sisbov: str
    name: str
    sex: str
    breed: str
    category: str
    birth_date: str
    status: str
    current_weight: float
    body_condition_score: float
    mother_id: str | None
    father_id: str | None
    metadata_json: dict[str, Any]
    created_at: datetime
    updated_at: datetime


class AnimalMovementRequest(BaseModel):
    movement_type: str
    to_lot_id: str | None = None
    occurred_at: datetime | None = None
    reason: str = ""
    document_reference: str = ""


class AnimalMovementResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    animal_id: str
    movement_type: str
    from_lot_id: str | None
    to_lot_id: str | None
    occurred_at: datetime
    reason: str
    document_reference: str
    created_by: str


class WeightCreateRequest(BaseModel):
    weight: float = Field(gt=0)
    body_condition_score: float = Field(default=0, ge=0, le=5)
    source: str = ""
    equipment: str = ""
    measured_at: datetime | None = None
    notes: str = ""


class WeightResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    animal_id: str
    weight: float
    body_condition_score: float
    source: str
    equipment: str
    measured_at: datetime
    notes: str


class ReproductionEventCreateRequest(BaseModel):
    event_type: str
    event_code: str = "observation"
    protocol_name: str = ""
    protocol_stage: str = ""
    sire_reference: str = ""
    result: str = ""
    reproductive_status: str = ""
    responsible: str = ""
    attempt_number: int = Field(default=0, ge=0)
    pregnancy_days: int = Field(default=0, ge=0, le=310)
    calf_id: str = ""
    calf_sex: str = ""
    birth_type: str = ""
    occurred_at: datetime | None = None
    expected_date: datetime | None = None
    notes: str = ""
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class ReproductionEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    animal_id: str
    event_type: str
    event_code: str
    protocol_name: str
    protocol_stage: str
    sire_reference: str
    result: str
    reproductive_status: str
    responsible: str
    attempt_number: int
    pregnancy_days: int
    calf_id: str
    calf_sex: str
    birth_type: str
    occurred_at: datetime
    expected_date: datetime | None
    notes: str
    metadata_json: dict[str, Any]


class ReproductionSummaryResponse(BaseModel):
    farm_id: str
    total_females: int
    serviced_animals: int
    diagnosed_animals: int
    pregnant_animals: int
    calvings: int
    abortions: int
    services: int
    service_rate: float
    conception_rate: float
    pregnancy_rate: float
    services_per_conception: float
    upcoming_actions: list[dict[str, Any]] = Field(default_factory=list)


class HealthEventCreateRequest(BaseModel):
    farm_id: str
    animal_id: str | None = None
    lot_id: str | None = None
    event_type: str
    product_name: str = ""
    dosage: str = ""
    route: str = ""
    withdrawal_until: datetime | None = None
    withdrawal_meat_until: datetime | None = None
    withdrawal_milk_until: datetime | None = None
    occurred_at: datetime | None = None
    responsible: str = ""
    notes: str = ""
    protocol_name: str = ""
    product_batch: str = ""
    frequency: str = ""
    diagnosis: str = ""
    severity: str = "not_informed"
    next_date: datetime | None = None
    status: str = "completed"
    is_quarantine: bool = False
    is_mortality: bool = False
    necropsy_result: str = ""
    inventory_product_id: str | None = None
    inventory_quantity: float = Field(default=0, ge=0)
    treatment_cost: float = Field(default=0, ge=0)


class HealthEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    animal_id: str | None
    lot_id: str | None
    event_type: str
    product_name: str
    dosage: str
    route: str
    withdrawal_until: datetime | None
    withdrawal_meat_until: datetime | None
    withdrawal_milk_until: datetime | None
    occurred_at: datetime
    responsible: str
    notes: str
    protocol_name: str
    product_batch: str
    frequency: str
    diagnosis: str
    severity: str
    next_date: datetime | None
    status: str
    is_quarantine: bool
    is_mortality: bool
    necropsy_result: str
    inventory_product_id: str | None
    inventory_quantity: float
    treatment_cost: float


class HealthProtocolCreateRequest(BaseModel):
    farm_id: str
    name: str = Field(min_length=1)
    event_type: str = "Protocolo sanitário"
    product_name: str = ""
    dosage: str = ""
    route: str = ""
    recurrence_days: int = Field(default=0, ge=0)
    withdrawal_meat_days: int = Field(default=0, ge=0)
    withdrawal_milk_days: int = Field(default=0, ge=0)
    notes: str = ""


class HealthProtocolResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    name: str
    event_type: str
    product_name: str
    dosage: str
    route: str
    recurrence_days: int
    withdrawal_meat_days: int
    withdrawal_milk_days: int
    active: bool
    notes: str


class HealthProtocolApplyRequest(BaseModel):
    animal_ids: list[str] = Field(default_factory=list)
    lot_id: str | None = None
    occurred_at: datetime | None = None
    responsible: str = ""


class InventoryProductCreateRequest(BaseModel):
    farm_id: str
    sku: str = Field(min_length=1)
    name: str = Field(min_length=1)
    category: str = ""
    unit: str = "un"
    quantity: float = Field(default=0, ge=0)
    minimum_quantity: float = Field(default=0, ge=0)
    average_cost: float = Field(default=0, ge=0)
    expiry_date: datetime | None = None


class InventoryProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    sku: str
    name: str
    category: str
    unit: str
    quantity: float
    minimum_quantity: float
    average_cost: float
    expiry_date: datetime | None
    active: bool


class InventoryMovementRequest(BaseModel):
    movement_type: str
    quantity: float = Field(gt=0)
    unit_cost: float = Field(default=0, ge=0)
    reference_type: str = ""
    reference_id: str = ""


class FinancialEntryCreateRequest(BaseModel):
    farm_id: str
    entry_type: str
    category: str = ""
    description: str
    amount: float = Field(gt=0)
    due_date: datetime | None = None
    paid_at: datetime | None = None
    reference_type: str = ""
    reference_id: str = ""


class FinancialEntryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    entry_type: str
    category: str
    description: str
    amount: float
    due_date: datetime | None
    paid_at: datetime | None
    reference_type: str
    reference_id: str
    created_at: datetime


class NutritionEventCreateRequest(BaseModel):
    farm_id: str
    lot_id: str
    diet_name: str
    product_id: str | None = None
    quantity_per_head: float = Field(default=0, ge=0)
    total_quantity: float = Field(default=0, ge=0)
    estimated_cost: float = Field(default=0, ge=0)
    occurred_at: datetime | None = None
    notes: str = ""


class NutritionEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    lot_id: str
    diet_name: str
    product_id: str | None
    quantity_per_head: float
    total_quantity: float
    estimated_cost: float
    occurred_at: datetime
    notes: str


class OperationalAlertResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    alert_type: str
    severity: str
    title: str
    description: str
    entity_type: str
    entity_id: str
    due_at: datetime | None
    status: str
    generated_by: str
    created_at: datetime
    resolved_at: datetime | None


class OperationalTaskCreateRequest(BaseModel):
    farm_id: str | None = None
    source_type: str = ""
    source_id: str = ""
    title: str = Field(min_length=1, max_length=220)
    description: str = ""
    responsible_user_id: str | None = None
    priority: str = "medium"
    due_at: datetime | None = None


class OperationalTaskUpdateRequest(BaseModel):
    title: str | None = None
    description: str | None = None
    responsible_user_id: str | None = None
    priority: str | None = None
    due_at: datetime | None = None
    status: str | None = None
    evidence: str | None = None


class OperationalTaskResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    source_type: str
    source_id: str
    title: str
    description: str
    responsible_user_id: str | None
    priority: str
    due_at: datetime | None
    status: str
    evidence: str
    created_at: datetime
    completed_at: datetime | None


class IndicatorSnapshotResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    indicator_key: str
    indicator_name: str
    value: float
    unit: str
    formula: str
    source_tables: list[str]
    period_start: datetime | None
    period_end: datetime | None
    filters: dict[str, Any]
    generated_at: datetime


class ConflictResolutionRequest(BaseModel):
    strategy: str = Field(pattern="^(keep_local|keep_remote|merge)$")
    merged_payload: dict[str, Any] | None = None
    justification: str = Field(min_length=3)


class TimelineItemResponse(BaseModel):
    event_id: str
    event_type: str
    module: str
    title: str
    occurred_at: datetime
    entity_type: str
    entity_id: str
    details: dict[str, Any]


class AnalyticsKpiCreateRequest(BaseModel):
    key: str = Field(min_length=2, max_length=120)
    name: str = Field(min_length=2, max_length=180)
    description: str = ""
    metric_group: str = Field(min_length=2, max_length=80)
    formula: str = Field(min_length=2)
    unit: str = ""
    target_direction: str = Field(default="higher", pattern="^(higher|lower|range)$")
    warning_threshold: float | None = None
    critical_threshold: float | None = None
    weight: float = Field(default=1, ge=0)


class AnalyticsKpiResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    key: str
    name: str
    description: str
    metric_group: str
    formula: str
    unit: str
    target_direction: str
    warning_threshold: float | None
    critical_threshold: float | None
    weight: float
    active: bool
    created_at: datetime
    updated_at: datetime


class AnalyticsGoalCreateRequest(BaseModel):
    farm_id: str | None = None
    kpi_key: str
    title: str
    baseline_value: float = 0
    target_value: float
    start_date: datetime
    due_date: datetime
    responsible_user_id: str | None = None
    notes: str = ""


class AnalyticsGoalUpdateRequest(BaseModel):
    current_value: float | None = None
    target_value: float | None = None
    due_date: datetime | None = None
    status: str | None = None
    responsible_user_id: str | None = None
    notes: str | None = None


class AnalyticsGoalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    kpi_key: str
    title: str
    baseline_value: float
    target_value: float
    current_value: float
    start_date: datetime
    due_date: datetime
    status: str
    responsible_user_id: str | None
    notes: str
    created_at: datetime
    updated_at: datetime


class AnalyticsFactResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    lot_id: str | None
    metric_key: str
    metric_name: str
    metric_group: str
    value: float
    unit: str
    period_start: datetime
    period_end: datetime
    dimensions: dict[str, Any]
    source_tables: list[str]
    formula: str
    generated_at: datetime


class AnalyticsBenchmarkResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    metric_key: str
    value: float
    percentile: float
    rank_position: int
    peer_count: int
    peer_group: str
    period_start: datetime
    period_end: datetime
    generated_at: datetime


class AnalyticsFarmScoreResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    score: float
    grade: str
    component_scores: dict[str, Any]
    explanations: list[str]
    period_start: datetime
    period_end: datetime
    generated_at: datetime


class AtlasAiConversationCreateRequest(BaseModel):
    farm_id: str | None = None
    title: str = Field(default="Nova conversa", max_length=220)
    specialist_area: str = Field(
        default="general",
        pattern="^(general|health|nutrition|reproduction|finance|climate|market|strategy|executive)$",
    )


class AtlasAiMessageRequest(BaseModel):
    content: str = Field(min_length=2)
    context: dict[str, Any] = Field(default_factory=dict)


class AtlasAiConversationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    user_id: str
    title: str
    specialist_area: str
    status: str
    context_snapshot: dict[str, Any]
    created_at: datetime
    updated_at: datetime


class AtlasAiMessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    conversation_id: str
    role: str
    content: str
    structured_payload: dict[str, Any]
    confidence: float
    sources: list[str]
    created_at: datetime


class AtlasAiOperationalRecommendationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    animal_id: str | None
    area: str
    recommendation_type: str
    title: str
    summary: str
    rationale: str
    action_items: list[str]
    evidence: list[dict[str, Any]]
    assumptions: list[str]
    confidence: float
    priority: str
    financial_impact: float
    status: str
    generated_by: str
    generated_at: datetime
    reviewed_by: str | None
    reviewed_at: datetime | None


class AtlasAiAnalyzeRequest(BaseModel):
    farm_id: str | None = None
    animal_id: str | None = None
    context: dict[str, Any] = Field(default_factory=dict)


class AtlasAiExecutiveResponse(BaseModel):
    generated_at: datetime
    farm_id: str | None
    executive_score: float
    status: str
    official_decision: str
    strategy: list[str]
    recommendations: list[AtlasAiOperationalRecommendationResponse]
    risks: list[str]
    opportunities: list[str]
    limitations: list[str]


class RealtimeNotificationCreateRequest(BaseModel):
    farm_id: str | None = None
    user_id: str | None = None
    channel: str = "in_app"
    category: str
    severity: str = Field(default="info", pattern="^(info|warning|high|critical)$")
    title: str = Field(min_length=1, max_length=220)
    message: str = Field(min_length=1)
    payload: dict[str, Any] = Field(default_factory=dict)
    deduplication_key: str = ""
    expires_at: datetime | None = None


class RealtimeNotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    user_id: str | None
    channel: str
    category: str
    severity: str
    title: str
    message: str
    payload: dict[str, Any]
    status: str
    read_at: datetime | None
    delivered_at: datetime | None
    expires_at: datetime | None
    created_at: datetime


class RealtimePublishRequest(BaseModel):
    farm_id: str | None = None
    topic: str = Field(min_length=1, max_length=120)
    event_type: str = Field(min_length=1, max_length=120)
    entity_type: str = ""
    entity_id: str = ""
    payload: dict[str, Any] = Field(default_factory=dict)
    correlation_id: str = ""
    source: str = "atlas"


class RealtimeSubscriptionRequest(BaseModel):
    topic: str = Field(min_length=1, max_length=120)
    farm_id: str | None = None
    enabled: bool = True
    minimum_severity: str = "info"
    channels: list[str] = Field(default_factory=lambda: ["in_app"])


class IotGatewayCreateRequest(BaseModel):
    farm_id: str
    external_id: str = Field(min_length=1, max_length=120)
    name: str = Field(min_length=1, max_length=180)
    protocol: str = "mqtt"
    firmware_version: str = ""
    ip_address: str = ""
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class IotGatewayResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    external_id: str
    name: str
    protocol: str
    status: str
    firmware_version: str
    ip_address: str
    last_seen_at: datetime | None
    metadata_json: dict[str, Any]
    created_at: datetime
    updated_at: datetime


class IotDeviceCreateRequest(BaseModel):
    farm_id: str
    gateway_id: str | None = None
    external_id: str = Field(min_length=1, max_length=120)
    name: str = Field(min_length=1, max_length=180)
    device_type: str = Field(min_length=1, max_length=80)
    model: str = ""
    manufacturer: str = ""
    animal_id: str | None = None
    lot_id: str | None = None
    configuration: dict[str, Any] = Field(default_factory=dict)
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class IotDeviceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    gateway_id: str | None
    external_id: str
    name: str
    device_type: str
    model: str
    manufacturer: str
    status: str
    battery_percent: float | None
    signal_strength: float | None
    animal_id: str | None
    lot_id: str | None
    installed_at: datetime | None
    last_seen_at: datetime | None
    configuration: dict[str, Any]
    metadata_json: dict[str, Any]
    created_at: datetime
    updated_at: datetime


class IotTelemetryIngestRequest(BaseModel):
    device_external_id: str
    metric_key: str
    value: float
    unit: str = ""
    quality: str = "good"
    recorded_at: datetime | None = None
    payload: dict[str, Any] = Field(default_factory=dict)
    battery_percent: float | None = None
    signal_strength: float | None = None


class IotTelemetryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    device_id: str
    metric_key: str
    value: float
    unit: str
    quality: str
    payload: dict[str, Any]
    recorded_at: datetime
    received_at: datetime


class IotCommandCreateRequest(BaseModel):
    command_type: str
    payload: dict[str, Any] = Field(default_factory=dict)


class IotCommandResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    device_id: str
    command_type: str
    payload: dict[str, Any]
    status: str
    requested_by: str
    requested_at: datetime
    acknowledged_at: datetime | None
    completed_at: datetime | None
    result_payload: dict[str, Any]
    error_message: str


class IotAutomationRuleCreateRequest(BaseModel):
    farm_id: str
    name: str
    metric_key: str
    operator: str = Field(pattern="^(gt|gte|lt|lte|eq)$")
    threshold: float
    severity: str = "warning"
    action_type: str = "notification"
    action_payload: dict[str, Any] = Field(default_factory=dict)
    enabled: bool = True


class IotAutomationRuleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str
    name: str
    metric_key: str
    operator: str
    threshold: float
    severity: str
    action_type: str
    action_payload: dict[str, Any]
    enabled: bool
    created_at: datetime
    updated_at: datetime


class CommercialCustomerCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=180)
    document: str = ""
    email: str = ""
    phone: str = ""
    customer_type: str = "producer"
    source: str = ""
    notes: str = ""
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class CommercialCustomerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    name: str
    document: str
    email: str
    phone: str
    customer_type: str
    status: str
    source: str
    notes: str
    metadata_json: dict[str, Any]
    created_at: datetime
    updated_at: datetime


class CommercialOpportunityCreateRequest(BaseModel):
    customer_id: str
    title: str
    estimated_value: float = 0
    probability_percent: float = Field(default=0, ge=0, le=100)
    expected_close_at: datetime | None = None
    responsible_user_id: str | None = None
    notes: str = ""


class CommercialOpportunityUpdateRequest(BaseModel):
    stage: str | None = None
    estimated_value: float | None = None
    probability_percent: float | None = Field(default=None, ge=0, le=100)
    expected_close_at: datetime | None = None
    responsible_user_id: str | None = None
    loss_reason: str | None = None
    notes: str | None = None


class CommercialOpportunityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    customer_id: str
    title: str
    stage: str
    estimated_value: float
    probability_percent: float
    expected_close_at: datetime | None
    responsible_user_id: str | None
    loss_reason: str
    notes: str
    created_at: datetime
    updated_at: datetime


class CommercialProposalCreateRequest(BaseModel):
    customer_id: str
    opportunity_id: str | None = None
    title: str
    description: str = ""
    items: list[dict[str, Any]] = Field(default_factory=list)
    discount: float = 0
    valid_until: datetime | None = None


class CommercialProposalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    customer_id: str
    opportunity_id: str | None
    title: str
    description: str
    items: list[dict[str, Any]]
    subtotal: float
    discount: float
    total: float
    valid_until: datetime | None
    status: str
    created_by: str
    accepted_at: datetime | None
    rejected_at: datetime | None
    created_at: datetime
    updated_at: datetime


class CommercialContractCreateRequest(BaseModel):
    customer_id: str
    proposal_id: str | None = None
    title: str
    terms: str
    start_at: datetime
    end_at: datetime | None = None


class CommercialContractResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    customer_id: str
    proposal_id: str | None
    title: str
    terms: str
    start_at: datetime
    end_at: datetime | None
    status: str
    signed_by_customer_at: datetime | None
    signed_by_company_at: datetime | None
    signature_metadata: dict[str, Any]
    created_at: datetime
    updated_at: datetime


class CommercialPlanCreateRequest(BaseModel):
    code: str
    name: str
    description: str = ""
    billing_cycle: str = "monthly"
    price: float = 0
    limits: dict[str, Any] = Field(default_factory=dict)
    features: list[str] = Field(default_factory=list)
    active: bool = True


class CommercialPlanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    code: str
    name: str
    description: str
    billing_cycle: str
    price: float
    limits: dict[str, Any]
    features: list[str]
    active: bool
    created_at: datetime
    updated_at: datetime


class CommercialSubscriptionCreateRequest(BaseModel):
    customer_id: str
    plan_id: str
    started_at: datetime
    trial_ends_at: datetime | None = None
    renews_at: datetime | None = None
    external_reference: str = ""
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class CommercialSubscriptionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    customer_id: str
    plan_id: str
    status: str
    started_at: datetime
    trial_ends_at: datetime | None
    renews_at: datetime | None
    canceled_at: datetime | None
    external_reference: str
    metadata_json: dict[str, Any]
    created_at: datetime
    updated_at: datetime


class CommercialInvoiceCreateRequest(BaseModel):
    customer_id: str
    subscription_id: str | None = None
    reference: str
    amount: float
    due_at: datetime
    payment_method: str = ""
    external_reference: str = ""
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class CommercialInvoiceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    customer_id: str
    subscription_id: str | None
    reference: str
    amount: float
    due_at: datetime
    status: str
    payment_method: str
    paid_at: datetime | None
    external_reference: str
    metadata_json: dict[str, Any]
    created_at: datetime
    updated_at: datetime


class MlDatasetCreateRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    farm_id: str | None = None
    name: str
    version: str = "1"
    task_type: str
    target_column: str = ""
    source_tables: list[str] = Field(default_factory=list)
    filters: dict[str, Any] = Field(default_factory=dict)
    dataset_schema: dict[str, Any] = Field(
        default_factory=dict,
        validation_alias="schema_json",
        serialization_alias="schema_json",
    )


class MlDatasetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
    id: str
    farm_id: str | None
    name: str
    version: str
    task_type: str
    target_column: str
    source_tables: list[str]
    filters: dict[str, Any]
    dataset_schema: dict[str, Any] = Field(
        validation_alias="schema_json",
        serialization_alias="schema_json",
    )
    row_count: int
    status: str
    checksum: str
    created_by: str
    created_at: datetime
    updated_at: datetime


class MlFeatureCreateRequest(BaseModel):
    key: str
    name: str
    description: str = ""
    data_type: str = "float"
    source_expression: str
    default_value: float | None = None
    active: bool = True


class MlFeatureResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    key: str
    name: str
    description: str
    data_type: str
    source_expression: str
    default_value: float | None
    active: bool
    created_at: datetime
    updated_at: datetime


class MlTrainingCreateRequest(BaseModel):
    dataset_id: str
    algorithm: str
    parameters: dict[str, Any] = Field(default_factory=dict)


class MlTrainingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    dataset_id: str
    algorithm: str
    parameters: dict[str, Any]
    metrics: dict[str, Any]
    status: str
    started_at: datetime | None
    completed_at: datetime | None
    error_message: str
    artifact_path: str
    created_by: str
    created_at: datetime


class MlModelCreateRequest(BaseModel):
    training_run_id: str | None = None
    name: str
    version: str
    task_type: str
    algorithm: str
    metrics: dict[str, Any] = Field(default_factory=dict)
    feature_keys: list[str] = Field(default_factory=list)
    target_name: str = ""
    artifact_path: str = ""
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class MlModelResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    training_run_id: str | None
    name: str
    version: str
    task_type: str
    algorithm: str
    metrics: dict[str, Any]
    feature_keys: list[str]
    target_name: str
    status: str
    artifact_path: str
    metadata_json: dict[str, Any]
    created_at: datetime


class MlDeploymentCreateRequest(BaseModel):
    model_id: str
    farm_id: str | None = None
    environment: str = "production"
    traffic_percent: float = Field(default=100, ge=0, le=100)
    threshold: float | None = None


class MlDeploymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    model_id: str
    environment: str
    status: str
    traffic_percent: float
    threshold: float | None
    deployed_by: str
    deployed_at: datetime
    retired_at: datetime | None


class MlPredictRequest(BaseModel):
    farm_id: str | None = None
    entity_type: str = ""
    entity_id: str = ""
    features: dict[str, float] = Field(default_factory=dict)


class MlPredictionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    deployment_id: str
    entity_type: str
    entity_id: str
    input_features: dict[str, Any]
    prediction: dict[str, Any]
    confidence: float
    explanation: dict[str, Any]
    latency_ms: int
    created_at: datetime


class MlFeedbackCreateRequest(BaseModel):
    actual_value: dict[str, Any] = Field(default_factory=dict)
    accepted: bool | None = None
    notes: str = ""


class MlDriftResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    deployment_id: str
    feature_drift: dict[str, Any]
    prediction_drift: float
    performance_drift: float | None
    status: str
    recommendations: list[str]
    generated_at: datetime


class AtlasAiSessionCreateRequest(BaseModel):
    farm_id: str | None = None
    title: str = "Conversa Atlas"


class AtlasAiSessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    user_id: str
    title: str
    status: str
    context_snapshot: dict[str, Any]
    last_message_at: datetime | None
    created_at: datetime
    updated_at: datetime


class AtlasAiChatRequest(BaseModel):
    session_id: str | None = None
    farm_id: str | None = None
    message: str = Field(min_length=1)
    requested_specialty: str | None = None


class AtlasAiChatResponse(BaseModel):
    session_id: str
    message_id: str
    answer: str
    agent_code: str
    confidence_percent: float
    evidence: list[str]
    limitations: list[str]
    recommendations_created: list[str]


class AtlasAiSessionMessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    session_id: str
    role: str
    content: str
    agent_code: str
    confidence_percent: float
    sources: list[Any]
    evidence: list[Any]
    limitations: list[Any]
    created_at: datetime


class AtlasAiMemoryCreateRequest(BaseModel):
    farm_id: str | None = None
    user_id: str | None = None
    memory_type: str
    key: str
    content: dict[str, Any] = Field(default_factory=dict)
    importance: float = Field(default=0.5, ge=0, le=1)
    source: str = "atlas"
    expires_at: datetime | None = None


class AtlasAiRecommendationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    agent_code: str
    title: str
    description: str
    priority: str
    status: str
    confidence_percent: float
    expected_financial_impact: float
    expected_technical_impact: str
    reasoning: list[Any]
    actions: list[Any]
    due_at: datetime | None
    reviewed_by: str | None
    reviewed_at: datetime | None
    created_at: datetime


class AtlasAiPlanRequest(BaseModel):
    farm_id: str | None = None
    horizon: str = Field(pattern="^(daily|weekly|monthly)$")


class AtlasAiPlanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    horizon: str
    title: str
    summary: str
    items: list[Any]
    confidence_percent: float
    status: str
    generated_by: str
    generated_at: datetime


class AtlasKnowledgeDocumentCreateRequest(BaseModel):
    farm_id: str | None = None
    title: str
    category: str
    content: str
    tags: list[str] = Field(default_factory=list)
    source_reference: str = ""


class AtlasKnowledgeDocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    farm_id: str | None
    title: str
    category: str
    content: str
    tags: list[str]
    source_reference: str
    checksum: str
    active: bool
    created_at: datetime
    updated_at: datetime


class AutomationRuleCreateRequest(BaseModel):
    farm_id: str | None = None
    name: str
    event_type: str
    conditions: dict[str, Any] = Field(default_factory=dict)
    actions: list[dict[str, Any]] = Field(default_factory=list)
    enabled: bool = True
    priority: int = Field(default=50, ge=0, le=100)


class WorkflowCreateRequest(BaseModel):
    code: str
    name: str
    description: str = ""
    steps: list[dict[str, Any]] = Field(default_factory=list)
    active: bool = True


class WorkflowStartRequest(BaseModel):
    farm_id: str | None = None
    context: dict[str, Any] = Field(default_factory=dict)


class CorporateCalendarEventCreateRequest(BaseModel):
    farm_id: str | None = None
    title: str
    category: str
    description: str = ""
    starts_at: datetime
    ends_at: datetime | None = None
    responsible_user_id: str | None = None
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class StrategicObjectiveCreateRequest(BaseModel):
    farm_id: str | None = None
    title: str
    description: str = ""
    owner_user_id: str | None = None
    due_at: datetime | None = None
    key_results: list[dict[str, Any]] = Field(default_factory=list)


class DataGovernancePolicyCreateRequest(BaseModel):
    code: str
    name: str
    description: str = ""
    resource_type: str
    classification: str = "internal"
    retention_days: int = Field(default=365, ge=0)
    legal_basis: str = ""
    access_rules: dict[str, Any] = Field(default_factory=dict)
    active: bool = True


class DataCatalogAssetCreateRequest(BaseModel):
    asset_key: str
    name: str
    asset_type: str
    source_system: str = "atlas"
    owner_user_id: str | None = None
    steward_user_id: str | None = None
    classification: str = "internal"
    schema_definition: dict[str, Any] = Field(default_factory=dict)
    lineage: list[dict[str, Any]] = Field(default_factory=list)


class DataQualityRuleCreateRequest(BaseModel):
    asset_id: str
    name: str
    rule_type: str
    field_name: str = ""
    parameters: dict[str, Any] = Field(default_factory=dict)
    severity: str = "warning"
    enabled: bool = True


class ComplianceControlCreateRequest(BaseModel):
    code: str
    name: str
    framework: str = "internal"
    description: str = ""
    evidence_requirements: list[str] = Field(default_factory=list)
    owner_user_id: str | None = None
    next_review_at: datetime | None = None


class ComplianceAssessmentCreateRequest(BaseModel):
    result: str
    score: float = Field(ge=0, le=100)
    findings: list[dict[str, Any]] = Field(default_factory=list)
    evidence: list[dict[str, Any]] = Field(default_factory=list)


class ServiceHealthSnapshotCreateRequest(BaseModel):
    service_name: str
    status: str
    latency_ms: int = Field(default=0, ge=0)
    availability_percent: float = Field(default=100, ge=0, le=100)
    error_rate_percent: float = Field(default=0, ge=0, le=100)
    metadata_json: dict[str, Any] = Field(default_factory=dict)


class ResilienceIncidentCreateRequest(BaseModel):
    title: str
    severity: str
    affected_services: list[str] = Field(default_factory=list)
    description: str


class IntegrationProviderCreateRequest(BaseModel):
    code: str
    name: str
    category: str
    description: str = ""
    base_url: str = ""
    auth_type: str = "api_key"
    capabilities: list[str] = Field(default_factory=list)
    active: bool = True


class IntegrationConnectionCreateRequest(BaseModel):
    farm_id: str | None = None
    provider_id: str
    name: str
    credentials: dict[str, Any] = Field(default_factory=dict)
    configuration: dict[str, Any] = Field(default_factory=dict)
    scopes: list[str] = Field(default_factory=list)


class IntegrationSyncJobCreateRequest(BaseModel):
    connection_id: str
    job_type: str
    direction: str = Field(default="pull", pattern="^(pull|push|bidirectional)$")
    payload: dict[str, Any] = Field(default_factory=dict)


class OutboundWebhookCreateRequest(BaseModel):
    farm_id: str | None = None
    name: str
    target_url: str
    secret: str = ""
    event_types: list[str] = Field(default_factory=list)
    headers: dict[str, str] = Field(default_factory=dict)
    retry_policy: dict[str, Any] = Field(
        default_factory=lambda: {
            "max_attempts": 5,
            "base_delay_seconds": 30,
        }
    )


class PartnerApplicationCreateRequest(BaseModel):
    name: str
    partner_name: str
    scopes: list[str] = Field(default_factory=list)
    allowed_origins: list[str] = Field(default_factory=list)
    rate_limit_per_minute: int = Field(default=60, ge=1, le=10000)


class ApiUsageRecordCreateRequest(BaseModel):
    partner_application_id: str | None = None
    endpoint: str
    method: str
    status_code: int
    duration_ms: int = Field(default=0, ge=0)
    request_units: int = Field(default=1, ge=1)


class SecurityPolicyCreateRequest(BaseModel):
    code: str
    name: str
    description: str = ""
    policy_type: str
    rules: dict[str, Any] = Field(default_factory=dict)
    enforcement_mode: str = Field(default="monitor", pattern="^(monitor|enforce)$")
    active: bool = True


class AccessReviewCreateRequest(BaseModel):
    review_type: str
    subject_user_id: str
    reviewer_user_id: str | None = None
    permissions_snapshot: dict[str, Any] = Field(default_factory=dict)
    due_at: datetime | None = None


class PrivacyConsentCreateRequest(BaseModel):
    data_subject_type: str
    data_subject_id: str
    purpose: str
    legal_basis: str = ""
    granted: bool = True
    evidence: dict[str, Any] = Field(default_factory=dict)


class PrivacyRequestCreateRequest(BaseModel):
    request_type: str
    data_subject_type: str
    data_subject_id: str
    description: str = ""
    due_at: datetime | None = None


class SecurityRiskCreateRequest(BaseModel):
    title: str
    category: str
    likelihood: float = Field(ge=0, le=5)
    impact: float = Field(ge=0, le=5)
    treatment: str = ""
    owner_user_id: str | None = None
    due_at: datetime | None = None


class BusinessContinuityPlanCreateRequest(BaseModel):
    name: str
    scenario: str
    critical_services: list[str] = Field(default_factory=list)
    recovery_steps: list[dict[str, Any]] = Field(default_factory=list)
    rto_minutes: int = Field(default=240, ge=0)
    rpo_minutes: int = Field(default=60, ge=0)
    owner_user_id: str | None = None
    active: bool = True


class ContinuityExerciseCreateRequest(BaseModel):
    plan_id: str


class ContinuityExerciseCompleteRequest(BaseModel):
    actual_rto_minutes: int = Field(ge=0)
    actual_rpo_minutes: int = Field(ge=0)
    findings: list[dict[str, Any]] = Field(default_factory=list)


class ReleasePipelineCreateRequest(BaseModel):
    code: str
    name: str
    description: str = ""
    stages: list[dict[str, Any]] = Field(default_factory=list)
    active: bool = True


class ReleaseBuildCreateRequest(BaseModel):
    pipeline_id: str
    version: str
    commit_sha: str = ""
    branch: str = "main"


class DeploymentEnvironmentCreateRequest(BaseModel):
    code: str
    name: str
    environment_type: str
    base_url: str = ""
    configuration: dict[str, Any] = Field(default_factory=dict)
    protected: bool = False
    active: bool = True


class DeploymentReleaseCreateRequest(BaseModel):
    build_id: str
    environment_id: str
    strategy: str = Field(default="rolling", pattern="^(rolling|blue_green|canary|recreate)$")
    rollback_build_id: str | None = None


class FeatureFlagCreateRequest(BaseModel):
    key: str
    name: str
    description: str = ""
    enabled: bool = False
    rollout_percent: float = Field(default=0, ge=0, le=100)
    targeting_rules: list[dict[str, Any]] = Field(default_factory=list)
    environments: list[str] = Field(default_factory=list)


class ChangeApprovalCreateRequest(BaseModel):
    change_type: str
    reference_id: str
    title: str
    description: str = ""
    risk_level: str = "medium"


class ReadinessCheckCreateRequest(BaseModel):
    release_id: str | None = None
    check_type: str
    name: str
    required: bool = True


class ReadinessCheckCompleteRequest(BaseModel):
    status: str = Field(pattern="^(passed|failed|waived)$")
    evidence: dict[str, Any] = Field(default_factory=dict)
    findings: list[dict[str, Any]] = Field(default_factory=list)


# Fases 2 e 3 — contratos integrados de nutrição, estoque e financeiro.
class InventoryProductPhase2CreateRequest(BaseModel):
    farm_id: str
    sku: str
    name: str
    category: str = ""
    unit: str = "un"
    quantity: float = Field(default=0, ge=0)
    minimum_quantity: float = Field(default=0, ge=0)
    maximum_quantity: float = Field(default=0, ge=0)
    average_cost: float = Field(default=0, ge=0)
    last_purchase_cost: float = Field(default=0, ge=0)
    expiry_date: datetime | None = None
    manufacturing_date: datetime | None = None
    batch_number: str = ""
    supplier: str = ""
    storage_location: str = ""
    active_ingredient: str = ""
    barcode: str = ""
    notes: str = ""


class InventoryMovementPhase2Request(BaseModel):
    movement_type: str
    quantity: float = Field(gt=0)
    unit_cost: float = Field(default=0, ge=0)
    reason: str = ""
    document_number: str = ""
    product_batch: str = ""
    reference_type: str = ""
    reference_id: str = ""
    occurred_at: datetime | None = None


class InventoryMovementPhase2Response(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    product_id: str
    movement_type: str
    quantity: float
    unit_cost: float
    balance_after: float
    reason: str
    document_number: str
    product_batch: str
    reference_type: str
    reference_id: str
    occurred_at: datetime


class InventoryAlertResponse(BaseModel):
    product_id: str
    product_name: str
    alert_type: str
    severity: str
    message: str
    quantity: float
    minimum_quantity: float
    expiry_date: datetime | None = None


class NutritionIngredientCreateRequest(BaseModel):
    farm_id: str
    inventory_product_id: str | None = None
    name: str
    category: str = "other"
    unit: str = "kg"
    dry_matter_percent: float = Field(default=0, ge=0, le=100)
    crude_protein_percent: float = Field(default=0, ge=0, le=100)
    ndf_percent: float = Field(default=0, ge=0, le=100)
    adf_percent: float = Field(default=0, ge=0, le=100)
    tdn_percent: float = Field(default=0, ge=0, le=100)
    cost_per_kg: float = Field(default=0, ge=0)
    notes: str = ""


class NutritionIngredientResponse(NutritionIngredientCreateRequest):
    model_config = ConfigDict(from_attributes=True)
    id: str
    active: bool
    created_at: datetime


class NutritionPlanCreateRequest(BaseModel):
    farm_id: str
    lot_id: str
    name: str
    category: str = ""
    start_date: datetime | None = None
    end_date: datetime | None = None
    daily_amount_per_animal_kg: float = Field(gt=0)
    animal_count: int = Field(default=0, ge=0)
    average_body_weight_kg: float = Field(default=0, ge=0)
    target_daily_gain_kg: float = Field(default=0, ge=0)
    dry_matter_percent: float = Field(default=0, ge=0, le=100)
    crude_protein_percent: float = Field(default=0, ge=0, le=100)
    ndf_percent: float = Field(default=0, ge=0, le=100)
    tdn_percent: float = Field(default=0, ge=0, le=100)
    cost_per_kg: float = Field(default=0, ge=0)
    ingredients_json: list[dict] = Field(default_factory=list)
    notes: str = ""


class NutritionPlanResponse(NutritionPlanCreateRequest):
    model_config = ConfigDict(from_attributes=True)
    id: str
    active: bool
    created_at: datetime
    created_by: str


class NutritionConsumptionRequest(BaseModel):
    nutrition_plan_id: str | None = None
    product_id: str | None = None
    diet_name: str
    amount_per_animal: float = Field(default=0, ge=0)
    animal_count: int = Field(default=0, ge=0)
    total_quantity: float = Field(gt=0)
    planned_quantity: float = Field(default=0, ge=0)
    observed_daily_gain_kg: float = Field(default=0, ge=0)
    notes: str = ""
    occurred_at: datetime | None = None


class FinancialEntryPhase3CreateRequest(BaseModel):
    farm_id: str
    animal_id: str | None = None
    lot_id: str | None = None
    entry_type: str
    category: str = ""
    cost_center: str = "Geral"
    description: str
    amount: float = Field(gt=0)
    status: str = "pending"
    competence_date: datetime | None = None
    due_date: datetime | None = None
    paid_at: datetime | None = None
    payment_method: str = ""
    counterparty: str = ""
    document_number: str = ""
    recurring: bool = False
    recurrence_rule: str = ""
    reference_type: str = ""
    reference_id: str = ""
    notes: str = ""


class FinancialEntryPhase3Response(FinancialEntryPhase3CreateRequest):
    model_config = ConfigDict(from_attributes=True)
    id: str
    created_at: datetime
    created_by: str


class FinancialSettlementRequest(BaseModel):
    paid_at: datetime | None = None
    payment_method: str = ""


class FinancialSummaryResponse(BaseModel):
    farm_id: str
    income: float
    expense: float
    paid_income: float
    paid_expense: float
    receivable: float
    payable: float
    overdue_receivable: float
    overdue_payable: float
    balance: float
    projected_balance: float
    cost_by_center: dict[str, float]
    cost_by_lot: dict[str, float]
    cost_by_animal: dict[str, float]
    indicators: dict[str, float]
