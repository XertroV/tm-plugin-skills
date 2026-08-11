"""Loopback-only one-request/one-response semantic-control client."""

import json
import socket

from .protocol import DEFAULT_MAX_FRAME, encode_frame, read_frame


class ClientError(RuntimeError):
    pass


class AssertionFailed(ClientError):
    pass


def call(host, port, request, timeout=2.0, max_frame=DEFAULT_MAX_FRAME):
    if host not in {"127.0.0.1", "localhost", "::1"}:
        raise ClientError("semantic control is localhost-only")
    request_id = request.get("id")
    if not isinstance(request_id, str) or not request_id:
        raise ClientError("request id must be a non-empty string")
    try:
        with socket.create_connection((host, port), timeout=timeout) as sock:
            sock.settimeout(timeout)
            sock.sendall(encode_frame(request, max_frame=max_frame))
            with sock.makefile("rb") as reader:
                response = read_frame(reader, max_frame=max_frame)
                if reader.read(1):
                    raise ClientError("trailing bytes after response frame")
    except (OSError, ValueError) as exc:
        raise ClientError(str(exc)) from exc
    if response.get("id") != request_id:
        raise ClientError(f"response id mismatch: expected {request_id!r}, got {response.get('id')!r}")
    return response


def _expected(text):
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return text


def _lookup(response, dotted):
    value = response
    for part in dotted.split("."):
        if not isinstance(value, dict) or part not in value:
            raise AssertionFailed(f"assertion path not found: {dotted}")
        value = value[part]
    return value


def assert_response(response, assertions):
    for assertion in assertions:
        if "=" not in assertion:
            raise AssertionFailed(f"assertion must be PATH=JSON_OR_TEXT: {assertion}")
        path, expected_text = assertion.split("=", 1)
        actual = _lookup(response, path)
        expected = _expected(expected_text)
        if actual != expected:
            raise AssertionFailed(f"assertion failed: {path} expected {expected!r}, got {actual!r}")
