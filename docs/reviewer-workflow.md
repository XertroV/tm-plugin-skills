# Openplanet adversarial reviewer workflow

This is the execution algorithm for `openplanet-reviewer`. Apply mechanisms to
the plugin's actual ownership and state model; do not begin by mechanically
labeling code with failure classes.

## Evidence grades

Report each claim as one of:

1. **Demonstrated** — reproduced with a runtime trace, log, screenshot, state
   observation, or deterministic fault fixture.
2. **Confirmed source invariant violation** — the unsafe path is provable from
   source, while runtime impact may still need demonstration.
3. **Hypothesis** — plausible mechanism with one concrete next probe.

Static diagnostics and token-presence checks never prove runtime behavior.

## Algorithm

1. **Pin scope and evidence level.** Declare source-only, live-capable, release,
   architecture, visual, or protocol review. Record unavailable probes.
   Completion: the report cannot silently imply stronger evidence than was run.
2. **Derive topology.** Inspect `info.toml`, dependencies, exports/shared exports,
   generated versus canonical source, and all Openplanet entry callbacks.
   Completion: every runtime entry and module boundary is accounted for.
3. **Map ownership.** Record root objects, mutable globals, sockets, tasks,
   coroutines, patches/hooks, retained nods, UI surfaces, and teardown owners.
   Completion: every long-lived resource has one named owner or a finding.
4. **Model state machines.** Include app/editor/playground/map/server/session
   generation, connection stages, and every loading/busy state with legal
   success/error/timeout/cancel terminals. Completion: invalid combinations and
   nonterminal exits are identifiable.
5. **Enumerate asynchronous boundaries.** For every callback and coroutine,
   record captured inputs, yields, reacquisition, generation checks,
   repeated-launch policy, cancellation, terminal assignment, and cleanup.
   Completion: every launch has an ownership-table row.
6. **Audit temporary mutations transactionally.** Trace every UI stack scope,
   patch, hook, intercept, editor-mode change, `MwAddRef`, retained task, and
   borrowed nod across all exits. Completion: restoration/release is proven or
   faulted on success, return, throw, cancel, unload, and transition.
7. **Trace UI event call graphs.** Keep cheap local nonthrowing assignments
   inline; isolate throwing, yielding, I/O, network, filesystem, game mutation,
   and dynamic callbacks. Completion: each risky branch has a real coroutine
   boundary and a failure probe.
8. **Trace mutation truth.** Model receive/compute → validate → queue → apply →
   observe/verify → commit expected state → acknowledge/remove. Completion:
   expected state cannot advance on failed or partial application.
9. **Characterize protocol semantics when applicable.** Document frame grammar,
   exact consumption, size bounds, one writer, queue count/byte bounds, overflow,
   zero-progress handling, epochs/IDs, replay/retry, and traffic classes.
   Completion: every field and failure policy is explicit.
10. **Run boundary probes first.** Null/empty, zero work, one item, exact limit,
    timeout before progress, partial success, duplicate launch, and teardown
    during wait. Completion: every applicable boundary has evidence or is
    explicitly not tested.
11. **Run the transition/fault matrix.** Cross map/mode/session/reload transitions
    with pending UI action, request, packet, patch, and retained object. For
    network code add fragmentation, partial writes, malformed frames, overload,
    replay, reorder, drop, stale session, concurrent writers, and poisoned
    reconciliation. Completion: no applicable row is silently omitted.
12. **Assess architecture after mechanisms are known.** Find ownership conflicts,
    duplicate normalizers, god objects, hidden cycles, mutable invariant leaks,
    and untestable seams. Completion: architecture findings cite concrete
    maintenance or correctness impact rather than aesthetics.
13. **Report findings first.** For each: severity, `path:line`, trigger,
    mechanism, impact, evidence grade, next probe, and ledger class. Include
    positive evidence only after findings.
14. **Close coverage.** Mark every ledger class caught, not applicable, or not
    tested. Add each new mechanism to the ledger and feed prevention into normal
    development guidance plus tests/demos where applicable.

## False-positive controls

- Cheap local UI state changes need no coroutine when they cannot throw or yield.
- A cached handle is acceptable when owner and generation bounds are explicit.
- Multiple socket writes require a finding only when sole-writer/order/full-write
  semantics are absent or unproven.
- A runtime-throw placeholder is actionable only when a reachable concrete type
  can retain the base implementation.
- Token matching is useful weak lint; label it as such.

## Output skeleton

```markdown
## Findings
### [severity] Finding title
- Path: `path:line`
- Trigger:
- Mechanism:
- Impact:
- Evidence grade:
- Next probe:
- Ledger class:

## Coverage
| Failure class | Caught / N/A / Not tested | Evidence |

## Positive evidence
## Runtime gaps
```