#if DEV
// Candidate-only runtime fixture. It is intentionally not installed or claimed live.
// Gate before promotion: current Openplanet LSP, live compile/load, fresh log window,
// loopback socket smoke, cascade observations, and exact game/Openplanet versions.

[Setting category="Lifecycle fixture" name="Enable DEV-only loopback fixture"]
bool S_EnableLifecycleFixture = false;

void Main() {
    if (!S_EnableLifecycleFixture) {
        trace("Lifecycle bridge fixture disabled; use manual Scripts/Plugins UI fallback.");
        return;
    }
    // TODO live gate: bind explicitly to 127.0.0.1:30007 with one bounded NDJSON
    // request/response per connection. Openplanet's socket bind semantics must be
    // verified before implementing this stub; Listen(port) may expose all interfaces.
    warn("Lifecycle bridge fixture is a static candidate only; no socket was opened.");
}
#endif
