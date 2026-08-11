from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts" / "record-gallery-evidence.py"
SCHEMA = ROOT / "evidence" / "gallery-evidence.schema.json"


class GalleryEvidenceTests(unittest.TestCase):
    def test_static_runner_records_truthful_pending_live_gates(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "evidence.json"
            result = subprocess.run(
                [sys.executable, str(RUNNER), "--static-only", "--output", str(output)],
                cwd=ROOT,
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            record = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(record["schema_version"], 1)
            self.assertEqual(record["component"], "VisualRecipeGallery")
            self.assertEqual(record["evidence_level"], "candidate-static-only")
            self.assertEqual(record["live"]["status"], "pending")
            self.assertFalse(record["live"]["runtime_load"])
            self.assertFalse(record["live"]["native_tests"])
            self.assertFalse(record["live"]["screenshots"])
            self.assertEqual(len(record["cases"]), 17)
            self.assertTrue(all(case["status"] == "pending" for case in record["cases"]))
            self.assertTrue(SCHEMA.is_file())

    def test_runner_refuses_to_claim_live_without_runtime_inputs(self) -> None:
        result = subprocess.run(
            [sys.executable, str(RUNNER), "--output", "/dev/null"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("use --static-only", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
