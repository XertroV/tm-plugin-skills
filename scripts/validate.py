#!/usr/bin/env python3
"""Authoritative local validation entrypoint for tm-plugin-skills."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCAL_LINK = re.compile(r"\[[^]]*]\(([^)]+)\)")
QUICK_COMMANDS = (
    (sys.executable, "scripts/check-final-skills.py"),
    (sys.executable, "scripts/check-reviewer-skill.py"),
    (sys.executable, "scripts/check-packaging.py"),
    (sys.executable, "scripts/check-demo-menu-contract.py"),
    (sys.executable, "tests/test_evidence_records.py", "-v"),
    (sys.executable, "tests/test_install_smoke.py", "-v"),
    (sys.executable, "-m", "unittest", "discover", "-s", "tests/semantic_control", "-v"),
    (sys.executable, "tests/test_lifecycle_bridge_contract.py", "-v"),
)


def fail(message: str) -> None:
    raise SystemExit(f"validation failed: {message}")


def check_skill_links() -> None:
    for markdown in sorted((ROOT / "skills").rglob("*.md")):
        text = markdown.read_text(encoding="utf-8")
        for raw_target in LOCAL_LINK.findall(text):
            target = raw_target.split("#", 1)[0]
            if not target or "://" in target or target.startswith("mailto:"):
                continue
            if not (markdown.parent / target).resolve().exists():
                fail(f"broken local link {raw_target!r} in {markdown.relative_to(ROOT)}")
    print("skill link validation passed")


def run(command: tuple[str, ...]) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", choices=("quick",), default="quick")
    parser.add_argument("--check", choices=("skill-links",))
    args = parser.parse_args()
    if args.check == "skill-links":
        check_skill_links()
        return
    for command in QUICK_COMMANDS:
        run(command)
    check_skill_links()
    base = os.environ.get("VALIDATION_BASE_SHA")
    if base:
        run(("git", "diff", "--check", f"{base}...HEAD"))
    else:
        run(("git", "diff", "--check"))
    print(f"validation passed: {args.profile}")


if __name__ == "__main__":
    main()
