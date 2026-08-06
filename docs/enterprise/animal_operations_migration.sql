-- Migração planejada para agenda e pendências Enterprise.

CREATE TABLE IF NOT EXISTS animal_operational_tasks (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    company_id TEXT NOT NULL,
    farm_id TEXT NOT NULL,
    animal_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT 'Geral',
    priority TEXT NOT NULL DEFAULT 'Média',
    due_date DATE,
    responsible_user_id TEXT,
    status TEXT NOT NULL DEFAULT 'open',
    version INTEGER NOT NULL DEFAULT 1,
    created_by TEXT,
    updated_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_animal_operational_tasks_scope
ON animal_operational_tasks (
    tenant_id,
    company_id,
    farm_id,
    animal_id,
    status,
    due_date
);
