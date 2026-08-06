"""Modelos SQLAlchemy oficiais do Atlas.

Este pacote preserva o contrato histórico ``from app.models import ...``
enquanto organiza a implementação consolidada em módulos internos.
"""

from .legacy import *  # noqa: F401,F403

# Exporta todos os símbolos públicos definidos no módulo consolidado.
from .legacy import __dict__ as _legacy_symbols

__all__ = sorted(
    name
    for name in _legacy_symbols
    if not name.startswith("_")
)

del _legacy_symbols
