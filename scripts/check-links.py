#!/usr/bin/env python3
"""Проверка внутренних ссылок и картинок в docs/.

Запуск: python scripts/check-links.py
Код возврата 1, если есть битые ссылки.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"

# [text](target) и ![alt](target)
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "tel:", "#", "ftp://")


def resolve(md_file: Path, target: str) -> Path | None:
    target = target.split("#", 1)[0].split("?", 1)[0]
    if not target:
        return None
    if target.startswith(SKIP_PREFIXES):
        return None
    if target.startswith("/"):
        candidate = DOCS / target.lstrip("/")
    else:
        candidate = md_file.parent / target
    candidate = candidate.resolve()
    if candidate.is_dir():
        candidate = candidate / "index.md"
    return candidate


def main() -> int:
    if not DOCS.is_dir():
        print(f"Нет папки {DOCS}", file=sys.stderr)
        return 1

    missing: list[tuple[Path, str]] = []
    checked = 0

    for md in sorted(DOCS.rglob("*.md")):
        text = md.read_text(encoding="utf-8")
        # убираем код-блоки, чтобы не ловить примеры
        text = re.sub(r"```.*?```", "", text, flags=re.S)
        for raw in LINK_RE.findall(text):
            if raw.startswith(SKIP_PREFIXES):
                continue
            checked += 1
            resolved = resolve(md, raw)
            if resolved is not None and not resolved.exists():
                missing.append((md.relative_to(ROOT), raw))

    print(f"Проверено ссылок: {checked}")
    if missing:
        print(f"Битых ссылок: {len(missing)}\n", file=sys.stderr)
        for src, target in missing:
            print(f"  {src}: {target}", file=sys.stderr)
        return 1

    print("Битых ссылок нет.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
