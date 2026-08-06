-- Fundação planejada do Pacote 50.

CREATE TABLE IF NOT EXISTS integration_catalog (
    id TEXT PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    provider_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    manifest JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS integration_installations (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    company_id TEXT,
    farm_id TEXT,
    integration_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
    last_health_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public_api_partners (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    allowed_scopes JSONB NOT NULL DEFAULT '[]'::jsonb,
    rate_limit_per_minute INTEGER NOT NULL DEFAULT 60,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS
idx_integration_installations_scope
ON integration_installations (
    tenant_id,
    company_id,
    farm_id,
    status
);
