from sqlalchemy import select
from sqlalchemy.orm import Session

from .config import get_settings
from .models import Company, Membership, User, new_id
from .security import hash_password

settings = get_settings()


def bootstrap(db: Session) -> None:
    admin_email = settings.atlas_bootstrap_admin_email.strip().lower()

    existing_user = db.scalar(
        select(User).where(User.email == admin_email)
    )
    if existing_user is not None:
        return

    company = Company(
        id=new_id("company"),
        tenant_id=new_id("tenant"),
        name=settings.atlas_bootstrap_company_name,
        document="",
        status="active",
        subscription_plan="enterprise",
    )

    user = User(
        id=new_id("user"),
        name="Administrador Atlas",
        email=admin_email,
        password_hash=hash_password(
            settings.atlas_bootstrap_admin_password
        ),
        active=True,
        email_verified=True,
        failed_login_attempts=0,
        locked_until=None,
        password_changed_at=None,
    )

    db.add_all([company, user])
    db.flush()

    db.add(
        Membership(
            id=new_id("membership"),
            user_id=user.id,
            company_id=company.id,
            role="companyAdministrator",
            permission_overrides={},
            farm_ids=[],
            active=True,
        )
    )
    db.commit()
