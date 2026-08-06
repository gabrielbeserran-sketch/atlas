
from app.models import (
    ApiUsageRecord,
    IntegrationConnection,
    IntegrationProvider,
    IntegrationSyncJob,
    OutboundWebhook,
    PartnerApplication,
    WebhookDelivery,
)


def test_phase55_tables():
    assert IntegrationProvider.__tablename__ == "integration_providers"
    assert IntegrationConnection.__tablename__ == "integration_connections"
    assert IntegrationSyncJob.__tablename__ == "integration_sync_jobs"
    assert OutboundWebhook.__tablename__ == "outbound_webhooks"
    assert WebhookDelivery.__tablename__ == "webhook_deliveries"
    assert PartnerApplication.__tablename__ == "partner_applications"
    assert ApiUsageRecord.__tablename__ == "api_usage_records"
