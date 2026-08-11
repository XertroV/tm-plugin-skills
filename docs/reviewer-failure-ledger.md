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
- **Evidence:** user-observed Openplanet behavior; research Max's plugins for
  established `startnew(...)` button/action patterns and capture a minimal live
  reproduction before promotion.
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
- **Evidence:** to be expanded from Editor++, Map Together, Dips++, and other
  plugins with explicit app/editor/playground guards.
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
- **Evidence:** lifecycle dependent-closure retry gotcha; Map Together and Dips++
  packet/state architectures require dedicated comparative research.
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
- **Invariant:** ordinary exports compile into dependents; shared exports are
  reserved for intentional cross-module identity/state.
- **Evidence:** SkillpackDemoLib test-companion in-game compile failure and fix.
- **Reviewer probe:** derive actual surface from `info.toml`; test in exporting
  and dependent modules; walk nested shared types and reload order.
- **Prevention/evidence gate:** consumer-side ordinary-export tests, shared-type
  closure audit, and game/LSP compile parity.

### Network architecture mismatch

- **Trigger:** packet handling, buffering, parsing, routing, or update cadence is
  copied from another plugin with different data, reliability, ordering, or
  performance requirements.
- **Symptom/impact:** stalls, dropped updates, unbounded memory, stale state,
  head-of-line blocking, parsing ambiguity, or incorrect reconciliation.
- **Invariant:** transport and packet architecture follow explicit workload and
  consistency requirements rather than precedent alone.
- **Evidence:** Dips++ and Map Together intentionally differ; comparative source
  research is pending.
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
- **Evidence:** Bosslike's planned namespace/class architecture, reusable button
  inheritance, and mature plugin APIs require focused extraction.
- **Reviewer probe:** map ownership and dependency direction; identify mutable
  global clusters, feature-condition fan-out, callbacks without lifecycle, and
  code that cannot be tested without rendering/network/game state.
- **Prevention/evidence gate:** architecture note for nontrivial features,
  cohesive APIs, pure seams, extension tests, and a demo proving intended use.

## Research queue

- Survey all Max plugins for coroutine isolation from UI callbacks, including
  argument passing and typed temporary state carriers.
- Extract reusable button/component superclass patterns and custom `OnClick`
  overrides.
- Map Bosslike namespaces, state ownership, mode engines, and extension APIs.
- Compare Dips++ and Map Together packet framing, routing, state reconciliation,
  queueing, and performance assumptions.
- Capture the exact Openplanet UI-stack unwind log signature and a minimal safe
  live reproduction.
- Turn each confirmed mechanism into reviewer checklist items and tests/demos.