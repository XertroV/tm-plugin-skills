"""Bounded, big-endian uint32 length-prefixed JSON framing."""

import json
import struct

DEFAULT_MAX_FRAME = 64 * 1024


class ProtocolError(ValueError):
    pass


class FrameTooLarge(ProtocolError):
    pass


class MalformedFrame(ProtocolError):
    pass


def read_exact(reader, size):
    chunks = bytearray()
    while len(chunks) < size:
        chunk = reader.read(size - len(chunks))
        if not chunk:
            raise MalformedFrame(f"unexpected EOF: wanted {size}, received {len(chunks)}")
        chunks.extend(chunk)
    return bytes(chunks)


def encode_frame(value, max_frame=DEFAULT_MAX_FRAME):
    body = json.dumps(value, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    if not body:
        raise MalformedFrame("empty frame")
    if len(body) > max_frame:
        raise FrameTooLarge(f"frame length {len(body)} exceeds maximum {max_frame}")
    return struct.pack("!I", len(body)) + body


def read_frame(reader, max_frame=DEFAULT_MAX_FRAME):
    length = struct.unpack("!I", read_exact(reader, 4))[0]
    if length == 0:
        raise MalformedFrame("zero-length frame")
    if length > max_frame:
        raise FrameTooLarge(f"frame length {length} exceeds maximum {max_frame}")
    body = read_exact(reader, length)
    try:
        value = json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise MalformedFrame("frame body is not valid UTF-8 JSON") from exc
    if not isinstance(value, dict):
        raise MalformedFrame("frame JSON must be an object")
    return value
