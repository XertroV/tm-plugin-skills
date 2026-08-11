---
name: openplanet-reviewer
description: Use when adversarially reviewing an Openplanet plugin for subtle runtime, state, lifecycle, UI, synchronization, protocol, or architecture failures.
license: CC0-1.0 OR Unlicense
compatibility: Requires access to the plugin source. Live Openplanet, Openplanet.log, openplanet-lsp, and control tooling improve evidence but are not mandatory.
metadata:
  author: XertroV
  version: "0.1.0"
---

# Openplanet reviewer

## Purpose

Find ways an AngelScript plugin can compile and still fail in real use. Review
mechanisms and invariants, not style. Prefer demonstrated runtime evidence;
separate source-proven violations from hypotheses.

## When to use

Use for plugin/change/release reviews involving game or plugin state, mode
assumptions, callbacks, coroutines, UI, networking, exports, teardown, or
nontrivial architecture.

Use ordinary code review instead for formatting, naming, or generic maintainability
that has no Openplanet-specific failure mechanism.

## Evidence grades

Label every finding:

1. **Demonstrated** — runtime trace, log, screenshot, state observation, or
   deterministic fault fixture reproduces it.
2. **Confirmed source invariant violation** — the path is provably unsafe, while
   runtime impact may remain unobserved.
3. **Hypothesis** — plausible mechanism with one concrete next probe.

Static diagnostics and token-presence checks are not runtime proof.

## Workflow

1. **Pin scope.** Declare source-only, live-capable, architecture, protocol,
   visual, or release review. Record unavailable probes. Completion: the report
   cannot imply stronger evidence than was gathered.
2. **Map topology.** Inspect `info.toml`, dependencies, ordinary/shared exports,
   canonical/generated sources, and every Openplanet callback. Completion: every
   runtime entry and module boundary is accounted for.
3. **Map ownership.** Identify root objects, mutable globals, sockets, tasks,
   coroutines, patches/hooks, retained nods, UI surfaces, and teardown owners.
   Completion: every long-lived resource has one owner or a finding.
4. **Model state and generations.** Include app/editor/playground/map/server/
   session identity and every loading/busy state with success, error, timeout,
   and cancellation terminals. Completion: invalid combinations and nonterminal
   exits are visible.
5. **Audit async boundaries.** For every callback/coroutine, record captured
   inputs, yields, reacquisition, generation checks, repeated-launch policy,
   cancellation, terminal assignment, and cleanup. Completion: every launch has
   an ownership row.
6. **Audit temporary mutation.** Trace UI scopes, patches, hooks, editor modes,
   `MwAddRef`, retained tasks, and borrowed nods through success, return, throw,
   cancel, unload, and transition. Completion: restoration is proven or found
   missing.
7. **Trace UI action call graphs.** Cheap local nonthrowing assignments may stay
   inline. Isolate work that can throw, yield, perform I/O, invoke dynamic
   callbacks, or mutate game state behind a real `startnew(...)` boundary.
   Completion: each risky path has containment and a failure probe.
8. **Trace mutation truth.** Follow validate → queue → apply → observe/verify →
   commit expected state → acknowledge/remove. Completion: expected state cannot
   advance after failed or partial application.
9. **Characterize protocols when applicable.** Record exact frame grammar,
   consumption, limits, sole-writer policy, queue count/byte bounds, overflow,
   epochs/IDs, retry/replay, and traffic classes. Completion: failure semantics
   are explicit.
10. **Probe boundaries before happy paths.** Cover null/empty, zero, one, exact
    limit, timeout-before-progress, partial success, duplicate launch, and
    teardown-during-wait.
11. **Run transition/fault matrices.** Cross map/mode/session/reload transitions
    with pending UI actions, requests, packets, patches, and retained objects.
    For networks add fragmentation, partial writes, malformed frames, overload,
    duplicate/replay/reorder/drop, stale session, concurrent writers, and
    poisoned reconciliation.
12. **Assess architecture last.** Report ownership conflicts, duplicate
    normalizers, god objects, hidden cycles, mutable invariant leaks, or
    untestable seams only with concrete correctness or change-safety impact.
13. **Close coverage.** Mark each applicable failure class caught, N/A, or not
    tested. Feed new mechanisms into development guidance and tests/demos.

Load `${CLAUDE_SKILL_DIR}/references/failure-ledger.md` to select failure classes.
Load `${CLAUDE_SKILL_DIR}/references/evidence-precedents.md` only when a branch
needs concrete Openplanet precedents or fault probes.

## UI containment invariant

A callback merely typed `CoroutineFunc` is still inline unless execution crosses
`startnew(...)`. Snapshot click-time values in typed carriers and revalidate
state after yields. Openplanet 1.29.0 live evidence showed an isolated coroutine
exception left render heartbeats running, while an exception escaping
`RenderInterface()` logged `Unrolling dangling script UI stack` and no later
plugin heartbeat.

## False-positive controls

- Cheap local UI state changes need no coroutine when they cannot throw or yield.
- Cached handles are acceptable with explicit owner and generation bounds.
- Multiple socket writes are findings only when sole-writer/order/full-write
  semantics are absent or unproven.
- Runtime-throw placeholders matter only when a reachable concrete type can
  retain the base behavior.
- Token matching is weak lint; label it as such.

## Output

Report findings first, ordered by severity. Each finding includes:

- severity and title;
- `path:line`;
- trigger, mechanism, and impact;
- evidence grade;
- next probe when not demonstrated; and
- failure-ledger class.

Then include a coverage table, positive evidence, and runtime gaps. Never hide a
high-severity hypothesis among stylistic notes.

## Verification

Before concluding:

- every runtime entry and long-lived resource is accounted for;
- every async operation has all terminal states and cleanup;
- every applicable transition/fault row has evidence or “not tested”;
- source and runtime claims use the correct evidence grade;
- LSP success is not presented as in-game proof;
- live behavior changes use fresh `Openplanet.log` and observable evidence; and
- newly discovered failure mechanisms are proposed for the ledger and a
  regression test or live fault fixture where deterministic.

After any ad-hoc verification report, print `---` and one concise sentence stating
what happens next.
