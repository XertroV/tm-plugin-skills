#!/usr/bin/env python3
"""Repository-specific packaging gates for promoted skills."""

from __future__ import annotations

import json
import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"packaging validation failed: {message}")


def main() -> None:
    require(not (ROOT / "SKILL.md").exists(), "root SKILL.md shadows promoted skills")
    package = json.loads((ROOT / "package.json").read_text())
    plugin = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text())
    marketplace = json.loads((ROOT / ".claude-plugin" / "marketplace.json").read_text())
    require(package.get("private") is True, "package.json must remain private")
    require(package["version"] == plugin["version"], "package/plugin version drift")
    require(marketplace["plugins"][0]["version"] == package["version"], "marketplace version drift")
    require(package["license"] == plugin["license"] == "CC0-1.0 OR Unlicense", "license metadata drift")
    require((ROOT / "LICENSES" / "CC0-1.0.txt").is_file(), "CC0 full text missing")
    require((ROOT / "LICENSES" / "Unlicense.txt").is_file(), "Unlicense full text missing")

    skill_dirs = sorted(p.parent.name for p in (ROOT / "skills").glob("*/SKILL.md"))
    plugin_dirs = sorted(Path(entry).name for entry in plugin["skills"])
    readme = (ROOT / "README.md").read_text()
    readme_dirs = sorted(re.findall(r"\[`([a-z0-9-]+)`\]\(skills/\1/SKILL\.md\)", readme))
    require(skill_dirs == plugin_dirs == readme_dirs, "filesystem/plugin/README promotion sets differ")

    name_re = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
    for name in skill_dirs:
        skill_dir = ROOT / "skills" / name
        content = (skill_dir / "SKILL.md").read_text()
        match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
        require(match is not None, f"{name}: invalid frontmatter delimiters")
        assert match is not None
        frontmatter = yaml.safe_load(match.group(1))
        require(name_re.fullmatch(name) is not None and len(name) <= 64, f"{name}: invalid Agent Skills name")
        require(frontmatter.get("name") == name, f"{name}: frontmatter name mismatch")
        description = frontmatter.get("description")
        require(isinstance(description, str) and 1 <= len(description) <= 1024, f"{name}: invalid description")
        compatibility = frontmatter.get("compatibility", "")
        require(isinstance(compatibility, str) and len(compatibility) <= 500, f"{name}: invalid compatibility")
        metadata = frontmatter.get("metadata", {})
        require(isinstance(metadata, dict) and all(isinstance(k, str) and isinstance(v, str) for k, v in metadata.items()), f"{name}: metadata must be string-to-string")
        openai = yaml.safe_load((skill_dir / "agents" / "openai.yaml").read_text())
        disabled = frontmatter.get("disable-model-invocation") is True
        implicit = openai.get("policy", {}).get("allow_implicit_invocation", True)
        require(implicit is (not disabled), f"{name}: invocation metadata drift")
        for relative in re.findall(r"\[[^]]+\]\((references/[^)]+)\)", content):
            require((skill_dir / relative).is_file(), f"{name}: missing reference {relative}")

    print(f"packaging validation passed ({len(skill_dirs)} promoted skill)")


if __name__ == "__main__":
    main()
