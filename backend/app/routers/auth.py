
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from ..authz import Principal, get_principal, resolve_permissions
from ..config import get_settings
from ..database import get_db
from ..models import (
    Company,
    EmailVerificationToken,
    Membership,
    MfaCredential,
    PasswordResetToken,
    RefreshSession,
    SecurityEvent,
    User,
    new_id,
)
from ..schemas import (
    CompanySummary,
    ConfirmEmailRequest,
    LoginRequest,
    LogoutRequest,
    MessageResponse,
    MfaChallengeRequest,
    MfaSetupResponse,
    MfaVerifyRequest,
    PasswordResetConfirmRequest,
    PasswordResetRequest,
    RefreshTokenRequest,
    RegisterRequest,
    RegistrationResponse,
    SecurityEventResponse,
    SessionResponse,
    SwitchCompanyRequest,
    TokenResponse,
)
from ..security import (
    create_access_token,
    create_challenge_token,
    decode_access_token,
    generate_opaque_token,
    generate_recovery_codes,
    generate_totp_secret,
    consume_recovery_code,
    decrypt_mfa_secret,
    encrypt_mfa_secret,
    hash_password,
    provisioning_uri,
    token_digest,
    validate_password_strength,
    verify_password,
    verify_totp,
)
from ..services.mailer import mailer
from ..services.security_events import record_security_event

router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()


def _as_utc(value: datetime | None) -> datetime | None:
    """Normaliza datas do banco para UTC com timezone.

    O PostgreSQL/SQLite de testes pode devolver objetos datetime sem tzinfo,
    mesmo quando a coluna foi declarada com timezone. Esta função evita
    comparações entre datas offset-naive e offset-aware.
    """
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _request_metadata(request: Request) -> tuple[str, str]:
    ip_address = request.client.host if request.client else ""
    return ip_address, request.headers.get("user-agent", "")


def _membership_for_company(
    db: Session,
    *,
    user_id: str,
    company_id: str | None,
) -> Membership:
    query = select(Membership).where(
        Membership.user_id == user_id,
        Membership.active.is_(True),
    )
    memberships = list(db.scalars(query).all())
    if not memberships:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário sem empresa autorizada.",
        )
    if company_id:
        for membership in memberships:
            if membership.company_id == company_id:
                return membership
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário não pertence à empresa solicitada.",
        )
    return memberships[0]


def _companies(
    db: Session,
    *,
    user_id: str,
) -> list[CompanySummary]:
    memberships = db.scalars(
        select(Membership).where(
            Membership.user_id == user_id,
            Membership.active.is_(True),
        )
    ).all()
    result: list[CompanySummary] = []
    for item in memberships:
        linked = db.get(Company, item.company_id)
        if linked is None:
            continue
        result.append(
            CompanySummary(
                id=linked.id,
                tenant_id=linked.tenant_id,
                name=linked.name,
                document=linked.document,
                status=linked.status,
                subscription_plan=linked.subscription_plan,
                role=item.role,
            )
        )
    return result


def _issue_session(
    db: Session,
    *,
    user: User,
    membership: Membership,
    request: Request,
    device_name: str = "",
) -> TokenResponse:
    company = db.get(Company, membership.company_id)
    if company is None:
        raise HTTPException(
            status_code=500,
            detail="Empresa do vínculo não encontrada.",
        )

    ip_address, user_agent = _request_metadata(request)
    refresh_token = generate_opaque_token()
    now = datetime.now(timezone.utc)
    session = RefreshSession(
        id=new_id("session"),
        user_id=user.id,
        company_id=company.id,
        token_hash=token_digest(refresh_token),
        device_name=device_name.strip(),
        ip_address=ip_address,
        user_agent=user_agent,
        expires_at=now + timedelta(days=settings.atlas_refresh_token_days),
        created_at=now,
    )
    db.add(session)
    db.flush()
    record_security_event(
        db,
        event_type="session.created",
        success=True,
        user_id=user.id,
        company_id=company.id,
        ip_address=ip_address,
        user_agent=user_agent,
        details={"session_id": session.id, "device_name": device_name},
    )
    db.commit()

    return TokenResponse(
        access_token=create_access_token(
            user_id=user.id,
            company_id=company.id,
            tenant_id=company.tenant_id,
            role=membership.role,
            extra={"session_id": session.id},
        ),
        refresh_token=refresh_token,
        expires_in_seconds=settings.atlas_access_token_minutes * 60,
        user_id=user.id,
        user_name=user.name,
        email=user.email,
        company_id=company.id,
        tenant_id=company.tenant_id,
        role=membership.role,
        companies=_companies(db, user_id=user.id),
        effective_permissions=sorted(resolve_permissions(membership)),
        farm_ids=list(membership.farm_ids or []),
    )


@router.post(
    "/register",
    response_model=RegistrationResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(
    payload: RegisterRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> RegistrationResponse:
    if not payload.accept_terms:
        raise HTTPException(
            status_code=422,
            detail="É necessário aceitar os termos.",
        )
    validate_password_strength(payload.password)
    email = payload.email.strip().lower()
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="E-mail já cadastrado.",
        )

    user = User(
        id=new_id("user"),
        name=payload.name.strip(),
        email=email,
        password_hash=hash_password(payload.password),
        active=True,
        email_verified=False,
    )
    company = Company(
        id=new_id("company"),
        tenant_id=new_id("tenant"),
        name=payload.company_name.strip(),
        document=payload.company_document.strip(),
        status="active",
        subscription_plan="trial",
    )
    membership = Membership(
        id=new_id("membership"),
        user_id=user.id,
        company_id=company.id,
        role="owner",
        active=True,
        farm_ids=[],
        permission_overrides={},
    )
    verification_token = generate_opaque_token()
    token = EmailVerificationToken(
        id=new_id("email_verify"),
        user_id=user.id,
        token_hash=token_digest(verification_token),
        expires_at=datetime.now(timezone.utc)
        + timedelta(minutes=settings.atlas_email_token_minutes),
    )
    db.add_all([user, company, membership, token])
    ip_address, user_agent = _request_metadata(request)
    record_security_event(
        db,
        event_type="user.registered",
        success=True,
        user_id=user.id,
        company_id=company.id,
        ip_address=ip_address,
        user_agent=user_agent,
    )
    db.commit()

    mailer.send(
        to=email,
        subject="Confirme sua conta Atlas",
        body=(
            "Use o token abaixo para confirmar sua conta:\n"
            f"{verification_token}\n"
            f"Validade: {settings.atlas_email_token_minutes} minutos."
        ),
    )

    return RegistrationResponse(
        user_id=user.id,
        company_id=company.id,
        email=email,
        verification_token=(
            verification_token
            if settings.atlas_env in {"development", "test"}
            else None
        ),
    )


@router.post("/confirm-email", response_model=MessageResponse)
def confirm_email(
    payload: ConfirmEmailRequest,
    db: Session = Depends(get_db),
) -> MessageResponse:
    now = datetime.now(timezone.utc)
    token = db.scalar(
        select(EmailVerificationToken).where(
            EmailVerificationToken.token_hash == token_digest(payload.token)
        )
    )
    if (
        token is None
        or token.used_at is not None
        or _as_utc(token.expires_at) < now
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token de confirmação inválido ou expirado.",
        )
    user = db.get(User, token.user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")
    user.email_verified = True
    token.used_at = now
    record_security_event(
        db,
        event_type="email.verified",
        success=True,
        user_id=user.id,
    )
    db.commit()
    return MessageResponse(message="E-mail confirmado com sucesso.")


@router.post("/login", response_model=TokenResponse)
def login(
    payload: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> TokenResponse:
    email = payload.email.strip().lower()
    user = db.scalar(select(User).where(User.email == email))
    ip_address, user_agent = _request_metadata(request)
    now = datetime.now(timezone.utc)

    if user is not None and user.locked_until and _as_utc(user.locked_until) > now:
        record_security_event(
            db,
            event_type="login.blocked",
            success=False,
            user_id=user.id,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail="Conta temporariamente bloqueada.",
        )

    if (
        user is None
        or not user.active
        or not verify_password(payload.password, user.password_hash)
    ):
        if user is not None:
            user.failed_login_attempts += 1
            if user.failed_login_attempts >= settings.atlas_max_failed_logins:
                user.locked_until = now + timedelta(
                    minutes=settings.atlas_lockout_minutes
                )
                user.failed_login_attempts = 0
        record_security_event(
            db,
            event_type="login.failed",
            success=False,
            user_id=user.id if user else None,
            ip_address=ip_address,
            user_agent=user_agent,
            details={"email": email},
        )
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-mail ou senha inválidos.",
        )

    if not user.email_verified and settings.atlas_env not in {"development", "test"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Confirme o e-mail antes de entrar.",
        )

    user.failed_login_attempts = 0
    user.locked_until = None
    membership = _membership_for_company(
        db,
        user_id=user.id,
        company_id=payload.company_id,
    )
    mfa = db.scalar(
        select(MfaCredential).where(
            MfaCredential.user_id == user.id,
            MfaCredential.enabled.is_(True),
        )
    )
    if mfa is not None:
        company = db.get(Company, membership.company_id)
        if company is None:
            raise HTTPException(status_code=500, detail="Empresa inválida.")
        challenge = create_challenge_token(
            user_id=user.id,
            company_id=company.id,
            tenant_id=company.tenant_id,
            role=membership.role,
        )
        record_security_event(
            db,
            event_type="login.mfa_required",
            success=True,
            user_id=user.id,
            company_id=company.id,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        db.commit()
        return TokenResponse(
            access_token="",
            mfa_required=True,
            challenge_token=challenge,
            user_id=user.id,
            user_name=user.name,
            email=user.email,
            company_id=company.id,
            tenant_id=company.tenant_id,
            role=membership.role,
            companies=_companies(db, user_id=user.id),
            effective_permissions=[],
            farm_ids=[],
        )

    return _issue_session(
        db,
        user=user,
        membership=membership,
        request=request,
    )


@router.post("/mfa/challenge", response_model=TokenResponse)
def complete_mfa_challenge(
    payload: MfaChallengeRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> TokenResponse:
    claims = decode_access_token(
        payload.challenge_token,
        expected_type="mfa_challenge",
    )
    user = db.get(User, str(claims["sub"]))
    company = db.get(Company, str(claims.get("company_id", "")))
    if (
        user is None
        or not user.active
        or company is None
        or company.status != "active"
        or claims.get("tenant_id") != company.tenant_id
    ):
        raise HTTPException(status_code=401, detail="Desafio inválido.")
    credential = db.scalar(
        select(MfaCredential).where(
            MfaCredential.user_id == user.id,
            MfaCredential.enabled.is_(True),
        )
    )
    if credential is None:
        raise HTTPException(status_code=401, detail="MFA não configurado.")

    recovery_hashes = list(credential.recovery_code_hashes or [])
    valid_recovery, remaining_hashes = consume_recovery_code(
        recovery_hashes,
        payload.code,
    )
    secret = decrypt_mfa_secret(credential.secret_encrypted)
    if not verify_totp(secret, payload.code) and not valid_recovery:
        raise HTTPException(status_code=401, detail="Código MFA inválido.")
    if valid_recovery:
        credential.recovery_code_hashes = remaining_hashes

    membership = _membership_for_company(
        db,
        user_id=user.id,
        company_id=str(claims["company_id"]),
    )
    return _issue_session(
        db,
        user=user,
        membership=membership,
        request=request,
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh(
    payload: RefreshTokenRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> TokenResponse:
    now = datetime.now(timezone.utc)
    session = db.scalar(
        select(RefreshSession).where(
            RefreshSession.token_hash == token_digest(payload.refresh_token)
        )
    )
    if (
        session is None
        or session.revoked_at is not None
        or _as_utc(session.expires_at) < now
    ):
        raise HTTPException(status_code=401, detail="Sessão inválida ou expirada.")

    user = db.get(User, session.user_id)
    if user is None or not user.active:
        session.revoked_at = now
        db.commit()
        raise HTTPException(status_code=401, detail="Sessão inválida ou expirada.")

    session.last_used_at = now
    membership = _membership_for_company(
        db,
        user_id=session.user_id,
        company_id=session.company_id,
    )
    session.revoked_at = now
    db.flush()
    return _issue_session(
        db,
        user=user,
        membership=membership,
        request=request,
        device_name=payload.device_name or session.device_name,
    )


@router.post("/logout", response_model=MessageResponse)
def logout(
    payload: LogoutRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> MessageResponse:
    session = db.scalar(
        select(RefreshSession).where(
            RefreshSession.token_hash == token_digest(payload.refresh_token)
        )
    )
    if session and session.revoked_at is None:
        session.revoked_at = datetime.now(timezone.utc)
        ip_address, user_agent = _request_metadata(request)
        record_security_event(
            db,
            event_type="session.revoked",
            success=True,
            user_id=session.user_id,
            company_id=session.company_id,
            ip_address=ip_address,
            user_agent=user_agent,
            details={"session_id": session.id},
        )
        db.commit()
    return MessageResponse(message="Sessão encerrada.")


@router.get("/sessions", response_model=list[SessionResponse])
def list_sessions(
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> list[SessionResponse]:
    now = datetime.now(timezone.utc)
    sessions = db.scalars(
        select(RefreshSession)
        .where(
            RefreshSession.user_id == principal.user.id,
            RefreshSession.revoked_at.is_(None),
            RefreshSession.expires_at > now,
        )
        .order_by(RefreshSession.created_at.desc())
    ).all()
    return [
        SessionResponse(
            id=item.id,
            device_name=item.device_name,
            ip_address=item.ip_address,
            user_agent=item.user_agent,
            expires_at=item.expires_at,
            last_used_at=item.last_used_at,
            created_at=item.created_at,
        )
        for item in sessions
    ]


@router.delete("/sessions/{session_id}", response_model=MessageResponse)
def revoke_session(
    session_id: str,
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    session = db.get(RefreshSession, session_id)
    if session is None or session.user_id != principal.user.id:
        raise HTTPException(status_code=404, detail="Sessão não encontrada.")
    session.revoked_at = datetime.now(timezone.utc)
    record_security_event(
        db,
        event_type="session.revoked_remote",
        success=True,
        user_id=principal.user.id,
        company_id=session.company_id,
        details={"session_id": session.id},
    )
    db.commit()
    return MessageResponse(message="Sessão revogada.")


@router.post("/password/request", response_model=MessageResponse)
def request_password_reset(
    payload: PasswordResetRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> MessageResponse:
    user = db.scalar(
        select(User).where(User.email == payload.email.strip().lower())
    )
    if user is not None:
        now = datetime.now(timezone.utc)
        db.execute(
            update(PasswordResetToken)
            .where(
                PasswordResetToken.user_id == user.id,
                PasswordResetToken.used_at.is_(None),
            )
            .values(used_at=now)
        )
        raw_token = generate_opaque_token()
        db.add(
            PasswordResetToken(
                id=new_id("password_reset"),
                user_id=user.id,
                token_hash=token_digest(raw_token),
                expires_at=now
                + timedelta(minutes=settings.atlas_password_reset_minutes),
            )
        )
        ip_address, user_agent = _request_metadata(request)
        record_security_event(
            db,
            event_type="password_reset.requested",
            success=True,
            user_id=user.id,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        db.commit()
        mailer.send(
            to=user.email,
            subject="Redefinição de senha Atlas",
            body=f"Token temporário: {raw_token}",
        )
    return MessageResponse(
        message="Caso o e-mail exista, as instruções foram enviadas."
    )


@router.post("/password/confirm", response_model=MessageResponse)
def confirm_password_reset(
    payload: PasswordResetConfirmRequest,
    db: Session = Depends(get_db),
) -> MessageResponse:
    validate_password_strength(payload.new_password)
    now = datetime.now(timezone.utc)
    token = db.scalar(
        select(PasswordResetToken).where(
            PasswordResetToken.token_hash == token_digest(payload.token)
        )
    )
    if (
        token is None
        or token.used_at is not None
        or _as_utc(token.expires_at) < now
    ):
        raise HTTPException(
            status_code=400,
            detail="Token de redefinição inválido ou expirado.",
        )
    user = db.get(User, token.user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")
    user.password_hash = hash_password(payload.new_password)
    user.password_changed_at = now
    user.failed_login_attempts = 0
    user.locked_until = None
    token.used_at = now
    db.execute(
        update(RefreshSession)
        .where(
            RefreshSession.user_id == user.id,
            RefreshSession.revoked_at.is_(None),
        )
        .values(revoked_at=now)
    )
    record_security_event(
        db,
        event_type="password_reset.completed",
        success=True,
        user_id=user.id,
    )
    db.commit()
    return MessageResponse(message="Senha redefinida com sucesso.")


@router.post("/mfa/setup", response_model=MfaSetupResponse)
def setup_mfa(
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> MfaSetupResponse:
    existing = db.scalar(
        select(MfaCredential).where(
            MfaCredential.user_id == principal.user.id
        )
    )
    secret = generate_totp_secret()
    recovery_codes = generate_recovery_codes()
    hashes = [token_digest(code) for code in recovery_codes]
    if existing is None:
        existing = MfaCredential(
            id=new_id("mfa"),
            user_id=principal.user.id,
            secret_encrypted=encrypt_mfa_secret(secret),
            recovery_code_hashes=hashes,
            enabled=False,
        )
        db.add(existing)
    else:
        existing.secret_encrypted = encrypt_mfa_secret(secret)
        existing.recovery_code_hashes = hashes
        existing.enabled = False
        existing.verified_at = None
    db.commit()
    return MfaSetupResponse(
        secret=secret,
        provisioning_uri=provisioning_uri(
            secret=secret,
            email=principal.user.email,
        ),
        recovery_codes=recovery_codes,
    )


@router.post("/mfa/verify", response_model=MessageResponse)
def verify_mfa_setup(
    payload: MfaVerifyRequest,
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    credential = db.scalar(
        select(MfaCredential).where(
            MfaCredential.user_id == principal.user.id
        )
    )
    if credential is None or not verify_totp(
        decrypt_mfa_secret(credential.secret_encrypted),
        payload.code,
    ):
        raise HTTPException(status_code=400, detail="Código MFA inválido.")
    credential.enabled = True
    credential.verified_at = datetime.now(timezone.utc)
    record_security_event(
        db,
        event_type="mfa.enabled",
        success=True,
        user_id=principal.user.id,
        company_id=principal.company.id,
    )
    db.commit()
    return MessageResponse(message="MFA ativado com sucesso.")


@router.delete("/mfa", response_model=MessageResponse)
def disable_mfa(
    payload: MfaVerifyRequest,
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    credential = db.scalar(
        select(MfaCredential).where(
            MfaCredential.user_id == principal.user.id,
            MfaCredential.enabled.is_(True),
        )
    )
    if credential is None or not verify_totp(
        decrypt_mfa_secret(credential.secret_encrypted),
        payload.code,
    ):
        raise HTTPException(status_code=400, detail="Código MFA inválido.")
    credential.enabled = False
    record_security_event(
        db,
        event_type="mfa.disabled",
        success=True,
        user_id=principal.user.id,
        company_id=principal.company.id,
    )
    db.commit()
    return MessageResponse(message="MFA desativado.")


@router.get("/security-events", response_model=list[SecurityEventResponse])
def security_events(
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> list[SecurityEventResponse]:
    items = db.scalars(
        select(SecurityEvent)
        .where(SecurityEvent.user_id == principal.user.id)
        .order_by(SecurityEvent.occurred_at.desc())
        .limit(200)
    ).all()
    return [
        SecurityEventResponse(
            id=item.id,
            user_id=item.user_id,
            company_id=item.company_id,
            event_type=item.event_type,
            success=item.success,
            ip_address=item.ip_address,
            user_agent=item.user_agent,
            details=item.details or {},
            occurred_at=item.occurred_at,
        )
        for item in items
    ]


@router.get("/me", response_model=TokenResponse)
def me(
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> TokenResponse:
    return TokenResponse(
        access_token="",
        user_id=principal.user.id,
        user_name=principal.user.name,
        email=principal.user.email,
        company_id=principal.company.id,
        tenant_id=principal.company.tenant_id,
        role=principal.membership.role,
        companies=_companies(db, user_id=principal.user.id),
        effective_permissions=sorted(principal.permissions),
        farm_ids=list(principal.membership.farm_ids or []),
    )


@router.post("/switch-company", response_model=TokenResponse)
def switch_company(
    payload: SwitchCompanyRequest,
    request: Request,
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> TokenResponse:
    membership = _membership_for_company(
        db,
        user_id=principal.user.id,
        company_id=payload.company_id,
    )
    return _issue_session(
        db,
        user=principal.user,
        membership=membership,
        request=request,
    )
