from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select

from app.config import get_settings
from app.database import SessionLocal
from app.models import Company, Membership, User, new_id
from app.security import hash_password


def _find_company(db, *, name: str) -> Company | None:
    return db.scalar(
        select(Company)
        .where(Company.name == name)
        .order_by(Company.id.asc())
    )


def main() -> int:
    settings = get_settings()

    if not settings.atlas_provision_admin_once:
        print("ATLAS ADMIN PROVISION: desabilitado")
        return 0

    if settings.atlas_env not in {"staging", "production"}:
        print(
            "ATLAS ADMIN PROVISION: ignorado fora de staging/production"
        )
        return 0

    email = settings.atlas_provision_admin_email.strip().lower()
    company_name = settings.atlas_provision_company_name.strip()

    with SessionLocal() as db:
        user = db.scalar(
            select(User).where(User.email == email)
        )

        if user is not None:
            memberships = list(
                db.scalars(
                    select(Membership).where(
                        Membership.user_id == user.id,
                        Membership.active.is_(True),
                    )
                ).all()
            )

            if memberships:
                # Idempotência: se o administrador já tem vínculo ativo,
                # não altera senha em redeploys acidentais.
                user.active = True
                user.email_verified = True
                user.failed_login_attempts = 0
                user.locked_until = None
                db.commit()

                print(
                    "ATLAS ADMIN PROVISION: administrador já provisionado; "
                    f"nenhuma senha alterada (email={email})"
                )
                return 0

        company = _find_company(db, name=company_name)
        if company is None:
            company = Company(
                id=new_id("company"),
                tenant_id=new_id("tenant"),
                name=company_name,
                document="",
                status="active",
                subscription_plan="enterprise",
            )
            db.add(company)
            db.flush()
            print(
                "ATLAS ADMIN PROVISION: empresa criada "
                f"(company_id={company.id})"
            )

        if user is None:
            user = User(
                id=new_id("user"),
                name="Administrador Atlas",
                email=email,
                password_hash=hash_password(
                    settings.atlas_provision_admin_password
                ),
                active=True,
                email_verified=True,
                failed_login_attempts=0,
                locked_until=None,
                password_changed_at=datetime.now(timezone.utc),
            )
            db.add(user)
            db.flush()
            print(
                "ATLAS ADMIN PROVISION: usuário administrativo criado "
                f"(user_id={user.id}, email={email})"
            )
        else:
            # Usuário pode ter vindo de um cadastro público incompleto.
            # Nesse caso, o provisionamento explícito completa a conta e
            # aplica a senha fornecida no evento one-shot.
            user.password_hash = hash_password(
                settings.atlas_provision_admin_password
            )
            user.active = True
            user.email_verified = True
            user.failed_login_attempts = 0
            user.locked_until = None
            user.password_changed_at = datetime.now(timezone.utc)
            print(
                "ATLAS ADMIN PROVISION: usuário existente sem vínculo "
                "administrativo foi regularizado"
            )

        membership = db.scalar(
            select(Membership).where(
                Membership.user_id == user.id,
                Membership.company_id == company.id,
            )
        )

        if membership is None:
            membership = Membership(
                id=new_id("membership"),
                user_id=user.id,
                company_id=company.id,
                role="companyAdministrator",
                permission_overrides={},
                farm_ids=[],
                active=True,
            )
            db.add(membership)
        else:
            membership.role = "companyAdministrator"
            membership.active = True

        db.commit()

        print(
            "ATLAS ADMIN PROVISION: APROVADO "
            f"(email={email}, company={company.name}, "
            "role=companyAdministrator)"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
