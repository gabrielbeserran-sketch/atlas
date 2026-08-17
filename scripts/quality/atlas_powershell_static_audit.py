from __future__ import annotations

import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "scripts"


def strip_comments_and_strings(source: str) -> str:
    result: list[str] = []
    in_single = False
    in_double = False
    escaped = False
    i = 0

    while i < len(source):
        ch = source[i]

        if escaped:
            result.append(" ")
            escaped = False
            i += 1
            continue

        if ch == "`" and (in_single or in_double):
            escaped = True
            result.append(" ")
            i += 1
            continue

        if not in_single and not in_double and ch == "#":
            while i < len(source) and source[i] != "\n":
                result.append(" ")
                i += 1
            continue

        if ch == "'" and not in_double:
            in_single = not in_single
            result.append(" ")
            i += 1
            continue

        if ch == '"' and not in_single:
            in_double = not in_double
            result.append(" ")
            i += 1
            continue

        result.append(" " if (in_single or in_double) else ch)
        i += 1

    return "".join(result)


def delimiter_errors(path: Path, source: str) -> list[str]:
    cleaned = strip_comments_and_strings(source)
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    errors: list[str] = []

    for index, ch in enumerate(cleaned):
        if ch in "([{":
            stack.append((ch, index))
        elif ch in ")]}":
            if not stack or stack[-1][0] != pairs[ch]:
                line = cleaned.count("\n", 0, index) + 1
                errors.append(
                    f"{path}: delimitador inesperado '{ch}' na linha {line}"
                )
                continue
            stack.pop()

    for ch, index in stack:
        line = cleaned.count("\n", 0, index) + 1
        errors.append(
            f"{path}: delimitador '{ch}' sem fechamento, linha {line}"
        )

    return errors


def main() -> int:
    errors: list[str] = []
    checked = 0

    for path in sorted(SCRIPTS.rglob("*.ps1")):
        checked += 1
        source = path.read_text(encoding="utf-8", errors="ignore")
        relative = path.relative_to(ROOT)

        for line_number, line in enumerate(source.splitlines(), start=1):
            if re.match(r"^\s*\.[A-Za-z_][A-Za-z0-9_]*\s*\(", line):
                errors.append(
                    f"{relative}:{line_number}: "
                    "método iniciado em nova linha sem continuação"
                )

        if re.search(r"-c\s+@['\"]", source):
            errors.append(
                f"{relative}: Python multiline embutido em PowerShell"
            )

        errors.extend(delimiter_errors(relative, source))

    result = {
        "status": "FAIL" if errors else "OK",
        "powershell_files_checked": checked,
        "errors": errors,
    }

    (ROOT / "ATLAS_POWERSHELL_STATIC_AUDIT.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(json.dumps(result, ensure_ascii=False, indent=2))
    print(
        "\nATLAS POWERSHELL STATIC AUDIT:",
        "FAIL" if errors else "OK",
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
