from __future__ import annotations

import json

import httpx
from dataclasses import dataclass
from urllib import error, request

from ..config import get_settings


@dataclass(frozen=True)
class WhatsAppSendResult:
    message_id: str


class WhatsAppProviderError(RuntimeError):
    pass


class MetaWhatsAppProvider:
    """WhatsApp Business Cloud API para mensagens automáticas por template.

    Boletins mensais são mensagens iniciadas pela empresa. O Atlas não usa
    mensagem `text` livre nesse fluxo: exige template previamente aprovado.
    """

    def __init__(self) -> None:
        self.settings = get_settings()

    @property
    def configured(self) -> bool:
        return bool(
            self.settings.atlas_whatsapp_enabled
            and self.settings.atlas_whatsapp_access_token.strip()
            and self.settings.atlas_whatsapp_phone_number_id.strip()
            and self.settings.atlas_whatsapp_graph_version.strip()
            and self.settings.atlas_whatsapp_template_zootechnical.strip()
            and self.settings.atlas_whatsapp_template_operations.strip()
            and self.settings.atlas_whatsapp_template_financial.strip()
        )

    @property
    def security_alert_configured(self) -> bool:
        return bool(
            self.settings.atlas_whatsapp_enabled
            and self.settings.atlas_whatsapp_access_token.strip()
            and self.settings.atlas_whatsapp_phone_number_id.strip()
            and self.settings.atlas_whatsapp_graph_version.strip()
            and self.settings.atlas_whatsapp_template_security_alert.strip()
        )

    def template_for(self, bulletin_type: str) -> str:
        mapping = {
            "zootechnical":
                self.settings.atlas_whatsapp_template_zootechnical,
            "operations":
                self.settings.atlas_whatsapp_template_operations,
            "financial":
                self.settings.atlas_whatsapp_template_financial,
        }
        template = mapping.get(bulletin_type, "").strip()
        if not template:
            raise WhatsAppProviderError(
                f"Template oficial não configurado para {bulletin_type}."
            )
        return template

    def _graph_url(self, resource: str) -> str:
        version = self.settings.atlas_whatsapp_graph_version.strip()
        phone_number_id = self.settings.atlas_whatsapp_phone_number_id.strip()
        return (
            "https://graph.facebook.com/"
            f"{version}/{phone_number_id}/{resource.lstrip('/')}"
        )

    def _authorization_headers(self) -> dict[str, str]:
        return {
            "Authorization": (
                "Bearer " + self.settings.atlas_whatsapp_access_token.strip()
            ),
            "Accept": "application/json",
        }

    def upload_image(
        self,
        *,
        image_bytes: bytes,
        content_type: str,
        filename: str,
    ) -> str:
        if not self.security_alert_configured:
            raise WhatsAppProviderError(
                "WhatsApp de alertas da entrada ainda não está configurado."
            )
        if not image_bytes:
            raise WhatsAppProviderError("Imagem do alerta vazia.")
        if content_type not in {"image/jpeg", "image/png", "image/webp"}:
            raise WhatsAppProviderError(
                "Formato de imagem não suportado pelo alerta."
            )

        try:
            with httpx.Client(timeout=60.0) as client:
                response = client.post(
                    self._graph_url("media"),
                    headers=self._authorization_headers(),
                    data={"messaging_product": "whatsapp"},
                    files={
                        "file": (
                            filename or "entrada.jpg",
                            image_bytes,
                            content_type,
                        ),
                    },
                )
        except httpx.HTTPError as exc:
            raise WhatsAppProviderError(
                f"Falha ao enviar imagem para WhatsApp Business: {exc}"
            ) from exc

        if response.status_code not in {200, 201}:
            raise WhatsAppProviderError(
                "WhatsApp Business recusou a imagem "
                f"(HTTP {response.status_code}): {response.text[:500]}"
            )

        try:
            payload = response.json()
        except ValueError as exc:
            raise WhatsAppProviderError(
                "WhatsApp Business retornou resposta inválida ao enviar imagem."
            ) from exc

        media_id = str(payload.get("id") or "").strip()
        if not media_id:
            raise WhatsAppProviderError(
                "WhatsApp Business não retornou ID da imagem."
            )
        return media_id

    def send_security_alert(
        self,
        *,
        recipient: str,
        camera_name: str,
        event_label: str,
        captured_at_label: str,
        image_bytes: bytes,
        content_type: str,
        filename: str,
    ) -> WhatsAppSendResult:
        if not self.security_alert_configured:
            raise WhatsAppProviderError(
                "WhatsApp de alertas da entrada ainda não está configurado."
            )

        target = "".join(ch for ch in recipient if ch.isdigit())
        if len(target) < 10 or len(target) > 15:
            raise WhatsAppProviderError(
                "Número de WhatsApp do produtor inválido."
            )

        media_id = self.upload_image(
            image_bytes=image_bytes,
            content_type=content_type,
            filename=filename,
        )

        template_name = (
            self.settings.atlas_whatsapp_template_security_alert.strip()
        )
        payload = {
            "messaging_product": "whatsapp",
            "recipient_type": "individual",
            "to": target,
            "type": "template",
            "template": {
                "name": template_name,
                "language": {
                    "code":
                        self.settings.atlas_whatsapp_template_language.strip()
                        or "pt_BR",
                },
                "components": [
                    {
                        "type": "header",
                        "parameters": [
                            {
                                "type": "image",
                                "image": {"id": media_id},
                            }
                        ],
                    },
                    {
                        "type": "body",
                        "parameters": [
                            {"type": "text", "text": camera_name},
                            {"type": "text", "text": event_label},
                            {"type": "text", "text": captured_at_label},
                        ],
                    },
                ],
            },
        }

        try:
            with httpx.Client(timeout=45.0) as client:
                response = client.post(
                    self._graph_url("messages"),
                    headers={
                        **self._authorization_headers(),
                        "Content-Type": "application/json",
                    },
                    json=payload,
                )
        except httpx.HTTPError as exc:
            raise WhatsAppProviderError(
                f"Falha ao enviar alerta pelo WhatsApp Business: {exc}"
            ) from exc

        if response.status_code not in {200, 201}:
            raise WhatsAppProviderError(
                "WhatsApp Business recusou o alerta "
                f"(HTTP {response.status_code}): {response.text[:500]}"
            )

        try:
            decoded = response.json()
        except ValueError as exc:
            raise WhatsAppProviderError(
                "WhatsApp Business retornou resposta inválida ao enviar alerta."
            ) from exc

        messages = decoded.get("messages")
        if not isinstance(messages, list) or not messages:
            raise WhatsAppProviderError(
                "WhatsApp Business não confirmou o alerta."
            )
        first = messages[0]
        message_id = first.get("id") if isinstance(first, dict) else None
        if not message_id:
            raise WhatsAppProviderError(
                "WhatsApp Business não retornou identificador do alerta."
            )
        return WhatsAppSendResult(message_id=str(message_id))

    def send_bulletin(
        self,
        *,
        recipient: str,
        bulletin_type: str,
        content: str,
    ) -> WhatsAppSendResult:
        if not self.configured:
            raise WhatsAppProviderError(
                "WhatsApp Business ainda não está configurado no backend."
            )

        target = "".join(ch for ch in recipient if ch.isdigit())
        if len(target) < 10 or len(target) > 15:
            raise WhatsAppProviderError(
                "Número de WhatsApp do destinatário inválido."
            )

        message = content.strip()
        if not message:
            raise WhatsAppProviderError("Boletim vazio.")

        template_name = self.template_for(bulletin_type)
        url = (
            "https://graph.facebook.com/"
            f"{self.settings.atlas_whatsapp_graph_version.strip()}/"
            f"{self.settings.atlas_whatsapp_phone_number_id.strip()}/messages"
        )
        payload = {
            "messaging_product": "whatsapp",
            "recipient_type": "individual",
            "to": target,
            "type": "template",
            "template": {
                "name": template_name,
                "language": {
                    "code":
                        self.settings.atlas_whatsapp_template_language.strip()
                        or "pt_BR",
                },
                "components": [
                    {
                        "type": "body",
                        "parameters": [
                            {
                                "type": "text",
                                "text": message,
                            }
                        ],
                    }
                ],
            },
        }

        req = request.Request(
            url,
            data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
            method="POST",
            headers={
                "Authorization": (
                    "Bearer "
                    + self.settings.atlas_whatsapp_access_token.strip()
                ),
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        )

        try:
            with request.urlopen(req, timeout=30) as response:
                raw = response.read().decode("utf-8")
                decoded = json.loads(raw or "{}")
        except error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            raise WhatsAppProviderError(
                f"WhatsApp Business respondeu HTTP {exc.code}: {body[:500]}"
            ) from exc
        except (error.URLError, TimeoutError, OSError) as exc:
            raise WhatsAppProviderError(
                f"Falha de comunicação com WhatsApp Business: {exc}"
            ) from exc

        messages = decoded.get("messages")
        if not isinstance(messages, list) or not messages:
            raise WhatsAppProviderError(
                "WhatsApp Business não retornou confirmação da mensagem."
            )

        first = messages[0]
        message_id = first.get("id") if isinstance(first, dict) else None
        if not message_id:
            raise WhatsAppProviderError(
                "WhatsApp Business não retornou identificador da mensagem."
            )

        return WhatsAppSendResult(message_id=str(message_id))
