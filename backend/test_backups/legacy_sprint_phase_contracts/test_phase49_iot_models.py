
from app.models import (
    IotAutomationRule,
    IotCommand,
    IotDevice,
    IotGateway,
    IotTelemetry,
)


def test_phase49_tables():
    assert IotGateway.__tablename__ == "iot_gateways"
    assert IotDevice.__tablename__ == "iot_devices"
    assert IotTelemetry.__tablename__ == "iot_telemetry"
    assert IotCommand.__tablename__ == "iot_commands"
    assert IotAutomationRule.__tablename__ == "iot_automation_rules"
