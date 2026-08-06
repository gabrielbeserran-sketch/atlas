"""Dependências de autenticação compartilhadas pelos routers de domínio.

Este módulo fornece nomes estáveis para a camada HTTP sem duplicar a lógica de
segurança. A fonte oficial continua sendo ``app.authz``.
"""

from __future__ import annotations

from fastapi import Depends

from .authz import Principal, get_principal
from .models import User


def get_current_context(
    principal: Principal = Depends(get_principal),
) -> Principal:
    """Retorna o contexto autenticado oficial da requisição."""

    return principal


def get_current_user(
    principal: Principal = Depends(get_principal),
) -> User:
    """Retorna o usuário autenticado preservando o contrato legado."""

    return principal.user
