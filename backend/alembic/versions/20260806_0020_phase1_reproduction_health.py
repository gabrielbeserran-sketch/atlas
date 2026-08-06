"""Phase 1: reproduction and health consolidation.

Revision ID: 20260806_0020
Revises: 20260806_0019
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0020"
down_revision = "20260806_0019"
branch_labels = None
depends_on = None

def upgrade():
    for name, typ, default in [
        ("reproductive_status", sa.String(60), "unknown"),
        ("last_reproduction_event_at", sa.DateTime(timezone=True), None),
        ("expected_calving_at", sa.DateTime(timezone=True), None),
    ]:
        op.add_column("livestock_animals", sa.Column(name, typ, nullable=True, server_default=default))
    repro=[("event_code",sa.String(50),"observation"),("protocol_stage",sa.String(120),""),("reproductive_status",sa.String(60),""),("responsible",sa.String(180),""),("attempt_number",sa.Integer(),"0"),("pregnancy_days",sa.Integer(),"0"),("calf_id",sa.String(80),""),("calf_sex",sa.String(30),""),("birth_type",sa.String(60),""),("metadata_json",sa.JSON(),None)]
    for n,t,d in repro: op.add_column("reproduction_events",sa.Column(n,t,nullable=True,server_default=d))
    health=[("protocol_name",sa.String(180),""),("product_batch",sa.String(120),""),("frequency",sa.String(120),""),("diagnosis",sa.String(240),""),("severity",sa.String(40),"not_informed"),("next_date",sa.DateTime(timezone=True),None),("status",sa.String(40),"completed"),("is_quarantine",sa.Boolean(),"false"),("is_mortality",sa.Boolean(),"false"),("necropsy_result",sa.Text(),""),("inventory_product_id",sa.String(80),None),("inventory_quantity",sa.Float(),"0"),("treatment_cost",sa.Float(),"0"),("withdrawal_meat_until",sa.DateTime(timezone=True),None),("withdrawal_milk_until",sa.DateTime(timezone=True),None)]
    for n,t,d in health: op.add_column("health_events",sa.Column(n,t,nullable=True,server_default=d))
    op.create_table("health_protocols",sa.Column("id",sa.String(80),primary_key=True),sa.Column("tenant_id",sa.String(80),nullable=False),sa.Column("company_id",sa.String(80),nullable=False),sa.Column("farm_id",sa.String(80),nullable=False),sa.Column("name",sa.String(180),nullable=False),sa.Column("event_type",sa.String(80),nullable=False,server_default="Protocolo sanitário"),sa.Column("product_name",sa.String(180),nullable=False,server_default=""),sa.Column("dosage",sa.String(80),nullable=False,server_default=""),sa.Column("route",sa.String(80),nullable=False,server_default=""),sa.Column("recurrence_days",sa.Integer(),nullable=False,server_default="0"),sa.Column("withdrawal_meat_days",sa.Integer(),nullable=False,server_default="0"),sa.Column("withdrawal_milk_days",sa.Integer(),nullable=False,server_default="0"),sa.Column("active",sa.Boolean(),nullable=False,server_default=sa.true()),sa.Column("notes",sa.Text(),nullable=False,server_default=""),sa.Column("created_by",sa.String(80),nullable=False),sa.Column("created_at",sa.DateTime(timezone=True),nullable=False))

def downgrade():
    op.drop_table("health_protocols")
    for n in ["withdrawal_milk_until","withdrawal_meat_until","treatment_cost","inventory_quantity","inventory_product_id","necropsy_result","is_mortality","is_quarantine","status","next_date","severity","diagnosis","frequency","product_batch","protocol_name"]: op.drop_column("health_events",n)
    for n in ["metadata_json","birth_type","calf_sex","calf_id","pregnancy_days","attempt_number","responsible","reproductive_status","protocol_stage","event_code"]: op.drop_column("reproduction_events",n)
    for n in ["expected_calving_at","last_reproduction_event_at","reproductive_status"]: op.drop_column("livestock_animals",n)
