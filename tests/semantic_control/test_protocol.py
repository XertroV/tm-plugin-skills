import io
import json
import struct
import sys
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[2] / "skills" / "openplanet-control" / "scripts"
sys.path.insert(0, str(SCRIPTS))

from semantic_control.protocol import (
    DEFAULT_MAX_FRAME,
    FrameTooLarge,
    MalformedFrame,
    encode_frame,
    read_exact,
    read_frame,
)


class FragmentedReader:
    def __init__(self, data, chunk_size=1):
        self.data = data
        self.chunk_size = chunk_size
        self.offset = 0

    def read(self, size):
        size = min(size, self.chunk_size)
        chunk = self.data[self.offset:self.offset + size]
        self.offset += len(chunk)
        return chunk


class ProtocolTests(unittest.TestCase):
    def test_read_exact_joins_fragmented_reads(self):
        self.assertEqual(read_exact(FragmentedReader(b"abcd"), 4), b"abcd")

    def test_read_exact_rejects_eof(self):
        with self.assertRaises(MalformedFrame):
            read_exact(io.BytesIO(b"abc"), 4)

    def test_frame_round_trip_uses_big_endian_uint32(self):
        payload = {"v": 1, "id": "r1", "route": "ping"}
        framed = encode_frame(payload)
        body = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        self.assertEqual(framed, struct.pack("!I", len(body)) + body)
        self.assertEqual(read_frame(FragmentedReader(framed)), payload)

    def test_zero_length_frame_is_malformed(self):
        with self.assertRaises(MalformedFrame):
            read_frame(io.BytesIO(struct.pack("!I", 0)))

    def test_exact_limit_is_allowed(self):
        framed = struct.pack("!I", 2) + b"{}"
        self.assertEqual(read_frame(io.BytesIO(framed), max_frame=2), {})

    def test_over_limit_is_rejected_before_body_read(self):
        with self.assertRaises(FrameTooLarge):
            read_frame(io.BytesIO(struct.pack("!I", DEFAULT_MAX_FRAME + 1)))

    def test_malformed_json_is_rejected(self):
        with self.assertRaises(MalformedFrame):
            read_frame(io.BytesIO(struct.pack("!I", 1) + b"{"))

    def test_non_object_json_is_rejected(self):
        body = b"[]"
        with self.assertRaises(MalformedFrame):
            read_frame(io.BytesIO(struct.pack("!I", len(body)) + body))

    def test_encode_rejects_oversized_payload(self):
        with self.assertRaises(FrameTooLarge):
            encode_frame({"data": "xxx"}, max_frame=2)


if __name__ == "__main__":
    unittest.main()
