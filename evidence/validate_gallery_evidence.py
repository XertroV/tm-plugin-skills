"""Semantic validation for gallery evidence records."""

from __future__ import annotations

from typing import Any


class EvidenceError(ValueError):
    pass


def validate_semantics(record: dict[str, Any]) -> None:
    live = record["live"]
    cases = record["cases"]
    all_live = all(
        live[key]
        for key in ("runtime_load", "native_tests", "screenshots", "visual_critique")
    )
    if live["status"] == "complete":
        if not all_live:
            raise EvidenceError("complete live status requires every live gate")
        for key in ("openplanet_version", "game_version", "log_reference"):
            if not live[key]:
                raise EvidenceError(f"complete live status requires {key}")
    if record["evidence_level"] in {"observed", "stable"} and live["status"] != "complete":
        raise EvidenceError("observed/stable evidence requires complete live status")
    if record["evidence_level"] == "stable" and not all(
        case["status"] == "approved" for case in cases
    ):
        raise EvidenceError("stable evidence requires every case approved")
    for case in cases:
        if case["status"] in {"captured", "approved", "rejected"} and not case["capture"]:
            raise EvidenceError(f"case {case['id']} requires a capture")
        if case["status"] in {"approved", "rejected"} and not case["critique"]:
            raise EvidenceError(f"case {case['id']} requires a critique")
