
from __future__ import annotations

import base64
import hashlib
import hmac
import secrets
import struct
import time
from datetime import datetime, timedelta, timezone
from urllib.parse import quote

from fastapi import HTTPException, status
from jose import JWTError, jwt
from passlib.context import CryptContext

from .config import get_settings

settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ALGORITHM = "HS256"


def validate_password_strength(password: str) -> None:
    checks = (
        len(password) >= 10,
        any(char.isupper() for char in password),
        any(char.islower() for char in password),
        any(char.isdigit() for char in password),
        any(not char.isalnum() for char in password),
    )
    if not all(checks):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                "A senha deve ter ao menos 10 caracteres, com maiúscula, "
                "minúscula, número e símbolo."
            ),
        )


def hash_password(password: str) -> str:
    validate_password_strength(password)
    return pwd_context.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return pwd_context.verify(password, password_hash)
    except ValueError:
        return False


def create_access_token(
    *,
    user_id: str,
    company_id: str,
    tenant_id: str,
    role: str,
    token_type: str = "access",
    extra: dict | None = None,
) -> str:
    now = datetime.now(timezone.utc)
    expires = now + timedelta(
        minutes=settings.atlas_access_token_minutes
    )
    payload = {
        "sub": user_id,
        "company_id": company_id,
        "tenant_id": tenant_id,
        "role": role,
        "type": token_type,
        "exp": expires,
        "iat": now,
        "jti": secrets.token_hex(16),
        **(extra or {}),
    }
    return jwt.encode(
        payload,
        settings.atlas_jwt_secret,
        algorithm=ALGORITHM,
    )


def create_challenge_token(
    *,
    user_id: str,
    company_id: str,
    tenant_id: str,
    role: str,
) -> str:
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {
            "sub": user_id,
            "company_id": company_id,
            "tenant_id": tenant_id,
            "role": role,
            "type": "mfa_challenge",
            "exp": now + timedelta(minutes=5),
            "iat": now,
            "jti": secrets.token_hex(16),
        },
        settings.atlas_jwt_secret,
        algorithm=ALGORITHM,
    )


def decode_access_token(
    token: str,
    *,
    expected_type: str = "access",
) -> dict:
    try:
        payload = jwt.decode(
            token,
            settings.atlas_jwt_secret,
            algorithms=[ALGORITHM],
        )
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido ou expirado.",
        ) from exc

    if payload.get("type", "access") != expected_type:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Tipo de token inválido.",
        )
    return payload


def generate_opaque_token() -> str:
    return secrets.token_urlsafe(48)


def token_digest(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def generate_recovery_codes(count: int = 8) -> list[str]:
    return [
        f"{secrets.randbelow(1_000_000):06d}-{secrets.randbelow(1_000_000):06d}"
        for _ in range(count)
    ]


def generate_totp_secret() -> str:
    return base64.b32encode(secrets.token_bytes(20)).decode("ascii").rstrip("=")


def _decode_base32(secret: str) -> bytes:
    padding = "=" * ((8 - len(secret) % 8) % 8)
    return base64.b32decode(secret.upper() + padding)


def totp_code(
    secret: str,
    *,
    for_time: int | None = None,
    interval: int = 30,
    digits: int = 6,
) -> str:
    timestamp = int(for_time or time.time())
    counter = timestamp // interval
    message = struct.pack(">Q", counter)
    digest = hmac.new(
        _decode_base32(secret),
        message,
        hashlib.sha1,
    ).digest()
    offset = digest[-1] & 0x0F
    binary = (
        (digest[offset] & 0x7F) << 24
        | digest[offset + 1] << 16
        | digest[offset + 2] << 8
        | digest[offset + 3]
    )
    return str(binary % (10**digits)).zfill(digits)


def verify_totp(
    secret: str,
    code: str,
    *,
    valid_window: int = 1,
) -> bool:
    now = int(time.time())
    normalized = code.strip().replace(" ", "")
    return any(
        hmac.compare_digest(
            totp_code(secret, for_time=now + offset * 30),
            normalized,
        )
        for offset in range(-valid_window, valid_window + 1)
    )


def provisioning_uri(
    *,
    secret: str,
    email: str,
    issuer: str = "Projeto Atlas",
) -> str:
    label = quote(f"{issuer}:{email}")
    return (
        f"otpauth://totp/{label}?secret={secret}"
        f"&issuer={quote(issuer)}&algorithm=SHA1&digits=6&period=30"
    )
