"""Fase 3: financeiro e custos pecuarios.

Revision ID: 20260806_0022
Revises: 20260806_0021
"""
from alembic import op
import sqlalchemy as sa
revision="20260806_0022"; down_revision="20260806_0021"; branch_labels=None; depends_on=None

def upgrade():
    with op.batch_alter_table("financial_entries") as b:
        b.add_column(sa.Column("animal_id",sa.String(80),nullable=True)); b.add_column(sa.Column("lot_id",sa.String(80),nullable=True))
        b.add_column(sa.Column("cost_center",sa.String(120),nullable=False,server_default="Geral")); b.add_column(sa.Column("status",sa.String(40),nullable=False,server_default="pending"))
        b.add_column(sa.Column("competence_date",sa.DateTime(timezone=True),nullable=True)); b.add_column(sa.Column("payment_method",sa.String(80),nullable=False,server_default=""))
        b.add_column(sa.Column("counterparty",sa.String(180),nullable=False,server_default="")); b.add_column(sa.Column("document_number",sa.String(120),nullable=False,server_default=""))
        b.add_column(sa.Column("recurring",sa.Boolean(),nullable=False,server_default=sa.false())); b.add_column(sa.Column("recurrence_rule",sa.String(120),nullable=False,server_default=""))
        b.add_column(sa.Column("notes",sa.Text(),nullable=False,server_default=""))
        b.create_foreign_key("fk_finance_animal","livestock_animals",["animal_id"],["id"],ondelete="SET NULL")
        b.create_foreign_key("fk_finance_lot","herd_lots",["lot_id"],["id"],ondelete="SET NULL")
        b.create_index("ix_financial_entries_cost_center",["cost_center"]); b.create_index("ix_financial_entries_status",["status"])
        b.create_index("ix_financial_entries_animal_id",["animal_id"]); b.create_index("ix_financial_entries_lot_id",["lot_id"])

def downgrade():
    with op.batch_alter_table("financial_entries") as b:
        for ix in ["ix_financial_entries_lot_id","ix_financial_entries_animal_id","ix_financial_entries_status","ix_financial_entries_cost_center"]: b.drop_index(ix)
        b.drop_constraint("fk_finance_lot",type_="foreignkey"); b.drop_constraint("fk_finance_animal",type_="foreignkey")
        for c in ["notes","recurrence_rule","recurring","document_number","counterparty","payment_method","competence_date","status","cost_center","lot_id","animal_id"]: b.drop_column(c)
