# Validation tiers and completion evidence

Validation is cumulative: a higher tier includes all applicable lower-tier gates.
A missing tool lowers the claim, not the standard. Record the unavailable probe,
its cause, and the next action needed to run it.

## Evidence labels

- **Static** — repository checks, generation checks, and `openplanet-lsp`.
- **Compiled** — fresh Openplanet compile/load transcript for the exact staged bytes.
- **Exercised** — behavior-specific smoke or automated `[Test]` execution.
- **Observed** — fresh logs, state reads, screenshots, or deterministic captures.
- **Adversarial** — boundary/transition/fault probes with evidence-graded findings.

Never translate static success into a runtime claim.

## Tier 0 — ordinary guidance

Applies to prose, API advice, and non-copyable illustrative fragments.

Required:

1. Primary-source or repository evidence for non-obvious API/behavior claims.
2. Explicit game/version scope and dependency assumptions.
3. No fabricated provenance. Bosslike/new snippets may omit provenance; copied or
   adapted public snippets retain source and compatible license.
4. Links and referenced paths resolve.
5. Code that is not exercised is labeled **candidate**, not proven recipe.

Completion claim: guidance is source-backed; no runtime claim.

## Tier 1 — copyable component or snippet

Applies to code intended for direct reuse.

Required:

1. Tracked initialization brief for its temporary/demo plugin.
2. Incremental integration into a plugin in category `Skillpack Demos`.
3. Static/repository checks and `openplanet-lsp` for exact staged bytes.
4. Fresh in-game compile/load transcript, including warnings/deprecations.
5. Behavior-specific smoke with visible or logged proof.
6. Neighboring `[Test]` companion when deterministic/testable, using
   `[Test] void Name(Tests::Context@ ctx)` and a real deterministic seam.
7. Applicable gotchas and reviewer classes represented by implementation,
   automated gate, live evidence, or reviewed N/A.

Completion claim: compiled and behavior-smoked on the declared Openplanet/game
version. No visual-quality or broad fault-tolerance claim unless separately run.

## Tier 2 — advanced recipe or reusable component family

Applies to lifecycle-sensitive UI/NVG, exports, remote control, networking,
editor mutation, asynchronous state, and multi-file reusable APIs.

Includes Tier 1 plus:

1. Ordinary-export consumer test; `shared_exports` only for types/interfaces
   requiring one identity across modules, with shared-type closure and
   reload-order checks.
2. Ownership/state-machine note covering callbacks, coroutines, generations,
   terminal states, resources, and teardown.
3. Boundary and transition probes: null/empty, zero/one/exact limit, timeout,
   partial success, duplicate launch, map/mode/session/reload transition, unload.
4. UI: stable explicit IDs, one render owner per overlay state, scope balance,
   theme preservation, and fresh screenshot review when visible.
5. Control: DEV-only, opt-in, localhost, bounded framing/timeouts, single-flight
   mutation, explicit shutdown, no secrets/arbitrary code, `force=false`, and
   truthful cause/next-step envelopes for invisible controls.
6. Network: exact frame consumption, one writer or proven equivalent, byte/count
   backpressure, malformed/fragmented/partial-write tests, epochs/IDs and
   traffic-class retry/reconciliation policy where required.
7. `openplanet-reviewer` findings-first pass; high severity is demonstrated,
   source-proven, or a labeled hypothesis with concrete next probe.

Completion claim: reusable under the tested states and failure matrix only.

## Tier 3 — promoted skill and skillpack release

Applies to installable skills and release candidates.

Includes all applicable component tiers plus:

1. Agent Skills frontmatter/name/link validation and progressive disclosure.
2. `agents/openai.yaml` invocation-policy parity.
3. `claude plugin validate . --strict`.
4. `npx skills@latest add . --list` discovers exactly the promoted set.
5. README, manifest, plugin metadata, filesystem, and version/license sets agree.
6. Every promoted recipe has current compile, behavior, test, and screenshot
   evidence where applicable; no candidate is presented as promoted.
7. Full diagnostics comparison: LSP versus game acceptance, reasons, locations,
   severity, warnings, and deprecations. File minimal LSP repros for drift.
8. Independent adversarial review of skill instructions and at least one real
   dogfood target; newly found mechanisms feed the ledger and regression/demo.
9. Trackmania 2020 runtime claims name Openplanet version/channel and exact
   evidence. Other games remain unverified unless separately exercised.
10. Experimental/local-only capabilities are labeled and excluded from public
    enablement by default.

Completion claim: installable, internally consistent, and validated to the
recorded matrix. Store submission/publication remains a separate human boundary.

## Per-increment loop

For every new or changed component:

1. update the adjacent test and live demo/fault fixture;
2. regenerate/stage exact bytes;
3. run repository/static checks and preserve all diagnostics;
4. compile/load in game and preserve the fresh log window;
5. exercise behavior and inspect visible/logged state;
6. compare LSP/game diagnostics, including warnings/deprecations;
7. run applicable reviewer boundary/transition probes; and
8. record evidence before building the next increment.

Do not defer all runtime integration to a final pass.

## Missing-tool degradation

| Missing capability | Allowed result | Forbidden claim |
| --- | --- | --- |
| `openplanet-lsp` | In-game compile plus explicit static-tool gap | Static parity |
| Running Openplanet/game | Candidate/static evidence only | Runtime correctness |
| Screenshot capture | Compiled behavior evidence; visual work incomplete | Visual quality/theme proof |
| Remote/control bridge | Manual lower-rung smoke and explicit blocker | Automated state/control proof |
| In-game `[Test]` invocation | Test source compiles; execution remains unrecorded | Test pass |
| Fault fixture/proxy | Source invariant or hypothesis with next probe | Demonstrated resilience |

Tool absence never converts “not tested” into success.

## Evidence report format

Record:

- component/skill and exact version or commit;
- staged source identity/digest where generated;
- Openplanet and game version/channel;
- commands and full diagnostic outcome;
- fresh log window/capture paths;
- behavior states and theme/overlay state;
- reviewer evidence grade and uncovered probes; and
- concise next action.

After an ad-hoc verification report, print `---` and a concise statement of what
happens next.