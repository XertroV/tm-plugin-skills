from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATE = ROOT / "scripts" / "validate.py"


def _load_validate():
    spec = importlib.util.spec_from_file_location("validate_script", VALIDATE)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ValidationEntrypointTests(unittest.TestCase):
    def test_quick_profile_runs_repository_contracts(self) -> None:
        result = subprocess.run(
            [sys.executable, str(VALIDATE), "--profile", "quick"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("validation passed: quick", result.stdout)

    def test_zero_github_before_sha_skips_three_dot_diff(self) -> None:
        whitespace_base = _load_validate().whitespace_base
        self.assertIsNone(whitespace_base(None))
        self.assertIsNone(whitespace_base(""))
        self.assertIsNone(whitespace_base("0" * 40))
        self.assertEqual(
            whitespace_base("8f1383b1b23ca79a50c0d81bdfe1d988a842c531"),
            "8f1383b1b23ca79a50c0d81bdfe1d988a842c531",
        )

    def test_every_openai_prompt_invokes_its_own_skill(self) -> None:
        for skill in sorted((ROOT / "skills").iterdir()):
            if not skill.is_dir():
                continue
            metadata = (skill / "agents" / "openai.yaml").read_text(encoding="utf-8")
            self.assertIn(f"${skill.name}", metadata, skill.name)

    def test_promoted_skills_have_no_broken_local_markdown_links(self) -> None:
        promoted = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8"))["skills"]
        result = subprocess.run(
            [sys.executable, str(VALIDATE), "--check", "skill-links"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(promoted), 6)


if __name__ == "__main__":
    unittest.main()
