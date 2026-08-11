# Transport freeze gate

This fixture is DEV-only, opt-in, and localhost-only. It uses one request/reply per connection, exact reads, close-on-error, and a 64 KiB request/response bound.

The Python reference currently encodes an unsigned 32-bit **big-endian** body length. Before a real Openplanet transport implementation is promoted, maintainers **MUST live-probe** the bytes produced/consumed by `Net::Socket` integer operations and either confirm big-endian or update both peers and captured tests. `Write(string)` must not be used because it adds its own framing; write the JSON bytes exactly once.

The checked-in AngelScript fixture deliberately provides registry/router/component semantics and a loopback listener ownership seam, not an unverified byte-framing implementation. Deadlines, exact reads/writes, active-client shutdown, fragmentation, partial-write, and reload behavior remain mandatory live gates.
