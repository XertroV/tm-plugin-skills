#!/usr/bin/env python3
"""Validate the promoted openplanet-reviewer skill and its evidence contract."""

from __future__ import annotations

import re
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SKILL_DIR = ROOT / "skills" / "openplanet-reviewer"
SKILL_MD = SKILL_DIR / "SKILL.md"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"reviewer validation failed: {message}")


def main() -> None:
    content = SKILL_MD.read_text()
    require(content.startswith("---\n"), "SKILL.md frontmatter must start at byte 0")
    match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
    require(match is not None, "SKILL.md frontmatter is not closed")
    assert match is not None
    frontmatter = yaml.safe_load(match.group(1))
    require(isinstance(frontmatter, dict), "frontmatter must be a mapping")
    require(frontmatter.get("name") == SKILL_DIR.name, "name must match directory")
    description = frontmatter.get("description")
    require(isinstance(description, str) and 1 <= len(description) <= 1024, "invalid description")
    require(description.startswith("Use when adversarially reviewing"), "trigger must be front-loaded")
    require(frontmatter.get("license") == "CC0-1.0 OR Unlicense", "license drift")
    require(len(content) <= 100_000, "SKILL.md exceeds portable limit")

    refs = re.findall(r"\$\{CLAUDE_SKILL_DIR\}/([^`\s]+)", content)
    require(bool(refs), "SKILL.md must progressively disclose references")
    for relative in refs:
        require((SKILL_DIR / relative).is_file(), f"missing linked file: {relative}")

    openai = yaml.safe_load((SKILL_DIR / "agents" / "openai.yaml").read_text())
    require(openai["policy"]["allow_implicit_invocation"] is True, "invocation policy drift")
    plugin = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text())
    require(plugin["version"] == frontmatter["metadata"]["version"], "plugin/skill version drift")
    require(plugin["skills"] == ["./skills/openplanet-reviewer"], "plugin promotion list drift")

    manifest = (ROOT / "docs" / "skill-manifest.md").read_text()
    workflow = (ROOT / "docs" / "reviewer-workflow.md").read_text()
    ledger = (ROOT / "docs" / "reviewer-failure-ledger.md").read_text()
    evidence = (ROOT / "docs" / "research" / "issue-13-adversarial-review-evidence.md").read_text()
    probe = (ROOT / "prototypes" / "issue-13-ui-exception-probe" / "Main.as").read_text()

    require("`openplanet-reviewer`" in manifest, "manifest omits reviewer")
    require("## Evidence grades" in workflow and "## Output skeleton" in workflow, "workflow contract incomplete")
    for failure_class in (
        "UI callback failure containment",
        "Transactional mutation restoration",
        "Async terminal-state completeness",
        "Mutation-result truthfulness",
        "Network architecture mismatch",
    ):
        require(failure_class in ledger, f"ledger omits {failure_class}")
    require("Unrolling dangling script UI stack" in evidence, "live UI evidence missing")
    require("startnew(CoroutineFunc(ThrowProbeIsolated))" in probe, "probe lacks isolated boundary")
    require('ThrowProbe("inline render callback")' in probe, "probe lacks inline failure path")

    print("openplanet-reviewer validation passed")


if __name__ == "__main__":
    main()
