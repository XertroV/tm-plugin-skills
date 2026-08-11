import socket
import sys
import threading
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[2] / "skills" / "openplanet-control" / "scripts"
sys.path.insert(0, str(SCRIPTS))

from semantic_control.client import (
    AssertionFailed,
    ClientError,
    assert_response,
    call,
)
from semantic_control.protocol import ProtocolError, encode_frame, read_frame


class OneShotServer:
    def __init__(self, responder, trailing=b""):
        self.responder = responder
        self.trailing = trailing
        self.received = None
        self.listener = socket.socket()
        self.listener.bind(("127.0.0.1", 0))
        self.listener.listen(1)
        self.port = self.listener.getsockname()[1]
        self.thread = threading.Thread(target=self.run)
        self.thread.start()

    def run(self):
        try:
            conn, _ = self.listener.accept()
            with conn, conn.makefile("rb") as reader:
                self.received = read_frame(reader)
                response = self.responder(self.received)
                conn.sendall(encode_frame(response) + self.trailing)
        except (OSError, ProtocolError):
            pass
        finally:
            self.listener.close()

    def join(self):
        self.thread.join(timeout=2)
        if self.thread.is_alive():
            raise AssertionError("server thread did not stop")


class ClientTests(unittest.TestCase):
    def test_call_round_trip_checks_matching_request_id(self):
        server = OneShotServer(lambda request: {"v": 1, "id": request["id"], "ok": True, "result": {"value": 7}})
        response = call("127.0.0.1", server.port, {"v": 1, "id": "r1", "route": "ping"})
        server.join()
        self.assertEqual(response["result"]["value"], 7)
        self.assertEqual(server.received["route"], "ping")

    def test_call_rejects_missing_request_id(self):
        with self.assertRaises(ClientError):
            call("127.0.0.1", 1, {"v": 1, "route": "ping"})

    def test_call_rejects_mismatched_response_id(self):
        server = OneShotServer(lambda request: {"v": 1, "id": "other", "ok": True, "result": {}})
        with self.assertRaises(ClientError):
            call("127.0.0.1", server.port, {"v": 1, "id": "request", "route": "ping", "args": {}})
        server.join()

    def test_call_rejects_trailing_response_bytes(self):
        server = OneShotServer(
            lambda request: {"v": 1, "id": request["id"], "ok": True},
            trailing=b"garbage",
        )
        with self.assertRaisesRegex(ClientError, "trailing bytes"):
            call("127.0.0.1", server.port, {"v": 1, "id": "r1", "route": "ping", "args": {}})
        server.join()

    def test_call_refuses_non_loopback_host(self):
        with self.assertRaises(ClientError):
            call("0.0.0.0", 1234, {"v": 1, "id": "r1", "route": "ping"})

    def test_assert_response_supports_dotted_result_equality(self):
        response = {"ok": True, "result": {"component": "save", "performed": True}}
        assert_response(response, ["ok=true", "result.component=save", "result.performed=true"])

    def test_assert_response_failure_is_explicit(self):
        with self.assertRaises(AssertionFailed):
            assert_response({"ok": False}, ["ok=true"])


if __name__ == "__main__":
    unittest.main()
