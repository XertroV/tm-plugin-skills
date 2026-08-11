from __future__ import annotations

import shutil
import os
import subprocess
import tempfile
import unittest
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "openplanet-control",
    "openplanet-dev",
    "openplanet-init",
    "openplanet-lifecycle",
    "openplanet-reviewer",
    "openplanet-visual",
}


class InstallSmokeTests(unittest.TestCase):
    def test_local_copy_install_has_exact_skill_set_and_integrity(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            install = Path(temporary) / "skills"
            shutil.copytree(ROOT / "skills", install)
            self.assertEqual({path.name for path in install.iterdir() if path.is_dir()}, EXPECTED)
            for name in EXPECTED:
                source = (ROOT / "skills" / name / "SKILL.md").read_bytes()
                copied = (install / name / "SKILL.md").read_bytes()
                self.assertEqual(copied, source)

    def test_pinned_cli_installs_exact_six_skills_in_isolated_home(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            temporary_path = Path(temporary)
            home = temporary_path / "home"
            environment = {
                **os.environ,
                "HOME": str(home),
                "XDG_CONFIG_HOME": str(temporary_path / "config"),
                "XDG_CACHE_HOME": str(temporary_path / "cache"),
                "npm_config_cache": str(temporary_path / "npm-cache"),
                "npm_config_userconfig": str(temporary_path / "npmrc"),
                "NPM_CONFIG_GLOBALCONFIG": str(temporary_path / "global-npmrc"),
            }
            command = ["npx", "--yes", "skills@1.4.1", "add", "."]
            for name in sorted(EXPECTED):
                command += ["--skill", name]
            command += ["--yes", "--global"]
            result = subprocess.run(
                command, cwd=ROOT, env=environment, text=True, capture_output=True
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            install = home / ".agents" / "skills"
            self.assertEqual(
                {path.name for path in install.iterdir() if path.is_dir()}, EXPECTED
            )
            for name in EXPECTED:
                self.assertEqual(
                    (install / name / "SKILL.md").read_bytes(),
                    (ROOT / "skills" / name / "SKILL.md").read_bytes(),
                )

    def test_pinned_cli_discovers_exact_six_skills(self) -> None:
        result = subprocess.run(
            ["npx", "--yes", "skills@1.4.1", "add", ".", "--list"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        plain = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", result.stdout)
        self.assertIn("Found 6 skills", plain)
        for name in EXPECTED:
            self.assertIn(name, plain)


if __name__ == "__main__":
    unittest.main()
