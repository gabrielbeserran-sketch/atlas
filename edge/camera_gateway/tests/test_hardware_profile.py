import json

import pytest

from atlas_camera_gateway.hardware_profile import (
    CameraCompatibilityReport,
    _find_xaddr,
    _safe_host,
)


def test_safe_host_rejects_url_and_path() -> None:
    with pytest.raises(ValueError):
        _safe_host("http://192.168.1.20")
    with pytest.raises(ValueError):
        _safe_host("../camera")


def test_onvif_capability_parser_extracts_media_and_events() -> None:
    xml = """<?xml version="1.0"?>
    <Envelope xmlns="http://www.w3.org/2003/05/soap-envelope"
              xmlns:tt="http://www.onvif.org/ver10/schema">
      <Body>
        <GetCapabilitiesResponse>
          <Capabilities>
            <Media>
              <XAddr>http://camera/onvif/media_service</XAddr>
            </Media>
            <Events>
              <XAddr>http://camera/onvif/events_service</XAddr>
            </Events>
          </Capabilities>
        </GetCapabilitiesResponse>
      </Body>
    </Envelope>
    """
    assert _find_xaddr(xml, "Media").endswith("/onvif/media_service")
    assert _find_xaddr(xml, "Events").endswith("/onvif/events_service")


def test_report_never_contains_password_field() -> None:
    report = CameraCompatibilityReport(
        host="192.168.1.20",
        resolved_ip="192.168.1.20",
        reachable_ports={"rtsp": True},
        onvif_endpoint="http://192.168.1.20/onvif/device_service",
        onvif_reachable=True,
        onvif_authenticated=True,
        onvif_media_xaddr="",
        onvif_events_xaddr="",
        rtsp_port_reachable=True,
        likely_capabilities=["rtsp_tcp"],
        limitations=[],
    )
    payload = json.loads(report.to_json())
    assert "password" not in payload
    assert "username" not in payload
