import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

from test_client import OneShotServer

ROOT = Path(__file__).resolve().parents[2]
CLI_ROOT = ROOT / "skills" / "openplanet-control" / "scripts"
CLI = CLI_ROOT / "control.py"


class CliTests(unittest.TestCase):
    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, str(CLI), *args],
            cwd=CLI_ROOT,
            text=True,
            capture_output=True,
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        )

    def test_call_prints_response_and_returns_zero(self):
        server = OneShotServer(lambda request: {"v": 1, "id": request["id"], "ok": True, "result": {"performed": True}})
        result = self.run_cli("--port", str(server.port), "call", "component.action", "--id", "r1", "--arg", "component=save", "--assert", "result.performed=true")
        server.join()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["id"], "r1")
        self.assertEqual(server.received["args"]["component"], "save")

    def test_protocol_error_returns_nonzero(self):
        result = self.run_cli("--port", "1", "call", "ping", "--id", "r1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ERROR:", result.stderr)

    def test_remote_ok_false_returns_nonzero(self):
        server = OneShotServer(lambda request: {"v": 1, "id": request["id"], "ok": False, "error": {"code": "not_drawn", "message": "not drawn", "next": "open and retry"}})
        result = self.run_cli("--port", str(server.port), "call", "component.action", "--id", "r1")
        server.join()
        self.assertEqual(result.returncode, 3)
        self.assertIn('"code": "not_drawn"', result.stdout)

    def test_assertion_failure_returns_nonzero(self):
        server = OneShotServer(lambda request: {"v": 1, "id": request["id"], "ok": True, "result": {"performed": False}})
        result = self.run_cli("--port", str(server.port), "call", "component.action", "--id", "r1", "--assert", "result.performed=true")
        server.join()
        self.assertEqual(result.returncode, 4)
        self.assertIn("assertion failed", result.stderr)

    def test_action_macro_emits_fixed_semantic_route(self):
        server = OneShotServer(lambda request: {"v": 1, "id": request["id"], "ok": True, "result": {"performed": True, "forced": request["args"]["force"]}})
        result = self.run_cli("--port", str(server.port), "action", "save", "click", "--id", "r1", "--force")
        server.join()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(server.received["route"], "component.action")
        self.assertEqual(server.received["args"], {"component": "save", "action": "click", "force": True})

    def test_arbitrary_routes_are_rejected(self):
        result = self.run_cli("--port", "1", "call", "eval", "--id", "r1")
        self.assertEqual(result.returncode, 2)
        self.assertIn("invalid choice", result.stderr)


if __name__ == "__main__":
    unittest.main()
