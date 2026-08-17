# Failure ledger

Use this as a mechanism checklist, not a keyword linter. Mark each applicable
class caught, N/A, or not tested.

## UI and callbacks

### UI callback failure containment

Risky action execution escapes a render callback, leaving UI scopes dangling and
stopping later callbacks. Trace transitive calls, including dynamic callbacks.
Require a real coroutine boundary for throwing/yielding/I/O/game-mutation work
and balance all UI/style/clip/scissor scopes on every actual path.

### Duplicate render dispatch

The same window or draw surface is submitted from multiple callbacks in one
frame. Assign one owner per overlay state and use stable explicit IDs.

### Interactive identity drift

Labels, ordering, localization, duplicated components, or loop positions change
ImGui identity. Require explicit stable IDs composed from persistent domain
identity and scope.

### Exception-safe scope restoration

Token counts or parallel depth helpers pass while an early return or throw leaks
window/table/child/style/clip/scissor state. Probe failure after each begin/push.

## State, mode, and lifetime

### Wrong game/application mode

Code reaches editor/playground/map/server objects outside its valid mode. Model
mode explicitly and fail closed with a concise reason and remediation.

### Plugin/game state desynchronization

Callbacks, packets, retries, or overlapping tasks apply out of order or outlive
the map/editor/server/session/reload snapshot that created them. Require
generation ownership, post-yield revalidation, explicit retry/reorder semantics,
and cleanup after partial teardown.

### Async terminal-state completeness

Loading/busy/in-progress flags or waiters have no error/timeout/cancel terminal.
Enumerate exactly one terminal state and cleanup for every exit.

### Wrong wait primitive

`Dev::Sleep` blocks the main thread; `sleep()` is the cooperative wall-clock
wait; `yield()` / `yield(n)` are frame waits (`yield()` is `yield(1)`;
`yield(0)` is a no-op; `sleep(0)` yields one frame). Flag `Dev::Sleep` on any
normal path, `sleep()` used for frame-counted lifecycle, `yield(n)` used for
wall-clock time, and a single `yield()` used as the entire compile/log wait
across a queued reload. After unload/reload, `yield()` then re-resolve by ID.

### Per-frame O(n) serialization

Draw/update serializes growing history, rebuilds a static registry every
call, or applies a bulk `O(n)` job on the game loop. Time sections with
stable `Time::Now` labels before blaming the obvious list. Require
fingerprint or version-counter caches with hit/miss counters, and
`startnew` + `yield()` chunking for bulk applies. Measure settled frames
on a real fixture, not a warmup spike or empty session.

### Transactional mutation restoration

Patches, hooks, intercepts, temporary modes, or settings survive early return,
throw, cancel, unload, or transition. Treat mutation as a transaction with one
idempotent rollback owner.

### Manual engine-reference ownership

`MwAddRef`, retained nods, or tasks leak or double-release. Build a balance graph
across every terminal path and repeated failure.

### Zero-progress and boundary behavior

A timeout before item zero causes negative indexing, queue stalls, skipped work,
or cleanup bypass. Test zero, one, exact limit, partial progress, and concurrent
queue mutation.

### Mutation-result truthfulness

Expected/replicated state advances, or queued work is removed, before engine
application is verified. Require validate → apply → observe → commit → ack.

## Component and module boundaries

### Component visibility versus intent

Remote or programmatic actions activate invisible/undrawn controls. Default to
`force = false`; return cause and next step when control is not visible.

### Export/module identity mismatch

Importer/exporter topology or shared identity assumptions differ between LSP,
generator, and Openplanet. Prefer ordinary exports unless a type or interface
must be one shared identity across modules; validate dependent load and unload
order in game. Reload traps (upstream openplanet-nl/issues #244/#383/#451/
#503): stale shared-class definitions held by registries in other plugins block
exporter reload; reload exporter first; prefer shared interfaces over shared
base classes; shared interface signature changes need a game restart; exporter
failing while dependents compile can mean a shared type is missing from
`shared_exports`.

### Shared-export reload traps

A shared class/interface is edited while dependents or registries in other
loaded modules still reference the old definition; or reload order is
dependent-before-exporter; or a shared type used by the exporter itself is
missing from `shared_exports`. Symptoms: "shared classes having different
definitions" errors that survive exporter reloads; exporter failing while
dependents compile; errors on school/dev-mode switches with no file change.
Upstream: openplanet-nl/issues #65, #244, #383, #451, #503. Prevention: prefer
shared interfaces over shared base classes; define shared interfaces complete
up front (signature changes need a game restart); reload exporter first; fix
stale-reference holders rather than restarting.

### Architecture erosion

Callbacks contain business engines, multiple modules derive the same truth,
boolean combinations encode illegal states, god objects mix protocol/state/UI,
or public mutation bypasses owners. Findings require concrete correctness or
change-safety impact, not aesthetics.

## Networking and synchronization

### Network architecture mismatch

Transport architecture was copied without classifying data, cadence, ordering,
loss consequence, consistency, and recovery. Document those properties first.

Probe:

- exact frame consumption and length bounds;
- fragmentation and partial writes;
- sole writer and ordering;
- count and byte backpressure;
- duplicate/replay/reorder/drop/delay;
- stale connection/session/map epochs;
- retry/coalescing per traffic class; and
- reconciliation after poisoned expected state.

## Evidence rule

A new class entry should state trigger, impact, invariant, evidence, reviewer
probe, and prevention/evidence gate. A hypothesis must include one concrete next
probe.