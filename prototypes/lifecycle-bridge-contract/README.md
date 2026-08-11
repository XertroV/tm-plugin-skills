# Minimal lifecycle bridge contract fixture

Portable, dependency-free Python 3 executable specification for the tm-plugin-skills L1 lifecycle bridge contract. It uses newline-delimited JSON on stdin/stdout for deterministic testing and includes a one-request/one-response TCP client for a future live bridge.

## Public seam

```sh
python3 prototypes/lifecycle-bridge-contract/lifecycle_bridge.py model
```

Each input line is one JSON request and each output line is its correlated response. Routes exercised here: `configure`, `status`, `reload`, `unload`, and `restore_closure`.

The live client shape is:

```sh
python3 prototypes/lifecycle-bridge-contract/lifecycle_bridge.py call status --host 127.0.0.1 --port 30007
```

It uses only Python's standard library, a 3-second default timeout, one connection per request, and a 64 KiB response bound.

## Contract encoded

- Snapshot only the currently loaded transitive required reverse-dependent closure.
- Preserve descriptors and the original snapshot across failed target load/retry.
- Restore providers before consumers in deterministic topological order.
- Never restore an unloaded/disabled possible consumer.
- An intentional unload-only cascade records evidence but restores nothing.
- A target can succeed while dependent restoration is partial; retain the snapshot, report per-ID errors, and retry missing members after prerequisites.

## Test

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_lifecycle_bridge_contract.py -v
```

The tests invoke the model through the NDJSON subprocess seam rather than importing internals.

## Evidence boundary and manual fallback

This is candidate/model evidence only. The files under `openplanet-fixture/` are deliberately gated DEV-only drafts and were not installed, compiled, loaded, or exercised in Openplanet. They must not be presented as live evidence.

Until a bridge passes current LSP + live Openplanet gates, preserve L0: stage/compare exact bytes, mark a fresh `Openplanet.log` offset, ask the human to operate the exact plugin ID in Scripts/Plugins, verify only appended log bytes, and manually restore the retained list provider-before-consumer after target success. For intentional unload-only, leave the expected cascade unloaded.
