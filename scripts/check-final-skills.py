#!/usr/bin/env python3
"""Validate the five final Openplanet workflow skills."""

from __future__ import annotations

import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
FINAL_SKILLS = (
    "openplanet-init",
    "openplanet-lifecycle",
    "openplanet-dev",
    "openplanet-visual",
    "openplanet-control",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"final skill validation failed: {message}")


def validate_common(name: str) -> tuple[str, dict]:
    directory = ROOT / "skills" / name
    skill = directory / "SKILL.md"
    require(skill.is_file(), f"missing {name}/SKILL.md")
    content = skill.read_text()
    match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
    require(match is not None, f"{name}: invalid frontmatter")
    assert match is not None
    frontmatter = yaml.safe_load(match.group(1))
    require(frontmatter.get("name") == name, f"{name}: name mismatch")
    description = frontmatter.get("description")
    require(isinstance(description, str) and description.startswith("Use when "), f"{name}: trigger not front-loaded")
    require(frontmatter.get("license") == "CC0-1.0 OR Unlicense", f"{name}: license drift")
    require((directory / "agents" / "openai.yaml").is_file(), f"{name}: missing OpenAI metadata")
    for relative in re.findall(r"\[[^]]+\]\((references/[^)]+|templates/[^)]+)\)", content):
        require((directory / relative).is_file(), f"{name}: missing linked file {relative}")
    return content, frontmatter


def main() -> None:
    init, _ = validate_common("openplanet-init")
    for phrase in (
        "tracked initialization brief",
        "first-load evidence",
        "explicit runtime blocker",
        "local-only",
        ".git/info/exclude",
        "Never write secrets",
        "controls_other_plugins",
    ):
        require(phrase in init, f"openplanet-init omits {phrase}")
    init_dir = ROOT / "skills" / "openplanet-init"
    require((init_dir / "templates" / "INITIALIZATION-BRIEF.md").is_file(), "init brief template missing")
    require((init_dir / "references" / "onboarding-and-local-state.md").is_file(), "init onboarding reference missing")

    for name in FINAL_SKILLS[1:]:
        validate_common(name)

    lifecycle = (ROOT / "skills" / "openplanet-lifecycle" / "SKILL.md").read_text()
    for phrase in ("exact staged bytes", "fresh post-action log window", "dependent", "manual", "truthful blocker"):
        require(phrase in lifecycle, f"openplanet-lifecycle omits {phrase}")

    dev = (ROOT / "skills" / "openplanet-dev" / "SKILL.md").read_text()
    for phrase in ("RED", "Feature_Test.as", "Skillpack Demos", "ordinary exports", "openplanet-lsp"):
        require(phrase in dev, f"openplanet-dev omits {phrase}")

    visual = (ROOT / "skills" / "openplanet-visual" / "SKILL.md").read_text()
    for phrase in ("Theme-preserving ImGui", "stable ID", "one authoritative gallery", "fresh screenshot", "startnew", "candidate-static-only"):
        require(phrase in visual, f"openplanet-visual omits {phrase}")

    control = (ROOT / "skills" / "openplanet-control" / "SKILL.md").read_text()
    for phrase in ("#if DEV", "127.0.0.1", "length-prefixed", "newline-delimited", "force", "completed render epoch", "single-flight"):
        require(phrase in control, f"openplanet-control omits {phrase}")

    print("final skill validation passed (five final skills)")


if __name__ == "__main__":
    main()
