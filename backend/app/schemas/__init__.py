"""Contratos Pydantic oficiais do Atlas.

Preserva o contrato histórico ``from app.schemas import ...`` enquanto a
implementação consolidada reside neste pacote.
"""

from .legacy import *  # noqa: F401,F403
from .legacy import __dict__ as _legacy_symbols

__all__ = sorted(
    name
    for name in _legacy_symbols
    if not name.startswith("_")
)

del _legacy_symbols
