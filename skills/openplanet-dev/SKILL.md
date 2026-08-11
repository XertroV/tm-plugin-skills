---
name: openplanet-dev
description: Use when implementing or changing Openplanet AngelScript behavior, structure, settings, callbacks, dependencies, deterministic seams, or plugin architecture.
license: CC0-1.0 OR Unlicense
compatibility: Requires an existing Openplanet plugin folder rooted at info.toml. openplanet-lsp and a running Openplanet improve evidence; missing capabilities lower the claim rather than the standard.
metadata:
  author: XertroV
  version: "0.1.0"
---

# Openplanet development

## Purpose

Implement behavior in an existing Openplanet plugin without mistaking source or
LSP success for a running change. Work in small increments whose tests, effective
`Skillpack Demos` surface, diagnostics, exact staged bytes, and live evidence grow
together.

Use `openplanet-init` first when no coherent plugin folder or initialization brief
exists. Use `openplanet-visual` when appearance is the primary task and
`openplanet-control` when driving the live game is the primary task.

## Workflow

### 1. Discover the real plugin

Locate `info.toml`; read project instructions and the tracked initialization
brief. Detect rather than assume:

- live-folder versus staged-source topology;
- canonical versus generated source;
- project build/staging commands;
- dependency root and target game/Openplanet scope;
- `openplanet-lsp`, lifecycle, RemoteBuild, control, and screenshot capabilities;
- module, `exports`, `shared_exports`, and dependent plugins.

Prefer project tooling when present. Default an ordinary project to one plugin
module; add cross-plugin topology only when its dependency and lifetime costs are
justified. Prefer ordinary exports; reserve `shared_exports` for APIs that truly
require shared cross-plugin identity or state.

**Gate:** the canonical source, runtime staging destination, capabilities, and
validation path are explicit before editing.

### 2. Define one observable increment

State the requested behavior, deterministic seam, live observation, affected
callbacks/resources, and applicable gotcha/reviewer failure classes. Search
current official docs and provenance-cleared project/sibling precedents before
inventing an API pattern. Treat research, commented-out code, and unvalidated
snippets as candidates, not recipes.

For copied/adapted public code, retain source and compatible license. Never
fabricate provenance. Audit bundled fonts, images, audio, and other assets
separately.

**Gate:** the increment has a falsifiable acceptance condition and a named live
surface or a reviewed demo N/A rationale.

### 3. RED-GREEN-REFACTOR where deterministic

For deterministic behavior, use strict **RED-GREEN-REFACTOR**:

1. **RED:** create or update the neighboring `Feature_Test.as` beside
   `Feature.as`; run the focused in-game test and preserve the expected failure
   with file/test attribution.
2. **GREEN:** implement the smallest deterministic seam that makes the focused
   test pass; run it twice and confirm expected names/counts.
3. **REFACTOR:** improve ownership and boundaries while the focused test remains
   green, then run reload-and-test and the broader applicable suite.

Use `[Test] void Name(Tests::Context@ ctx)` in `namespace Tests`, descriptive
messages, and actual-before-expected assertions. Keep tests synchronous and
order-independent; reset mutated globals and never retain `Tests::Context@`.
Extract callback/state logic into pure seams instead of invoking rendering APIs
from ordinary tests.

If behavior is genuinely nondeterministic or engine-only, record why RED is not
mechanically available and use a deterministic fault fixture or live probe. A
reviewed N/A is not permission to omit live evidence.

**Gate:** every deterministic changed feature has its adjacent companion and a
recorded red-to-green result; every exception has a concrete substitute probe.

### 4. Grow the effective demo in the same change

Expose every changed component or behavior through an effective plugin surface
in category `Skillpack Demos`. Visual components must be reachable from one
authoritative shared gallery with deterministic states. Nonvisual behavior uses
controls, state readouts, exact expected text, logs, or deterministic fault
buttons that make its contract inspectable. Mark demo coverage N/A only after
review when another surface is genuinely clearer.

Conceptual demos state what is simulated, show branch/owner decisions, display
the expected invariant, and label PASS/FAIL. Keep temporary fault probes only
long enough to preserve evidence and feed the mechanism into guidance/tests.

**Gate:** the changed behavior is reachable and self-explanatory in the effective
`Skillpack Demos` surface, or its reviewed N/A is recorded.

### 5. Implement with explicit ownership

Keep callbacks thin. Give each UI surface, mutable state, coroutine, task, socket,
hook/patch, retained nod, and cleanup path one owner. Keep potentially throwing,
yielding, networked, filesystem, or multi-step game mutation behind a real
`startnew(...)` boundary rather than calling a coroutine-typed callback inline.
Snapshot typed inputs, revalidate generations/state after yields, and define
success, failure, timeout, cancellation, stale-result, and unload terminals.

Interactive controls use stable explicit IDs. One callback owns each rendered
surface per overlay state; balance every UI/style/clip scope on all paths.

When a subtle failure is found, capture trigger, symptom/impact, violated
invariant, exact evidence, reviewer probe, and prevention gate. Label hypotheses
and their next probe. Feed confirmed mechanisms into the neighboring test, demo
or fault fixture, and development guidance before proceeding.

Load [exports and architecture](references/exports-and-architecture.md) when the
increment affects module boundaries, dependencies, async ownership, networking,
or nontrivial architecture.

**Gate:** ownership, terminal states, teardown, and applicable gotcha/reviewer
feedback are represented in code and evidence rather than left as prose debt.

### 6. Check LSP and game parity on exact bytes

Follow [the incremental test and demo loop](references/test-demo-loop.md). Build
or generate deterministically, identify the staged source, and prove it is
byte-for-byte the source checked by `openplanet-lsp` (for example with `cmp` or a
recorded digest). Load that exact staging output; never validate one tree and run
another.

Preserve both LSP and Openplanet acceptance, reasons, locations, severities,
warnings, and deprecations. Game compilation is runtime ground truth but does not
erase parity gaps. File the smallest known LSP reproduction when game and LSP
differ materially.

**Gate:** exact-byte identity and the complete diagnostics comparison are
recorded, or unavailable capabilities are explicit blockers to the stronger
claim.

### 7. Require lifecycle proof

Invoke `openplanet-lifecycle` after every behavior-affecting increment. Require a
fresh post-action `Openplanet.log` window showing the plugin loaded with no later
compile error for it, then exercise the observable behavior. Run focused tests,
reload-and-test where initialization matters, and applicable teardown/reload or
dependent lifecycle checks. Rendering changes additionally require
`openplanet-visual` and fresh screenshot critique.

Tool absence lowers the supported claim: without a running game the result is a
candidate/static change, not runtime-correct; without test invocation, test
source only compiled and did not pass.

**Completion gate:** requested source behavior, adjacent deterministic tests,
effective demo evidence, exact-byte LSP/game comparison, applicable reviewer
feedback, and lifecycle proof all close for the increment. Otherwise report the
specific blocker and next probe; do not claim completion.

## Escalate to adversarial review

Invoke `openplanet-reviewer` for nontrivial architecture, state machines,
networking, exports/shared identity, risky lifecycle or game mutation, or a
pre-release change. Apply findings by severity and evidence grade. A high-severity
hypothesis remains open until its concrete next probe runs or is explicitly
recorded as not tested.
