from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATE = ROOT / "scripts" / "validate.py"


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
