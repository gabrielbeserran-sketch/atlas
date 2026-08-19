from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select

from app.config import get_settings
from app.database import SessionLocal
from app.models import Membership, User
from app.security import hash_password, verify_password


def main() -> int:
    settings = get_settings()

    if not settings.atlas_reset_admin_password_once:
        print("ATLAS ADMIN PASSWORD RESET: desabilitado")
        return 0

    if settings.atlas_env not in {"staging", "production"}:
        raise RuntimeError(
            "ATLAS ADMIN PASSWORD RESET só pode rodar em staging/production"
        )

    email = settings.atlas_reset_admin_email.strip().lower()
    new_password = settings.atlas_reset_admin_password

    with SessionLocal() as db:
        user = db.scalar(select(User).where(User.email == email))

        if user is None:
            raise RuntimeError(
                "ATLAS ADMIN PASSWORD RESET: usuário não encontrado"
            )

        memberships = list(
            db.scalars(
                select(Membership).where(
                    Membership.user_id == user.id,
                    Membership.active.is_(True),
                )
            ).all()
        )

        admin_memberships = [
            membership
            for membership in memberships
            if str(membership.role) == "companyAdministrator"
        ]

        if not admin_memberships:
            raise RuntimeError(
                "ATLAS ADMIN PASSWORD RESET: usuário existe, mas não possui "
                "membership companyAdministrator ativa"
            )

        user.password_hash = hash_password(new_password)
        user.active = True
        user.email_verified = True
        user.failed_login_attempts = 0
        user.locked_until = None
        user.password_changed_at = datetime.now(timezone.utc)

        db.flush()

        if not verify_password(new_password, user.password_hash):
            raise RuntimeError(
                "ATLAS ADMIN PASSWORD RESET: verificação do novo hash falhou"
            )

        db.commit()

        print(
            "ATLAS ADMIN PASSWORD RESET: APROVADO "
            f"(email={email}, admin_memberships={len(admin_memberships)}, "
            "post_reset_password_match=true)"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
