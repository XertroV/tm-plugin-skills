#!/usr/bin/env python3
"""Portable NDJSON lifecycle-closure model and TCP client (Python 3 stdlib only)."""
from __future__ import annotations

import argparse
import json
import socket
import sys
from dataclasses import dataclass, field
from typing import Any, TextIO

PROTOCOL = 1


@dataclass
class Plugin:
    id: str
    dependencies: list[str]
    path: str
    source: str
    type: str
    version: str
    loaded: bool = True

    @classmethod
    def from_json(cls, value: dict[str, Any]) -> "Plugin":
        return cls(
            id=value["id"],
            dependencies=list(value.get("dependencies", [])),
            path=value["path"],
            source=value["source"],
            type=value["type"],
            version=value["version"],
            loaded=bool(value.get("loaded", True)),
        )

    def descriptor(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "dependencies": self.dependencies,
            "path": self.path,
            "source": self.source,
            "type": self.type,
            "version": self.version,
        }


@dataclass
class Snapshot:
    target: str
    descriptors: list[dict[str, Any]]

    def json(self) -> dict[str, Any]:
        return {
            "target": self.target,
            "ids": [item["id"] for item in self.descriptors],
            "descriptors": self.descriptors,
        }


@dataclass
class LifecycleModel:
    plugins: dict[str, Plugin] = field(default_factory=dict)
    retained: dict[str, Snapshot] = field(default_factory=dict)

    def configure(self, data: dict[str, Any]) -> dict[str, Any]:
        self.plugins = {p.id: p for p in map(Plugin.from_json, data["plugins"])}
        self.retained.clear()
        return {"configured": sorted(self.plugins)}

    def closure(self, target: str) -> Snapshot:
        selected: set[str] = set()
        frontier = [target]
        while frontier:
            provider = frontier.pop(0)
            for plugin in self.plugins.values():
                if plugin.loaded and plugin.id != target and provider in plugin.dependencies and plugin.id not in selected:
                    selected.add(plugin.id)
                    frontier.append(plugin.id)
        ordered = self.topological_order(selected)
        return Snapshot(target, [self.plugins[plugin_id].descriptor() for plugin_id in ordered])

    def topological_order(self, selected: set[str]) -> list[str]:
        remaining = set(selected)
        ordered: list[str] = []
        while remaining:
            ready = sorted(
                plugin_id for plugin_id in remaining
                if not (set(self.plugins[plugin_id].dependencies) & remaining)
            )
            if not ready:
                raise ValueError("dependency_cycle")
            ordered.extend(ready)
            remaining.difference_update(ready)
        return ordered

    def cascade_unload(self, target: str) -> None:
        affected = {target}
        changed = True
        while changed:
            changed = False
            for plugin in self.plugins.values():
                if plugin.loaded and set(plugin.dependencies) & affected and plugin.id not in affected:
                    affected.add(plugin.id)
                    changed = True
        for plugin_id in affected:
            self.plugins[plugin_id].loaded = False

    def unload(self, data: dict[str, Any]) -> tuple[bool, str | None, dict[str, Any]]:
        target = data["id"]
        if target not in self.plugins or not self.plugins[target].loaded:
            return False, "unknown_or_unloaded_plugin", {}
        snapshot = self.retained.get(target) or self.closure(target)
        if bool(data.get("remember", True)):
            self.retained[target] = snapshot
        self.cascade_unload(target)
        return True, None, {
            "phase": "unloaded", "snapshot": snapshot.json(),
            "expected_cascade": snapshot.json()["ids"], "restored": [],
            "unloaded": sorted(plugin.id for plugin in self.plugins.values() if not plugin.loaded),
        }

    def restore(self, target: str, failures: set[str]) -> tuple[list[str], list[str], list[dict[str, str]]]:
        snapshot = self.retained[target]
        attempt_order: list[str] = []
        restored: list[str] = []
        errors: list[dict[str, str]] = []
        snapshot_ids = {item["id"] for item in snapshot.descriptors}
        for descriptor in snapshot.descriptors:
            plugin_id = descriptor["id"]
            if self.plugins[plugin_id].loaded:
                continue
            attempt_order.append(plugin_id)
            if plugin_id in failures:
                errors.append({"id": plugin_id, "code": "load_failed"})
                continue
            required = set(descriptor["dependencies"]) & (snapshot_ids | {target})
            if any(not self.plugins[dependency].loaded for dependency in required):
                errors.append({"id": plugin_id, "code": "prerequisite_unloaded"})
                continue
            self.plugins[plugin_id].loaded = True
            restored.append(plugin_id)
        if not errors:
            del self.retained[target]
        return attempt_order, restored, errors

    def restore_closure(self, data: dict[str, Any]) -> tuple[bool, str | None, dict[str, Any]]:
        target = data["id"]
        if target not in self.retained:
            return False, "no_retained_snapshot", {}
        attempt_order, restored, errors = self.restore(target, set(data.get("dependent_load_failures", [])))
        return True, None, {
            "phase": "partial_restore" if errors else "restored",
            "restore_attempt_order": attempt_order,
            "restored": restored,
            "dependent_errors": errors,
        }

    def reload(self, data: dict[str, Any]) -> tuple[bool, str | None, dict[str, Any]]:
        target = data["id"]
        if target not in self.plugins:
            return False, "unknown_plugin", {}
        reused = target in self.retained
        snapshot = self.retained.get(target) or self.closure(target)
        self.retained[target] = snapshot
        self.cascade_unload(target)
        if not bool(data.get("target_load_ok", True)):
            return False, "target_load_failed", {
                "phase": "target_load_failed", "snapshot": snapshot.json(),
                "snapshot_reused": reused, "restore_attempt_order": [],
                "restored": [], "dependent_errors": [],
            }
        self.plugins[target].loaded = True
        attempt_order, restored, errors = self.restore(
            target, set(data.get("dependent_load_failures", [])))
        return True, None, {
            "phase": "partial_restore" if errors else "restored",
            "snapshot": snapshot.json(), "snapshot_reused": reused,
            "restore_attempt_order": attempt_order,
            "restored": restored, "dependent_errors": errors,
        }

    def handle(self, request: dict[str, Any]) -> dict[str, Any]:
        route = request.get("route")
        data = request.get("data") or {}
        ok, code, result = True, None, {}
        try:
            if request.get("v") != PROTOCOL:
                ok, code = False, "unsupported_protocol"
            elif route == "configure":
                result = self.configure(data)
            elif route == "reload":
                ok, code, result = self.reload(data)
            elif route == "unload":
                ok, code, result = self.unload(data)
            elif route == "restore_closure":
                ok, code, result = self.restore_closure(data)
            elif route == "status":
                result = {
                    "loaded": sorted(plugin.id for plugin in self.plugins.values() if plugin.loaded),
                    "retained": {target: snapshot.json() for target, snapshot in sorted(self.retained.items())},
                }
            else:
                ok, code = False, "unknown_route"
        except (KeyError, TypeError, ValueError) as exc:
            ok, code, result = False, str(exc).strip("'"), {}
        return {
            "v": PROTOCOL,
            "id": request.get("id"),
            "route": route,
            "ok": ok,
            "error": None if ok else {"code": code, "message": code.replace("_", " ")},
            "data": result,
        }


def serve_model(source: TextIO, sink: TextIO) -> int:
    model = LifecycleModel()
    for line in source:
        try:
            request = json.loads(line)
            response = model.handle(request)
        except json.JSONDecodeError:
            response = {"v": PROTOCOL, "id": None, "route": None, "ok": False,
                        "error": {"code": "invalid_json", "message": "invalid json"}, "data": {}}
        sink.write(json.dumps(response, separators=(",", ":")) + "\n")
        sink.flush()
    return 0


def call_tcp(host: str, port: int, timeout: float, request: dict[str, Any]) -> dict[str, Any]:
    wire = json.dumps(request, separators=(",", ":")).encode() + b"\n"
    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(wire)
        response = bytearray()
        while not response.endswith(b"\n"):
            chunk = sock.recv(4096)
            if not chunk:
                raise RuntimeError("connection closed before newline response")
            response.extend(chunk)
            if len(response) > 65536:
                raise RuntimeError("response exceeds 65536 bytes")
    return json.loads(response)


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("model", help="run the deterministic stdin/stdout NDJSON model")
    call = sub.add_parser("call", help="send one NDJSON request to a live bridge")
    call.add_argument("route")
    call.add_argument("--data", default="{}")
    call.add_argument("--id", default="cli-1")
    call.add_argument("--host", default="127.0.0.1")
    call.add_argument("--port", type=int, default=30007)
    call.add_argument("--timeout", type=float, default=3.0)
    args = parser.parse_args()
    if args.command == "model":
        return serve_model(sys.stdin, sys.stdout)
    request = {"v": PROTOCOL, "id": args.id, "route": args.route, "data": json.loads(args.data)}
    response = call_tcp(args.host, args.port, args.timeout, request)
    print(json.dumps(response, sort_keys=True))
    return 0 if response.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
