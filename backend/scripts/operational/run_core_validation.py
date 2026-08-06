from __future__ import annotations

import argparse
import json

from app.database import SessionLocal
from app.services.core_livestock_validation import ValidationContext, validate_all


def main() -> int:
    parser = argparse.ArgumentParser(description="Valida o núcleo operacional de uma fazenda Atlas.")
    parser.add_argument("--company-id", required=True)
    parser.add_argument("--farm-id", required=True)
    parser.add_argument("--fail-on-issues", action="store_true")
    args = parser.parse_args()
    with SessionLocal() as db:
        result = validate_all(db, ValidationContext(company_id=args.company_id, farm_id=args.farm_id))
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 1 if args.fail_on_issues and result["issue_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
