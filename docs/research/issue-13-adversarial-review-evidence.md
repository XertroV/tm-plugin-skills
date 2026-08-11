# Issue 13 — adversarial review evidence

This document records source-backed patterns for `openplanet-reviewer`. It is
research evidence, not a claim that every historical implementation is a
recommended template.

## UI failure containment and action APIs

### Strongest reusable component precedent

`tm-draw-tests/src/Epp/ExtraEditorMenuItem.as:8-70,114-175` defines
`ExtraMainToolbarItem`:

- owns a semantic `CoroutineFunc@ onClick`;
- keeps hit testing in `Draw()`;
- launches action execution through `startnew(CoroutineFunc(RunOnClick))`;
- catches and reports action exceptions centrally; and
- exposes overridable icon, color, tooltip, and action methods.

`MacroRecordMainToolbarItem` subclasses it and overrides behavior and
presentation. This is the strongest component architecture in the corpus, but
it is draw-test/prototype code. Refine its lifecycle, identity, busy policy, and
error API rather than copying it byte-for-byte.

### Typed click-time arguments and stale-state checks

`tm-bosslike/src/Game/Modes/SimpleRM.as:124-162` scopes a button with the map UID,
launches `CoroutineFuncUserdata(this.OnClick_PlayMap)` with the selected map,
and revalidates state after yielding before committing mutation. This is the
strongest mature precedent for a class-bound action with one object argument.

For immutable scalars, `tm-simple-room-admin/src/Interface.as:430-534` copies the
selected integer or UID into the launched coroutine. It passes the selected
value rather than a loop index that could point elsewhere later.

For multiple values, prefer a named typed carrier. Existing evidence includes:

- `tm-bosslike/src/ChangeRoomParams.as:1-11` and its validated `ref@` consumption
  in `RoomChange.as:8-23`;
- `tm-cgf-library/src/Maps.as:126-156` (`MapUidTidData`); and
- the newer but weaker positional `array<string>` snapshot in
  `tm-control-mcp/src/McpTools.as:1080-1093`.

The recommended order is: named typed request, immutable primitive or owned
object, class-bound method, named wrapper, dynamic array/JSON at protocol
boundaries, and ambient globals only as a last resort.

### Callback types do not imply coroutine isolation

Two reusable components are useful counterexamples:

- `tm-editor-ui-toolbox/src/NvgButton.as:1-40` stores callbacks but invokes
  `onClick(this)` and `onDrag(this)` inline.
- `tm-map-info/src/NvgButton.as:1-41` stores a `CoroutineFunc@` but calls it
  inline from `OnMouseClick()`.

A callback typed as `CoroutineFunc` is not isolated unless execution crosses a
real `startnew(...)` boundary.

### UI exception evidence status

Supporting code evidence exists:

- `tm-editor-plus-plus/AGENTS.md:11-12` distinguishes ordinary coroutine failure
  from UI-coroutine/bad-plugin-state failure.
- `tm-editor-plus-plus/src/UI/UI_Main.as:44-53` contains a disabled render
  exception guard and the diagnostic `UI_Main_Render exception: ...`.
- `tm-draw-tests/src/Epp/ExtraEditorMenuItem.as:40-46` reports component action
  exceptions with component identity.

No literal Openplanet engine log line saying it is unwinding/unrolling the UI
stack was found in the corpus, git history, or current log. Render-callback
cessation remains user-observed pending a controlled live reproduction. Do not
upgrade that wording to engine-verified before capturing the log and subsequent
frame behavior.

## Bosslike and mature-plugin architecture

### Thin runtime shell

`tm-bosslike/src/Main.as:6-23` owns one active `Game::Bosslike` root.
`OpenplanetCallbacks.as:5-67` keeps Openplanet callbacks thin and delegates into
that root. This makes callbacks adapters rather than the game engine.

### Domain boundaries and normalized state

The source structure separates concerns:

- `Game` and `Game::Animations` own mode and animation engines;
- `Game::Render` / `Game::Draw` own presentation helpers;
- `Maps`, `Seasons`, and `Countries` own content access;
- `TM_State.as:1-155` normalizes unstable game state and derives transition
  edges once; and
- `API/Core.as:1-14` is a narrow external-service adapter.

The reviewer should reject multiple modules independently inferring map or UI
sequence transitions when one normalized snapshot can own that truth.

### Deep engine, small policy hooks, real adapters

`Game/Bosslike.as:3-182` owns invariant lifecycle, scores, season, map changer,
and independent RNG families. `Game/Modes/SimpleRM.as:11-242` supplies concrete
policy through overrides. Independent RNG streams in `Game/RNG.as:40-57`
prevent an added draw in one subsystem from perturbing another.

`Game/State/MapChanger.as:18-130` provides a real environment seam:
`LocalMapChanger` and `RoomMapChanger` hide materially different workflows
behind one API.

`Game/State/Scores.as:183-958` separates per-map observations (`MapScores`) from
cross-map game rules (`GameScoreMgr`) and durable per-player state
(`UserGameScore`). This is a useful ownership pattern for avoiding accidental
state mixing.

### Extension architecture evidence

Editor++ demonstrates the strongest public extension surface:

- `info.toml:17-20` declares ordinary and shared exports explicitly;
- `src/Exports/Callbacks_Shared.as:15-74` defines minimal callback/data contracts
  with a lifecycle kill hook;
- `src/Exports/Callbacks.as:1-5` keeps registration narrow; and
- `src/Exports/Callbacks_Impl.as:3-317` owns indexing, dispatch, and removal.

Dips++ similarly presents small shared waiter/data contracts in
`src/Ex/Shared.as:1-48` and domain-grouped imports in
`src/Ex/FunctionImports.as:1-37`.

### Architecture erosion checks

Adversarial review should flag:

1. business/network/domain logic directly in Openplanet callbacks;
2. multiple writers or normalizers for derived game state;
3. repeated mode conditionals where policy hooks/adapters should exist;
4. coroutines without owner, cancellation/generation identity, or post-yield
   stale checks;
5. boolean combinations encoding invalid implicit workflow states;
6. global event bridges proliferating into hidden dependency cycles;
7. runtime-throw placeholders used as unenforced abstract methods;
8. parallel arrays requiring lockstep registration/removal edits;
9. god classes owning transport, parsing, users, UI, logs, and persistence;
10. UI replacing engine dependencies directly instead of sending commands;
11. public mutable fields that let callers violate owner invariants;
12. abandoned competing state models and large commented-out workflows;
13. intended public extension without manifest-backed exports and lifecycle; and
14. resource cleanup that occurs only on successful coroutine completion.

Map Together's `Socket.as` is a useful god-object warning: its connection owns
transport, room/session data, players, logs, map state, and UI models. COTD HUD's
many perpetual workflows in `DataManager.as:51-278` show why namespace locality
alone does not establish ownership or cancellation.

## Dips++ versus Map Together networking

### Workload distinction

Dips++ is a resilient asynchronous API/session client. It sends telemetry,
queries, and replaceable snapshots where reconnect/session resume and protocol
evolvability matter more than frame latency. Its `DD2API` root owns transport,
queue, handlers, session token, and reconnect generation
(`Server/Server.as:75-293`). It uses JSON envelopes and sampled cadence.

Map Together replicates ordered, non-commutative collaborative editor actions.
Dropped or duplicated place/delete operations can permanently diverge maps. Its
room connection owns binary protocol and replicated state, while the editor
coroutine applies persistent actions in order and under a frame-time budget
(`Socket.as:24-75,521-602`; `EditorFeed.as:255-395`). It keeps ephemeral
cursor/vehicle updates separate from persistent edit operations and reconciles
an expected map octree against live editor state (`EditorFeed.as:417-500`).

This difference is architectural, not stylistic. Never transplant protocol code
without first classifying data, consistency, loss consequence, cadence, and
recovery requirements.

### Confirmed Dips++ hazards

- Inner JSON length is not required to equal the outer frame remainder;
  malformed input can cross frame boundaries (`Server/Socket.as:183-195`).
- One `RawMessage` is reused and parse failure does not clear `msgJson`, allowing
  stale payload dispatch (`Socket.as:97-98,148-150,190-201`).
- Send-queue entries are removed even when write reports failure
  (`Socket.as:159-168`; `Server.as:284-290`).
- The queue survives reconnect without freshness/epoch classification
  (`Server.as:154-165,266-293`).
- A connect timeout retries without closing/nulling the previous socket
  (`Socket.as:31-49`).

Overlapping reconnect owners and stale cache responses are evidence-backed
risks but remain inferred until fault-injection proves the consequences.

### Confirmed Map Together hazards

- Framing assumes a fixed 46-byte metadata tail although it contains a
  variable-length player ID (`Socket.as:3,841-846,1121-1131`).
- Unknown types discard a hard-coded 46 bytes (`Socket.as:896-900,1027-1059`).
- Frames are written through multiple independent socket writes and most return
  values are ignored (`Socket.as:441-519`).
- Multiple coroutines write the same socket without one writer queue
  (`EditorFeed.as:115-230,575-597`; `Socket.as:237-253`).
- No operation ID, room epoch, sequence, or deduplication field is visible in
  the client framing.
- Expected `mapTree` advances before editor application succeeds
  (`Socket.as:566-574`; `EditorFeed.as:291-343`).
- Persistent update queue growth is effectively unbounded under sustained load
  (`Socket.as:561`; `EditorFeed.as:259-343`).
- `PlayerEphemUpdates.as:106-108` compares `cur_obj != cur_obj`, so an
  object-name-only change cannot trigger that branch.

Server behavior was outside this research. Claims about authorization,
acknowledgement, replay, or server ordering remain unknown unless client framing
proves their absence.

## Required adversarial network probes

Use a controllable TCP proxy/server fixture and assert raw stream alignment plus
final semantic state:

- fragment every boundary and delay final bytes across timeouts;
- force partial writes and ambiguous hangup;
- burst beyond queue/application capacity;
- mutate all declared lengths and metadata sizes;
- duplicate/replay every operation class;
- logically reorder state across reconnect/session resume;
- drop one persistent edit while later edits continue;
- delay an old connection's response until a new generation is active;
- trigger every writer in one scheduling window; and
- poison expected map state before automatic reconciliation.

Recommended protocol invariants are one framed-write owner, exact frame
consumption, explicit limits, clear decode failure, session/room epoch,
sequence/operation IDs, traffic-class-specific retry/coalescing semantics, and
fixture tests for malformed framing, reconnect ambiguity, replay, and overload.
