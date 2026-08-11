# Skill manifest

The portable core contains six independently triggerable, model-invoked skills.
Shared capability detection and domain language remain references rather than a
seventh invocation surface.

| Skill | Trigger boundary | Completion gate |
| --- | --- | --- |
| `openplanet-init` | Scaffold, bootstrap, or normalize a plugin folder and `info.toml`. | Loadable identity plus first-load evidence or an explicit runtime blocker. |
| `openplanet-dev` | Implement or modify AngelScript behavior, structure, settings, callbacks, dependencies, or architecture. | Static diagnostics plus required lifecycle/runtime proof for behavior changes. |
| `openplanet-lifecycle` | Load, reload, unload, diagnose compilation, and prove the bytes actually running. | Fresh post-action log window plus observable behavior evidence when applicable. |
| `openplanet-visual` | Design or review ImGui/NVG/custom-draw appearance. | Fresh screenshot critique under declared states and themes, plus lifecycle proof. |
| `openplanet-control` | Drive an available RemoteBuild/control bridge capability rung. | Requested action observed, or a lower-rung attempt and explicit blocker. |
| `openplanet-reviewer` | Adversarially review a plugin, change, architecture, or release candidate for subtle runtime failure. | Evidence-backed findings cover all applicable failure classes; every high-severity concern has a repro, trace, invariant violation, or clearly labeled hypothesis and next probe. |

## Reviewer boundary

`openplanet-reviewer` is not a style linter or generic code review. It hunts for
ways a compiling plugin can fail in use:

- Trackmania and plugin state corruption or drift;
- wrong-mode and unavailable-object access;
- stale handles across map, server, editor, playground, or reload transitions;
- UI exceptions and stack unwinding that stop future rendering;
- callback reentrancy, ordering, cancellation, and cleanup failures;
- packet ordering, synchronization, retry, and performance mismatches;
- API and ownership designs that make correct change unsafe or excessively hard;
- export/module/lifetime mismatches; and
- visual/control/test paths that claim success without runtime evidence.

The installable skill executes `skills/openplanet-reviewer/SKILL.md`, consumes its
bundled `references/failure-ledger.md`, and progressively discloses bundled
project-local precedents only when a branch needs them. The repository-facing
workflow, ledger, and issue-13 research retain the full maintainer evidence base;
promotion validation prevents portable-contract and taxonomy drift.
It feeds actionable prevention back into
`openplanet-dev`, `openplanet-visual`, `openplanet-control`, tests, and demos.

## Cross-links

- `openplanet-dev` invokes reviewer guidance for nontrivial architecture, state machines, networking, risky lifecycle changes, or pre-release review.
- `openplanet-visual` invokes reviewer guidance for callback safety, stack balance, duplicate dispatch, IDs, and exception-prone UI actions.
- `openplanet-control` invokes reviewer guidance for transport bounds, action visibility, synchronization, cancellation, and shutdown.
- `openplanet-reviewer` invokes lifecycle/control/visual evidence gathering rather than inferring runtime success from source.