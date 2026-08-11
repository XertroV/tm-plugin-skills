# UI exception containment probe

DEV-only fault fixture for issue 13. It intentionally exposes two manual actions:

1. an exception in an isolated `startnew(...)` coroutine;
2. an exception escaping `RenderInterface()`.

The window reports callback counters and emits a heartbeat every 120 frames. Run
the isolated action first and verify later heartbeats continue. Then run the
inline action, preserve the exact post-click `Openplanet.log` window, and observe
whether later heartbeats/callback counts continue.

## Captured result (Openplanet 1.29.0)

- Isolated path: `Openplanet.log:26724-26727` reported the coroutine exception;
  later heartbeats at `:26746-26836` proved rendering continued.
- Inline path: `Openplanet.log:27021-27027` reported the exception through
  `RenderInterface()`, then `Unrolling dangling script UI stack` at the open
  window scope. No later probe heartbeat appeared while other plugins logged.

This fixture is intentionally unsafe and is not a promoted component or recipe.
Its only purpose is reproducible engine-behavior evidence. Unload it after use.
