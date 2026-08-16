# Exports and architecture

Load this branch only for module boundaries, reusable libraries, dependencies,
async ownership, networking, or nontrivial plugin architecture.

## Default topology

Use one monolithic plugin unless independent deployment is worth cross-plugin
compile, load-order, reload, and lifetime costs. Prefer mature ecosystem
dependencies over reimplementing their product; declare required and optional
dependencies truthfully and exercise the missing/disabled path.

For the skill-development harness, use a reusable library plus dependent demo
plugins in category `Skillpack Demos` only when that topology itself is under
test. Load/reload the library before dependents and prove the dependent closure.

## Ordinary exports first

Ordinary `exports` are compiled into each dependent module, so every plugin
gets its own copy: the same class compiled into two plugins is a *different*
class in each and cannot match across module boundaries in signatures or
casts. Ordinary export files typically carry function `import` statements so
the dependent can call back into the dependency's own module. Prefer ordinary
`exports` for stateless helpers and classes that need no shared cross-plugin
identity. Therefore:

- test them from a dependent `Skillpack Demos` consumer;
- do not assume symbols exist in the exporting library's own module;
- list the export declaration file in `info.toml`; implementation location alone
  is not a public surface; and
- compare exact library/dependent staged bytes before live proof.

Use `shared_exports` when a type, class, or interface must be one shared
identity across plugins: to appear in cross-plugin function signatures, to be
passed or cast between plugins, or to back a single shared registration
instance. Shared state falls out of that single identity — identity is the
mechanism, state is not the reason. Audit the complete custom-type closure in
exported signatures: each plugin-defined nested return/parameter/base type must
be `shared`; game/Openplanet built-ins do not. Prove library-first load,
dependent compile, reload order, disable/unload, and cleanup. Never switch to
shared exports merely to make a test visible.

Shared-export hazards to design around (openplanet-nl/issues #65, #244, #383,
#451, #503; see `docs/openplanet-gotchas.md` "Shared exports: reload and
identity hazards"):

- prefer shared **interfaces** over shared base classes — class bodies change
  more than interfaces, and shared-class reload bugs are subtle (stale
  definitions not cleared, exception-adjacent, mode-switch triggers);
- changing a shared interface signature requires a game restart for importers
  to re-link — define it complete up front;
- reload the exporter before dependents; a "different definitions" error after
  reload often means another loaded module still references the old definition
  (e.g. an uncleared registry) — find and fix the holder, not the exporter;
- a shared type used by the exporter itself must be in `shared_exports` or the
  exporter can fail to compile while dependents succeed;
- use `export_dependencies` when your exports expose types from a transitive
  dependency.

## Ownership map for nontrivial plugins

Before feature growth, map one owner for:

- callback/runtime shell and normalized game-state snapshot;
- domain engine and environment adapters;
- UI surfaces and stable interactive identity;
- persistence/network framing and mutation truth;
- every coroutine/task/socket/hook/patch/retained nod; and
- cancellation, generation identity, stale-result checks, and teardown.

Use explicit states/enums once booleans permit invalid combinations. Separate
per-map observations from cross-map rules. Keep callbacks as adapters to an
invariant-owning engine; avoid competing normalizers, god objects, public mutable
invariants, and abandoned parallel architectures.

## Async and mutation gates

A `CoroutineFunc` called inline is still inline. Potentially throwing, yielding,
I/O, network, or multi-step mutation crosses `startnew(...)` with typed captured
state. Reacquire/revalidate after yields. Specify duplicate-launch policy and all
terminals: success, partial failure, timeout, cancellation, stale generation,
mode/map/session transition, disable, destroy, and reload.

For protocols, define exact frame grammar/consumption, maximum sizes, timeouts,
one complete-write owner, count/byte backpressure, epochs/operation IDs,
deduplication, and retry/reconciliation by traffic semantics. Probe malformed and
fragmented frames, partial writes, overload, replay/reorder/drop, stale sessions,
and concurrent writers.

## Required evidence

1. Neighboring deterministic tests in each owning/consumer module.
2. Effective dependent demos and fault controls under `Skillpack Demos`.
3. LSP plus game diagnostic parity on exact staged bytes.
4. Library/dependent load, reload, disable/unload, and cleanup transcript.
5. `openplanet-reviewer` findings-first pass with transition/fault coverage.
6. Every finding fixed, represented by a regression gate, or explicitly left as
   a labeled hypothesis/not-tested gap with its next probe.

Primary basis: approved specification, validation tiers, Openplanet `info.toml`
documentation, project testing guide, and implementation gotchas.
