---
name: openplanet-init
description: Use when scaffolding a new Openplanet plugin, creating its first info.toml, normalizing a cloned template or plugin folder, or onboarding a young plugin before feature work.
license: CC0-1.0 OR Unlicense
compatibility: Requires filesystem access to the plugin source. Openplanet and Openplanet.log are required for first-load evidence; their absence is recorded as an explicit runtime blocker.
metadata:
  author: XertroV
  version: "0.1.0"
---

# Openplanet initialization

## Purpose

Create or normalize one plugin folder rooted at `info.toml`, record its durable
intent and policy assumptions, and prove its identity can load. This workflow
ends at initialization; feature implementation belongs to `openplanet-dev`.

## Workflow

1. **Search existing plugins before scaffolding.** Establish the intended purpose
   and target game, then use [existing-plugin discovery](references/plugin-discovery.md)
   and its bundled catalog helper to search names, summaries, and likely synonyms.
   Inspect plausible matches for equivalent features or reusable dependencies.
   Completion: the brief records search terms, catalog date/coverage, linked
   candidates, and the reason to reuse, extend, or build separately. A stale or
   unavailable catalog is an explicit discovery limitation, never evidence that
   nothing exists. Respect an author's deliberate decision to build an alternative.
2. **Locate the plugin folder.** Find the repository instructions and
   `info.toml`. Determine whether the repository is already a live Openplanet
   plugin folder or stages canonical source elsewhere. For a new plugin, choose
   the folder that will own `info.toml`. Completion: one canonical source root
   and its relationship to the live `Plugins/` tree are known.
3. **Run the simple interview.** Copy
   [the initialization brief template](templates/INITIALIZATION-BRIEF.md) into a
   tracked project document and complete every required field. Apply the
   [policy boundary](#policy-boundary) before choosing publication intent. A tracked
   initialization brief is mandatory for every plugin, including a tiny,
   temporary, or local-only experiment. Completion: purpose, game scope,
   publication intent, rights/disclosure assumptions, topology, and the smallest
   observable first-load gate have explicit answers.
4. **Branch only when relevant.** Complete advanced brief sections for assets,
   dependencies, exports or multiple modules, build/staging tools, preprocessor
   defines, authentication/public configuration, and packaging. Default to one
   plugin module unless a dependency boundary is justified. Completion: each
   applicable branch is answered and each inapplicable branch is marked N/A.
5. **Record clone-local capabilities.** Follow
   [onboarding and local-state guidance](references/onboarding-and-local-state.md).
   Store machine paths, ports, detected tools, and runtime receipts in a private
   checkout-local file listed in `.git/info/exclude` when Git metadata exists;
   otherwise use external private state outside the plugin folder. Never write secrets to the
   tracked brief, clone-local state, `info.toml`, logs, prompts, or commits.
   Completion: portable decisions are tracked; local capabilities are excluded
   from tracked/public plugin files;
   secrets remain only in their proper secret store.
6. **Create the minimal loadable identity.** Preserve a valid existing manifest
   when normalizing. Otherwise create the smallest `info.toml` and AngelScript
   entrypoint appropriate to the recorded game and current Openplanet
   documentation. Keep identity, category, script paths, dependencies, and
   defines consistent with the brief. Use `Skillpack Demos` only for skillpack
   development/demo plugins. Completion: every manifest script path resolves to
   canonical or deterministically staged source and a minimal entrypoint exists.
   Use a real version/name/author/category, justify game/timeout constraints, and
   do not set `essential`, `controls_other_plugins`, or deprecated `meta.perms`
   without a concrete requirement supported by current Openplanet documentation.
7. **Check exact bytes.** Run available repository checks and `openplanet-lsp` on
   the exact source that will be loaded. If staging exists, compare staged bytes
   with canonical/generated inputs and record the command and result in local
   state. Completion: static failures are fixed or reported as explicit blockers;
   static success is not called runtime proof.
8. **Prove the first load.** Use the highest available lifecycle capability while
   preserving the manual Openplanet UI and `Openplanet.log` fallback. Capture a
   fresh post-action log window showing a `Loaded plugin` event for this identity
   with no later compilation error for it, plus the brief's smallest observable
   check. This is first-load evidence. If runtime access is unavailable or load
   fails, record the attempted rung, exact cause, and next action as an explicit
   runtime blocker. Completion: first-load evidence or an explicit runtime
   blocker exists; “not tested” is never reported as a pass.
9. **Stop at the boundary.** Report the initialized identity, tracked brief path,
   excluded local-state path, diagnostics, and runtime evidence/blocker. Hand
   later AngelScript behavior to `openplanet-dev`; use `openplanet-lifecycle` for
   further load/reload diagnosis. Do not add settings, UI, control bridges,
   architecture, or product features merely to make initialization look complete.

## Policy boundary

**Openplanet rejects plugins whose code is mostly AI generated** from its website
and plugin manager. The [Plugin terms of service](https://openplanet.dev/docs/plugin-tos)
grant no exceptions for programming experience, directing the LLM, successful
in-game testing, or token spend. Explain this before generating code for a public
candidate and record the publication constraint in the brief. Tests, human
review, and disclosure do not create an exception. Other AI use must be disclosed
during review; AI-generated plugin thumbnails are prohibited.

Apply the brief's safety, rights, provenance, AI-use, paid-feature permission,
and publication questions before feature code. `local-only` or
`do-not-publish` is a distribution decision, not permission for infringement,
paid-feature bypass, harmful exploitation, review evasion, or false disclosure.
Keep upload, signing, attestation, terms assent, approval, and publication as
human-controlled actions. Recheck volatile policy before any later submission.

## Verification

Initialization is complete only when:

- existing-plugin discovery and the reuse/extend/build decision are recorded,
  including any catalog limitation;
- one plugin folder rooted at a valid `info.toml` has a resolvable minimal script
  entrypoint;
- the tracked initialization brief exists even for tiny/local-only work;
- applicable advanced branches are resolved without speculative architecture;
- clone-local receipts are private through `.git/info/exclude`, or external
  private state is used when the plugin folder is not a Git checkout;
- no secret was written into project or agent artifacts;
- checks ran against the bytes intended for loading; and
- fresh first-load evidence exists, or the result names an explicit runtime
  blocker with the attempted action and next step.
