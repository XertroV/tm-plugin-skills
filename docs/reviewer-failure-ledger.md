# Openplanet adversarial reviewer failure ledger

This is a living evidence base for `openplanet-reviewer`. Add a row whenever
development, testing, dogfooding, issue research, or postmortem work reveals a
new way a plugin can subtly fail. Normal implementation defaults belong in
`openplanet-gotchas.md`; this ledger records the adversarial question, failure
mechanism, evidence, and required reviewer probe.

## Entry contract

Each entry records:

- **Failure class** — stable category used by the reviewer checklist.
- **Trigger** — state or event that makes the bug possible.
- **Symptom/impact** — observable failure, including silent corruption.
- **Mechanism/invariant** — why it fails and what must remain true.
- **Evidence** — source path, issue, log signature, live reproduction, or primary documentation; label hypotheses.
- **Reviewer probe** — concrete search, state transition, fault injection, or runtime check.
- **Prevention/evidence gate** — architecture rule and test/demo proof expected.

Do not record vague “be careful” advice. A ledger entry must change how an
adversarial review is performed.

## Current failure classes

### UI callback failure containment

- **Trigger:** drawing code directly performs a potentially throwing, yielding,
  networked, filesystem, or complex state mutation.
- **Symptom/impact:** Openplanet reports an exception while unwinding/unrolling
  the UI stack; the plugin stops receiving render callbacks and its UI vanishes.
- **Invariant:** render callbacks remain bounded and exception-minimal; complex
  action execution cannot escape through the active UI stack.
- **Evidence:** prior issue-13 Openplanet 1.29.0 project observation; the original
  log is not bundled. `Openplanet.log:26724-26836` showed an isolated coroutine
  exception followed by continuing heartbeats;
  `Openplanet.log:27021-27027` shows an inline `RenderInterface()` exception,
  `Unrolling dangling script UI stack`, and no later probe heartbeat. Rerun the
  define-gated fixture for independent demonstration. Component
  precedents remain in `tm-draw-tests/src/Epp/ExtraEditorMenuItem.as:8-70,114-175`
  and `tm-bosslike/src/Game/Modes/SimpleRM.as:124-162`.
- **Reviewer probe:** trace every render-path call transitively; flag operations
  that can throw, yield, perform I/O, mutate game state, or invoke untrusted
  callbacks inline. Confirm style/ID/clip/scissor scopes are balanced on all
  early returns and exceptions.
- **Prevention/evidence gate:** launch risky work through an isolated coroutine
  with explicit argument/state ownership; inject a failing action and verify
  later frames still render and the failure is surfaced concisely.

### Duplicate render dispatch

- **Trigger:** one named ImGui window is unconditionally reached from both
  `Render()` and `RenderInterface()`.
- **Symptom/impact:** one window contains two copies of its interior.
- **Invariant:** overlay visibility selects exactly one authoritative callback.
- **Evidence:** Visual Recipe Gallery prototype and established sibling-plugin
  `UI::IsOverlayShown()` patterns.
- **Reviewer probe:** find plugins defining both callbacks, trace shared window
  functions, and test overlay shown/hidden states.
- **Prevention/evidence gate:** `RenderInterface()` owns overlay-visible UI;
  optional `Render()` fallback returns while overlay is shown; two-state test
  proves one interior.

### Interactive identity drift

- **Trigger:** controls rely on mutable/repeated labels, loop position without
  scope, or random IDs regenerated per frame.
- **Symptom/impact:** state moves between controls, clicks target the wrong item,
  focus resets, popups collide, or bugs appear only with duplicate labels.
- **Invariant:** every interactive control has a stable lifetime-appropriate ID.
- **Evidence:** gallery duplicate/ID dogfood and ImGui identity behavior.
- **Reviewer probe:** enumerate buttons, selectables, collapsibles, inputs,
  sliders, trees, tabs, popups, windows, and custom hit targets; model repeated
  labels, sorting, insertion, and changing visible text.
- **Prevention/evidence gate:** centralized string/index/composite/retained-random
  ID helpers plus duplicate-label and reorder tests.

### Wrong game/application mode

- **Trigger:** code assumes editor, playground, menu, server, map, or app objects
  exist after a mode transition or during partial initialization.
- **Symptom/impact:** null access, exception, mutation of the wrong state, stale
  UI, or silent no-op while the plugin believes the action succeeded.
- **Invariant:** mode-specific work validates current mode and reacquires live
  objects at the point of use.
- **Evidence:** Bosslike normalizes mode-sensitive state in
  `tm-bosslike/src/TM_State.as:1-155`; Map Together couples room lifetime to
  editor presence in `tm-map-together/src/EditorFeed.as:400-415`.
- **Reviewer probe:** exercise menu→playground→editor→menu, map changes, server
  join/leave, spectate, plugin reload, and dependency reload. Find cached nods or
  handles crossing these boundaries.
- **Prevention/evidence gate:** explicit state-machine guards, bounded retries or
  cancellation, and transition tests showing no stale access or false success.

### Plugin/game state desynchronization

- **Trigger:** callbacks, packets, coroutines, or retries apply out of order,
  overlap, or outlive the state snapshot that created them.
- **Symptom/impact:** plugin UI/state disagrees with Trackmania or peers; old work
  overwrites newer state; a retry loses the original dependent closure.
- **Invariant:** every mutation is tied to a generation/session/map identity and
  stale results cannot commit.
- **Evidence:** lifecycle dependent-closure retry gotcha; Bosslike post-yield
  stale-state revalidation (`Game/Modes/SimpleRM.as:124-162`); Dips++ connection
  nonce (`Server/Server.as:154-213`); Map Together expected-map reconciliation
  (`EditorFeed.as:417-500`).
- **Reviewer probe:** reorder, duplicate, delay, and drop events/packets; overlap
  actions; change map/server/mode while work is pending; retry after partial
  teardown.
- **Prevention/evidence gate:** generations, idempotence, explicit ownership,
  monotonic transitions where possible, and deterministic fault-injection tests.

### Component visibility versus intent

- **Trigger:** remote action trusts a `Visible` flag although the component was
  not submitted in the current completed render epoch.
- **Symptom/impact:** hidden controls activate or automation reports a click that
  could not physically occur.
- **Invariant:** default actions target only controls drawn this epoch.
- **Evidence:** approved component-control contract in the gallery prototype.
- **Reviewer probe:** invoke before first draw, after hiding, after stale
  registration, during reload, and with `force=false/true`.
- **Prevention/evidence gate:** render-epoch marking, no-op `not_drawn` failure,
  explicit forced semantic action, concise cause and next step.

### Export/module identity mismatch

- **Trigger:** ordinary exports are treated as library-local symbols or shared
  exports are used without a genuine identity requirement.
- **Symptom/impact:** game compile differs from LSP, tests cannot see symbols,
  dependency reload becomes fragile, or instances unexpectedly diverge/share.
- **Invariant:** ordinary exports compile into dependents (each plugin gets its
  own copy, so the same class is a different class per module); shared exports
  are reserved for types/interfaces that must be one identity across modules —
  signatures, passing, casts, or a single shared instance.
- **Evidence:** SkillpackDemoLib test-companion in-game compile failure and fix.
- **Reviewer probe:** derive actual surface from `info.toml`; test in exporting
  and dependent modules; walk nested shared types and reload order.
- **Prevention/evidence gate:** consumer-side ordinary-export tests, shared-type
  closure audit, and game/LSP compile parity.

### Shared-export reload traps

- **Trigger:** a shared class/interface is edited while dependents or registries
  in other loaded modules still reference the old definition; reload order is
  dependent-before-exporter; or a shared type used by the exporter itself is
  missing from `shared_exports` in `info.toml`.
- **Symptom/impact:** "shared classes having different definitions" compile
  errors that survive reloads of the exporter; exporter fails to compile while
  dependents succeed; errors appearing on school/dev-mode switches with no file
  change; stale function bodies applying silently after a body-only edit.
  Upstream: openplanet-nl/issues #65, #244, #383, #451, #503.
- **Invariant:** shared types have exactly one live definition across all loaded
  modules; changing one requires rebuilding every module that can hold a
  reference, in exporter-first order, or a script-engine/game restart.
- **Evidence:** MLFeed/MLHook registry held stale hook-class references —
  reloading MLHook (the holder) unblocked MLFeed (the exporter); ai-api
  documents game-restart re-linking for shared interface signature changes.
- **Reviewer probe:** map every shared type's consumers *and* registration
  holders (registries, caches, retained handles in third-party plugins); check
  reload transcripts exporter-first; flag shared class hierarchies where a
  shared interface would do.
- **Prevention/evidence gate:** prefer shared interfaces over shared base
  classes (interface surfaces change less; shared-class reload bugs are
  subtle); define shared interfaces complete up front; keep concrete
  implementations internal; fix stale-reference holders rather than restarting
  as a workaround during development.

### Network architecture mismatch

- **Trigger:** packet handling, buffering, parsing, routing, or update cadence is
  copied from another plugin with different data, reliability, ordering, or
  performance requirements.
- **Symptom/impact:** stalls, dropped updates, unbounded memory, stale state,
  head-of-line blocking, parsing ambiguity, or incorrect reconciliation.
- **Invariant:** transport and packet architecture follow explicit workload and
  consistency requirements rather than precedent alone.
- **Evidence:** confirmed comparison in
  `docs/research/issue-13-adversarial-review-evidence.md`: Dips++ is a sampled
  JSON API/session client with resume; Map Together is binary ordered editor
  replication with queued application and map reconciliation.
- **Reviewer probe:** characterize packet sizes/rates, ordering, partial reads,
  framing, backpressure, retry, disconnect, ownership, and per-frame work;
  simulate malformed, duplicated, delayed, and burst traffic.
- **Prevention/evidence gate:** documented protocol/state model, bounded queues
  and frames, load/fault tests, and explicit reconciliation semantics.

### Architecture erosion

- **Trigger:** a nontrivial plugin grows through globals, ad-hoc callbacks,
  cross-namespace reach-through, and repeated special cases without stable API
  or ownership boundaries.
- **Symptom/impact:** changes become risky, invariants are implicit, state leaks
  across modes, testing requires the whole plugin, and dynamic behavior becomes
  a giant conditional mesh.
- **Invariant:** namespaces define domains; classes own state/lifetimes;
  interfaces/callback bases expose narrow extension points; state machines and
  packet routers make transitions explicit.
- **Evidence:** Bosslike's runtime root, normalized state, base mode engine,
  adapters, split score ownership, animation polymorphism, and subsystem RNG
  streams are mapped in `docs/research/issue-13-adversarial-review-evidence.md`.
  Editor++ provides explicit external registration and teardown evidence.
- **Reviewer probe:** map ownership and dependency direction; identify mutable
  global clusters, feature-condition fan-out, callbacks without lifecycle, and
  code that cannot be tested without rendering/network/game state.
- **Prevention/evidence gate:** architecture note for nontrivial features,
  cohesive APIs, pure seams, extension tests, and a demo proving intended use.

### Transactional mutation restoration

- **Trigger:** a coroutine applies editor patches, hooks, intercepts, temporary
  modes, settings, or other engine mutations before a yield or fallible check.
- **Symptom/impact:** an early return, exception, cancellation, unload, or mode
  transition leaves Trackmania or another plugin patched after the owner stops.
- **Invariant:** temporary engine mutation is a transaction whose rollback runs
  on every terminal path.
- **Evidence:** `tm-map-together/src/EditorFeed.as:71-95,405-415` enables undo and
  sweep patches before readiness checks whose early returns bypass cleanup.
- **Reviewer probe:** inventory every patch/hook/intercept/temporary mode change;
  cross each with success, early return, throw, cancel, unload, and transition.
- **Prevention/evidence gate:** one owner and idempotent restoration path, with a
  fault-injection test proving the original engine state is restored.

### Manual engine-reference ownership

- **Trigger:** code retains a nod or task manually and exits through timeout,
  error, cancellation, or unload.
- **Symptom/impact:** references or tasks leak, stale engine objects remain
  reachable, or later cleanup double-releases them.
- **Invariant:** every `MwAddRef`, retained nod, and owned task has one balanced
  release on all terminal paths; borrowed handles are not retained implicitly.
- **Evidence:** `tm-bosslike/src/Game/Modes/SimpleRM.as:344-402` adds a reference
  to a matching download but releases it only on the non-timeout path.
- **Reviewer probe:** build an ownership graph for `MwAddRef`/`MwRelease`, web
  tasks, downloaded nods, and handles crossing yields; inject each terminal path.
- **Prevention/evidence gate:** scoped/centralized cleanup plus repeated-failure
  evidence showing stable refcounts and no retained tasks.

### Async terminal-state completeness

- **Trigger:** a loading, busy, in-progress, or delay flag is set before a
  coroutine performs fallible or yielding work.
- **Symptom/impact:** waiters suspend forever, repeated actions accumulate, UI
  remains loading, or a gameplay transition stays blocked.
- **Invariant:** every asynchronous operation reaches exactly one terminal state:
  success, error, timeout, or cancellation.
- **Evidence:** `tm-bosslike/src/Game/Modes/SimpleRM.as:289-319` throws before its
  only `IsLoading = false`; consumers wait at `:156-162,208-226`.
- **Reviewer probe:** enumerate async state flags and verify terminal assignment,
  waiter release, error reporting, and retry policy on every exit.
- **Prevention/evidence gate:** explicit terminal-state model and injected
  success/error/timeout/cancel tests with no remaining waiters.

### Wrong wait primitive

- **Trigger:** `Dev::Sleep` on a normal plugin path; `sleep()` used for a
  frame-counted lifecycle or animation wait; `yield(n)` used for wall-clock
  time; a single `yield()` used as the entire wait for compile/log evidence
  across a queued reload.
- **Symptom/impact:** the game and render freeze; a wait drifts with framerate
  or wall-clock; handles or logs are read before the next-frame unload/reload
  has settled.
- **Invariant:** only cooperative waits run in product code (`yield()`,
  `yield(n)`, `sleep(ms)`); the unit matches the condition (frames vs time);
  `Dev::Sleep` is reserved for a deliberate named debug freeze.
- **Evidence:** official `OpenplanetCore.json` (`yield()` = `yield(1)` next
  tick; `yield(n)` framerate-dependent, use `sleep()` for time; `sleep()`
  yields; `sleep(0)` = one frame; `yield(0)` is a no-op; `Dev::Sleep` has no
  yield description). [Document yield()/yield(n_frames)/sleep(ms) coroutine
  primitives and the Dev::Sleep main-thread hazard](https://github.com/XertroV/tm-plugin-skills/issues/17).
  Sibling `tm-change-car-color/src/Main.as:57-58` replaced a hot-loop
  `Dev::Sleep(5)` with `yield()`.
- **Reviewer probe:** search `Dev::Sleep`; classify every wait as frame-counted
  or wall-clock; after `Meta::UnloadPlugin` / `ReloadPlugin`, confirm
  `yield()`-then-re-resolve-by-ID and that compile/log waits use `yield(n)`
  settle frames.
- **Prevention/evidence gate:** no `Dev::Sleep` on product paths; wait unit
  matches the condition; lifecycle waits are frame-counted. Language primitive;
  do not add a demo that calls `Dev::Sleep`.

### Zero-progress and boundary behavior

- **Trigger:** a queue/time budget expires before processing item zero or exactly
  at zero, one, or the declared limit.
- **Symptom/impact:** negative indexing, stalled queues, skipped work, or overload
  handling throws and bypasses cleanup.
- **Invariant:** zero progress is a valid result with no item dereference; queue
  accounting remains correct at every boundary.
- **Evidence:** `tm-map-together/src/EditorFeed.as:312-343` can set processed
  count to zero and then index `pendingUpdates[processed - 1]`.
- **Reviewer probe:** test zero, one, exact limit, timeout-before-first-item,
  partial success, and queue mutation during processing.
- **Prevention/evidence gate:** guarded boundary logic and deterministic budget
  tests that prove progress accounting and cleanup.

### Mutation-result truthfulness

- **Trigger:** expected/replicated state commits or queued work is removed when a
  mutation returns control rather than when success is verified.
- **Symptom/impact:** the plugin's authoritative model diverges from Trackmania;
  reconciliation can amplify a failed or poisoned operation.
- **Invariant:** validate → apply → observe/verify → commit expected state →
  acknowledge/remove; failed application never becomes authoritative.
- **Evidence:** Map Together updates `mapTree` in `Socket.as:527-578` before
  application in `EditorFeed.as:291-343`, whose update APIs can report failure.
- **Reviewer probe:** fault each mutation and compare live state, expected state,
  queue removal, persistence, acknowledgement, and reconciliation behavior.
- **Prevention/evidence gate:** explicit operation result and commit point, plus
  failed/partial-application fault tests.

### Exception-safe scope restoration

- **Trigger:** validation counts push/pop tokens or models a separate depth
  helper without traversing the real draw/control flow.
- **Symptom/impact:** static checks pass while early return or exception leaks UI,
  clip, scissor, style, table, child, or window state into later rendering.
- **Invariant:** restoration holds on every actual exit path, not merely in token
  counts or a parallel arithmetic model.
- **Evidence:** gallery validation in `prototype.py:92-102` checks token presence;
  recipe tests model depth independently of actual draw paths.
- **Reviewer probe:** inject early return and throw after every push/begin/scissor,
  then exercise the subsequent frame/component.
- **Prevention/evidence gate:** path-sensitive analysis or runtime failure
  injection; describe token-presence checks only as weak lint.

## Confirmed additional reviewer probes

- A stored `CoroutineFunc@` called inline does not isolate UI exceptions; trace
  to an actual `startnew(...)` boundary.
- Snapshot selected values at click time. Do not pass a loop index or reread a
  mutable selection after the frame.
- After every yield, revalidate app/editor/playground/session identity and any
  borrowed object.
- Define repeated-click policy: disable, coalesce, cancel previous, queue, or
  explicitly allow concurrency.
- Give every coroutine an owner, cancellation/generation identity, and cleanup
  on success, error, timeout, unload, and mode transition.
- Record each coroutine in an ownership table: launcher, captured inputs,
  generation, cancellation condition, terminal states, cleanup site, and
  stale-commit guard.
- Reject god objects that own transport, parsing, replicated state, logs,
  persistence, and UI unless their internal boundaries are independently testable.
- Fault-inject fragmentation, partial writes, malformed lengths, overload,
  replay, reorder, drop, stale sessions, concurrent writers, and poisoned
  reconciliation in network reviews.

## Research queue

- Revalidate the captured UI-stack unwind signature and callback behavior on
  future Openplanet versions; do not generalize the 1.29.0 observation.
- Prototype a stable-ID, render-epoch, guarded-coroutine, overridable-action
  component and test repeated-click/stale-state policies.
- Build protocol fixtures for confirmed Dips++ and Map Together hazards before
  promoting specific remediation as proven.