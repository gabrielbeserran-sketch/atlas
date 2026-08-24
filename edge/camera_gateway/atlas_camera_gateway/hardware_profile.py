from __future__ import annotations

from dataclasses import asdict, dataclass
import ipaddress
import json
import os
import socket
from urllib.parse import urlparse
import xml.etree.ElementTree as ET



SOAP_GET_CAPABILITIES = """<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
            xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <s:Body>
    <tds:GetCapabilities>
      <tds:Category>All</tds:Category>
    </tds:GetCapabilities>
  </s:Body>
</s:Envelope>
"""


@dataclass(frozen=True)
class CameraCompatibilityReport:
    host: str
    resolved_ip: str
    reachable_ports: dict[str, bool]
    onvif_endpoint: str
    onvif_reachable: bool
    onvif_authenticated: bool
    onvif_media_xaddr: str
    onvif_events_xaddr: str
    rtsp_port_reachable: bool
    likely_capabilities: list[str]
    limitations: list[str]

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2)


def _safe_host(value: str) -> str:
    host = value.strip()
    if not host or len(host) > 253:
        raise ValueError("Host da câmera inválido.")
    if "://" in host or "/" in host or "\\" in host:
        raise ValueError("Informe apenas IP ou hostname da câmera.")
    return host


def resolve_host(host: str) -> str:
    safe = _safe_host(host)
    try:
        return str(ipaddress.ip_address(safe))
    except ValueError:
        pass
    try:
        return socket.gethostbyname(safe)
    except OSError as exc:
        raise RuntimeError(f"Não foi possível resolver a câmera: {safe}") from exc


def tcp_reachable(host: str, port: int, timeout: float = 1.5) -> bool:
    if not 1 <= port <= 65535:
        raise ValueError("Porta inválida.")
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


def _find_xaddr(xml_text: str, capability_name: str) -> str:
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return ""

    for element in root.iter():
        local_name = element.tag.rsplit("}", 1)[-1]
        if local_name != capability_name:
            continue
        for child in element.iter():
            if child.tag.rsplit("}", 1)[-1] == "XAddr":
                return (child.text or "").strip()
    return ""


def probe_onvif(
    *,
    host: str,
    port: int,
    username: str = "",
    password: str = "",
    timeout: float = 4.0,
) -> tuple[bool, bool, str, str, str]:
    try:
        import httpx
    except ImportError as exc:
        raise RuntimeError(
            "O diagnóstico ONVIF requer o gateway instalado com suas "
            "dependências (pip install .)."
        ) from exc

    endpoint = f"http://{host}:{port}/onvif/device_service"
    auth = None
    if username:
        auth = httpx.DigestAuth(username, password)

    try:
        response = httpx.post(
            endpoint,
            content=SOAP_GET_CAPABILITIES.encode("utf-8"),
            headers={
                "Content-Type":
                    "application/soap+xml; charset=utf-8",
                "Accept": "application/soap+xml, text/xml",
            },
            timeout=timeout,
            auth=auth,
            follow_redirects=False,
        )
    except httpx.HTTPError:
        return False, False, endpoint, "", ""

    reachable = response.status_code not in {404, 405}
    authenticated = response.status_code < 400
    if not authenticated:
        return reachable, False, endpoint, "", ""

    body = response.text
    media = _find_xaddr(body, "Media")
    events = _find_xaddr(body, "Events")
    return reachable, True, endpoint, media, events


def build_report(
    *,
    host: str,
    onvif_port: int = 80,
    rtsp_port: int = 554,
    username: str = "",
    password: str | None = None,
) -> CameraCompatibilityReport:
    safe_host = _safe_host(host)
    resolved_ip = resolve_host(safe_host)

    probe_ports = {
        "http": 80,
        "https": 443,
        "rtsp": rtsp_port,
        "onvif": onvif_port,
        "8000": 8000,
        "8899": 8899,
    }
    reachable_ports = {
        name: tcp_reachable(safe_host, port)
        for name, port in probe_ports.items()
    }

    secret = (
        password
        if password is not None
        else os.getenv("ATLAS_CAMERA_PASSWORD", "")
    )
    onvif_reachable = False
    onvif_authenticated = False
    endpoint = f"http://{safe_host}:{onvif_port}/onvif/device_service"
    media = ""
    events = ""

    if reachable_ports["onvif"]:
        (
            onvif_reachable,
            onvif_authenticated,
            endpoint,
            media,
            events,
        ) = probe_onvif(
            host=safe_host,
            port=onvif_port,
            username=username.strip(),
            password=secret,
        )

    capabilities: list[str] = []
    limitations: list[str] = []

    if onvif_reachable:
        capabilities.append("onvif_device_service")
    if media:
        capabilities.append("onvif_media")
    if events:
        capabilities.append("onvif_events")
    if reachable_ports["rtsp"]:
        capabilities.append("rtsp_tcp")

    if not onvif_reachable:
        limitations.append(
            "ONVIF não foi confirmado neste endereço/porta."
        )
    elif username and not onvif_authenticated:
        limitations.append(
            "ONVIF respondeu, mas as credenciais não foram aceitas."
        )
    elif not username and not onvif_authenticated:
        limitations.append(
            "ONVIF respondeu, mas pode exigir autenticação."
        )

    if not reachable_ports["rtsp"]:
        limitations.append(
            "A porta RTSP informada não respondeu ao teste TCP."
        )

    if "onvif_events" not in capabilities:
        limitations.append(
            "Eventos inteligentes ONVIF ainda não foram confirmados."
        )

    return CameraCompatibilityReport(
        host=safe_host,
        resolved_ip=resolved_ip,
        reachable_ports=reachable_ports,
        onvif_endpoint=endpoint,
        onvif_reachable=onvif_reachable,
        onvif_authenticated=onvif_authenticated,
        onvif_media_xaddr=media,
        onvif_events_xaddr=events,
        rtsp_port_reachable=reachable_ports["rtsp"],
        likely_capabilities=capabilities,
        limitations=limitations,
    )


def sanitize_url(value: str) -> str:
    parsed = urlparse(value)
    if not parsed.scheme or not parsed.hostname:
        return value
    port = f":{parsed.port}" if parsed.port else ""
    return f"{parsed.scheme}://{parsed.hostname}{port}{parsed.path or ''}"
