from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
import shutil
import copy
import importlib.util
import os
from pathlib import Path

import jsonschema

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts" / "record-gallery-evidence.py"
SCHEMA = ROOT / "evidence" / "gallery-evidence.schema.json"
SPEC = importlib.util.spec_from_file_location(
    "validate_gallery_evidence", ROOT / "evidence" / "validate_gallery_evidence.py"
)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
EvidenceError = MODULE.EvidenceError
validate_semantics = MODULE.validate_semantics


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
            self.assertEqual(record["static"]["lsp"], shutil.which("openplanet-lsp") is not None)
            matrix = json.loads(
                (ROOT / "prototypes" / "issue-12-gallery" / "screenshot-matrix.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(len(record["cases"]), len(matrix["required_cases"]))
            self.assertTrue(all(case["status"] == "pending" for case in record["cases"]))
            self.assertTrue(SCHEMA.is_file())
            jsonschema.validate(record, json.loads(SCHEMA.read_text(encoding="utf-8")))
            validate_semantics(record)

            contradictions = []
            stable_pending = copy.deepcopy(record)
            stable_pending["evidence_level"] = "stable"
            contradictions.append(stable_pending)
            complete_false = copy.deepcopy(record)
            complete_false["live"]["status"] = "complete"
            contradictions.append(complete_false)
            approved_without_artifacts = copy.deepcopy(record)
            approved_without_artifacts["cases"][0]["status"] = "approved"
            contradictions.append(approved_without_artifacts)
            for contradiction in contradictions:
                with self.assertRaises(EvidenceError):
                    validate_semantics(contradiction)

    def test_runner_refuses_to_claim_live_without_runtime_inputs(self) -> None:
        result = subprocess.run(
            [sys.executable, str(RUNNER), "--output", "/dev/null"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("use --static-only", result.stdout + result.stderr)

    def test_static_runner_accepts_explicit_archive_source_identity(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "evidence.json"
            environment = {**os.environ, "GALLERY_SOURCE_COMMIT": "archive-export-2026-08-12"}
            result = subprocess.run(
                [sys.executable, str(RUNNER), "--static-only", "--output", str(output)],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            record = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(record["commit"], "archive-export-2026-08-12")
            validate_semantics(record)


if __name__ == "__main__":
    unittest.main()
