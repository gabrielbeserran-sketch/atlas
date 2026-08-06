from __future__ import annotations

from collections import Counter
from pathlib import Path
import sys

# Permite executar este arquivo diretamente com:
#   python scripts/quality/check_openapi.py
# e também como módulo com:
#   python -m scripts.quality.check_openapi
BACKEND_ROOT = Path(__file__).resolve().parents[2]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.main import app


HTTP_METHODS = {"get", "post", "put", "patch", "delete", "options", "head"}


def main() -> int:
    schema = app.openapi()
    paths = schema.get("paths", {})
    operation_ids: list[str] = []
    operations = 0

    for path_item in paths.values():
        for method, operation in path_item.items():
            if method.lower() not in HTTP_METHODS:
                continue

            operations += 1
            operation_id = operation.get("operationId")
            if operation_id:
                operation_ids.append(operation_id)

    duplicates = sorted(
        operation_id
        for operation_id, count in Counter(operation_ids).items()
        if count > 1
    )

    if duplicates:
        print("Operation IDs duplicados:")
        for operation_id in duplicates:
            print(f"- {operation_id}")
        return 1

    print(
        "OpenAPI aprovado: "
        f"{len(paths)} caminhos, {operations} operações e "
        f"{len(operation_ids)} operationIds únicos."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
