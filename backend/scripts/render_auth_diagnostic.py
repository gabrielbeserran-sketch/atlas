from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select

from app.config import get_settings
from app.database import SessionLocal
from app.models import Membership, User
from app.security import verify_password


def _is_locked(user: User) -> bool:
    if user.locked_until is None:
        return False

    locked_until = user.locked_until
    if locked_until.tzinfo is None:
        locked_until = locked_until.replace(tzinfo=timezone.utc)

    return locked_until > datetime.now(timezone.utc)


def main() -> int:
    settings = get_settings()

    if not settings.atlas_auth_diagnostic_enabled:
        print("ATLAS AUTH DIAGNOSTIC: desabilitado")
        return 0

    email = settings.atlas_auth_diagnostic_email.strip().lower()
    candidate_password = settings.atlas_auth_diagnostic_password

    with SessionLocal() as db:
        user = db.scalar(select(User).where(User.email == email))

        if user is None:
            print("ATLAS AUTH DIAGNOSTIC: RESULT")
            print(" - user_found=false")
            print(" - active=false")
            print(" - email_verified=false")
            print(" - active_memberships=0")
            print(" - locked=false")
            print(" - failed_login_attempts=0")
            print(" - password_match=false")
            print(" - roles=(none)")
            return 0

        memberships = list(
            db.scalars(
                select(Membership).where(
                    Membership.user_id == user.id,
                    Membership.active.is_(True),
                )
            ).all()
        )

        password_match = verify_password(
            candidate_password,
            user.password_hash,
        )

        roles = sorted(
            {
                str(membership.role)
                for membership in memberships
                if membership.role
            }
        )

        print("ATLAS AUTH DIAGNOSTIC: RESULT")
        print(" - user_found=true")
        print(f" - active={str(bool(user.active)).lower()}")
        print(
            f" - email_verified={str(bool(user.email_verified)).lower()}"
        )
        print(f" - active_memberships={len(memberships)}")
        print(f" - locked={str(_is_locked(user)).lower()}")
        print(
            " - failed_login_attempts="
            f"{int(user.failed_login_attempts or 0)}"
        )
        print(
            f" - password_match={str(bool(password_match)).lower()}"
        )
        print(
            " - roles="
            + (",".join(roles) if roles else "(none)")
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
