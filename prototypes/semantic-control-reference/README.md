# Semantic-control reference draft

Portable, public-safe draft for `tm-plugin-skills` implementation-sequence step 6. It is deliberately **DEV-only**, disabled by default, loopback-only, bounded, fixed-route, and semantic-only. It contains no eval, shell, filesystem, generic callback, lifecycle-daemon, secret, or arbitrary-code surface.

## Python reference

The dependency-free `semantic_control` package and `control.py` implement a one-request/one-response TCP client using a big-endian uint32 length followed by bounded UTF-8 JSON. The client enforces exact reads, 64 KiB defaults, localhost, non-empty/matching request IDs, fixed routes, dotted assertions, timeouts, and nonzero exits.

Examples:

```sh
python3 control.py --port 39021 call ping --id smoke-1 --assert ok=true
python3 control.py --port 39021 action save click --id click-1 --assert result.performed=true
python3 control.py --port 39021 action save click --id click-2 --force --assert result.forced=true
```

Exit codes: `0` success, `1` transport/protocol/client error, `2` CLI usage or disallowed route, `3` remote `ok:false`, `4` assertion failure.

## AngelScript fixture

`openplanet/SemanticControlFixture` is the canonical registry/router/component seam:

- stable IDs, owner generation, teardown;
- completed-render-epoch visibility truth;
- hidden no-op by default and truthful forced semantic invocation;
- fixed `ping`, `component.state`, and `component.action` routes only;
- observable component state and neighboring `[Test]` files;
- explicit localhost listener ownership and cleanup.

It intentionally does **not** claim a validated Openplanet framing implementation. `TRANSPORT.md` records the mandatory byte-order live probe and remaining live network gates. This separation avoids publishing guessed socket semantics.

## Test

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests/semantic_control -v
```

AngelScript tests are neighboring fixtures for Openplanet `[Test]` discovery
and require live compile/test evidence before promotion.
