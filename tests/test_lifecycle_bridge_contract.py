#!/usr/bin/env python3
import json
import importlib.util
import subprocess
import socket
import threading
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "prototypes" / "lifecycle-bridge-contract" / "lifecycle_bridge.py"
SPEC = importlib.util.spec_from_file_location("lifecycle_bridge", MODEL)
assert SPEC is not None and SPEC.loader is not None
lifecycle_bridge = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = lifecycle_bridge
SPEC.loader.exec_module(lifecycle_bridge)


class OneShotLifecycleServer:
    def __init__(self, response: bytes):
        self.response = response
        self.listener = socket.socket()
        self.listener.bind(("127.0.0.1", 0))
        self.listener.listen(1)
        self.port = self.listener.getsockname()[1]
        self.thread = threading.Thread(target=self.run)
        self.thread.start()

    def run(self):
        try:
            conn, _ = self.listener.accept()
            with conn:
                while not conn.recv(4096).endswith(b"\n"):
                    pass
                conn.sendall(self.response)
        finally:
            self.listener.close()

    def join(self):
        self.thread.join(timeout=2)
        if self.thread.is_alive():
            raise AssertionError("lifecycle server did not stop")


class ModelSession:
    """Public seam: one JSON request and response per newline."""

    def __init__(self):
        self.proc = subprocess.Popen(
            [sys.executable, str(MODEL), "model"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.next_id = 1

    def request(self, route, data=None):
        request_id = f"t{self.next_id}"
        self.next_id += 1
        request = {"v": 1, "id": request_id, "route": route, "data": data or {}}
        self.proc.stdin.write(json.dumps(request, separators=(",", ":")) + "\n")
        self.proc.stdin.flush()
        line = self.proc.stdout.readline()
        self.assert_process_alive(line)
        response = json.loads(line)
        if response.get("id") != request_id or response.get("route") != route:
            raise AssertionError(f"response correlation mismatch: {response!r}")
        return response

    def assert_process_alive(self, line):
        if not line:
            stderr = self.proc.stderr.read()
            raise AssertionError(f"model exited without a response: {stderr}")

    def close(self):
        if self.proc.poll() is None:
            self.proc.stdin.close()
            self.proc.wait(timeout=2)
        stderr = self.proc.stderr.read()
        self.proc.stdout.close()
        self.proc.stderr.close()
        if self.proc.returncode != 0:
            raise AssertionError(f"model exited {self.proc.returncode}: {stderr}")


class LifecycleBridgeContractTests(unittest.TestCase):
    def setUp(self):
        self.model = ModelSession()
        configured = self.model.request("configure", {
            "plugins": [
                {"id": "Provider", "dependencies": [], "path": "/plugins/Provider", "source": "user", "type": "folder", "version": "1"},
                {"id": "Direct", "dependencies": ["Provider"], "path": "/plugins/Direct", "source": "user", "type": "folder", "version": "1"},
                {"id": "Transitive", "dependencies": ["Direct"], "path": "/plugins/Transitive", "source": "user", "type": "folder", "version": "1"},
                {"id": "Sibling", "dependencies": ["Provider"], "path": "/plugins/Sibling", "source": "user", "type": "folder", "version": "1"},
                {"id": "Disabled", "dependencies": ["Provider"], "path": "/plugins/Disabled", "source": "user", "type": "folder", "version": "1", "loaded": False},
            ]
        })
        self.assertTrue(configured["ok"])

    def tearDown(self):
        self.model.close()

    def test_failed_provider_retry_retains_original_reverse_dependent_closure(self):
        failed = self.model.request("reload", {"id": "Provider", "target_load_ok": False})
        self.assertFalse(failed["ok"])
        self.assertEqual("target_load_failed", failed["error"]["code"])
        self.assertEqual(["Direct", "Sibling", "Transitive"], failed["data"]["snapshot"]["ids"])
        self.assertEqual([], failed["data"]["restored"])

        retry = self.model.request("reload", {"id": "Provider", "target_load_ok": True})
        self.assertTrue(retry["ok"])
        self.assertTrue(retry["data"]["snapshot_reused"])
        self.assertEqual(["Direct", "Sibling", "Transitive"], retry["data"]["restored"])
        self.assertNotIn("Disabled", retry["data"]["restored"])

    def test_successful_restore_is_topological_not_lexical(self):
        self.model.request("configure", {"plugins": [
            {"id": "Root", "dependencies": [], "path": "/plugins/Root", "source": "user", "type": "folder", "version": "1"},
            {"id": "AlphaConsumer", "dependencies": ["ZuluProvider"], "path": "/plugins/AlphaConsumer", "source": "user", "type": "folder", "version": "1"},
            {"id": "ZuluProvider", "dependencies": ["Root"], "path": "/plugins/ZuluProvider", "source": "user", "type": "folder", "version": "1"},
        ]})
        restored = self.model.request("reload", {"id": "Root", "target_load_ok": True})
        self.assertTrue(restored["ok"])
        self.assertEqual(["ZuluProvider", "AlphaConsumer"], restored["data"]["restore_attempt_order"])
        self.assertEqual(["ZuluProvider", "AlphaConsumer"], restored["data"]["restored"])

    def test_unload_only_snapshots_expected_cascade_without_restoring_it(self):
        unloaded = self.model.request("unload", {"id": "Provider", "remember": True})
        self.assertTrue(unloaded["ok"])
        self.assertEqual(["Direct", "Sibling", "Transitive"], unloaded["data"]["expected_cascade"])
        self.assertEqual([], unloaded["data"]["restored"])
        self.assertEqual(["Direct", "Disabled", "Provider", "Sibling", "Transitive"], unloaded["data"]["unloaded"])

        state = self.model.request("status")
        self.assertEqual([], state["data"]["loaded"])
        self.assertEqual(["Direct", "Sibling", "Transitive"], state["data"]["retained"]["Provider"]["ids"])

    def test_partial_restore_is_provider_first_and_retained_for_retry(self):
        partial = self.model.request("reload", {
            "id": "Provider", "target_load_ok": True, "dependent_load_failures": ["Direct"]
        })
        self.assertTrue(partial["ok"], "target success remains distinct from dependent partial failure")
        self.assertEqual("partial_restore", partial["data"]["phase"])
        self.assertEqual(["Direct", "Sibling", "Transitive"], partial["data"]["restore_attempt_order"])
        self.assertEqual(["Sibling"], partial["data"]["restored"])
        self.assertEqual([
            {"id": "Direct", "code": "load_failed"},
            {"id": "Transitive", "code": "prerequisite_unloaded"},
        ], partial["data"]["dependent_errors"])

        state = self.model.request("status")
        self.assertEqual(["Provider", "Sibling"], state["data"]["loaded"])
        self.assertEqual(["Direct", "Sibling", "Transitive"], state["data"]["retained"]["Provider"]["ids"])

        completed = self.model.request("restore_closure", {"id": "Provider"})
        self.assertTrue(completed["ok"])
        self.assertEqual(["Direct", "Transitive"], completed["data"]["restored"])
        self.assertEqual([], completed["data"]["dependent_errors"])
        self.assertEqual(["Direct", "Transitive"], completed["data"]["restore_attempt_order"])
        self.assertEqual(["Direct", "Provider", "Sibling", "Transitive"], self.model.request("status")["data"]["loaded"])

    def test_non_object_json_returns_error_without_terminating_model(self):
        self.model.proc.stdin.write("[]\n")
        self.model.proc.stdin.flush()
        response = json.loads(self.model.proc.stdout.readline())
        self.assertFalse(response["ok"])
        self.assertEqual("invalid_request", response["error"]["code"])
        self.assertTrue(self.model.request("status")["ok"])

    def test_tcp_client_rejects_non_loopback_and_oversized_request(self):
        request = {"v": 1, "id": "r1", "route": "status", "data": {}}
        with self.assertRaisesRegex(ValueError, "loopback"):
            lifecycle_bridge.call_tcp("example.com", 30007, 1.0, request)
        request["data"] = {"value": "x" * 70000}
        with self.assertRaisesRegex(ValueError, "65536"):
            lifecycle_bridge.call_tcp("127.0.0.1", 30007, 1.0, request)

    def test_tcp_client_rejects_mismatched_correlation_and_oversized_response(self):
        request = {"v": 1, "id": "r1", "route": "status", "data": {}}
        bad = json.dumps({"v": 1, "id": "stale", "route": "status", "ok": True}).encode() + b"\n"
        server = OneShotLifecycleServer(bad)
        with self.assertRaisesRegex(RuntimeError, "correlation"):
            lifecycle_bridge.call_tcp("127.0.0.1", server.port, 1.0, request)
        server.join()

        server = OneShotLifecycleServer(b"x" * (lifecycle_bridge.MAX_MESSAGE + 1))
        with self.assertRaisesRegex(RuntimeError, "65536"):
            lifecycle_bridge.call_tcp("127.0.0.1", server.port, 1.0, request)
        server.join()


if __name__ == "__main__":
    unittest.main(verbosity=2)
