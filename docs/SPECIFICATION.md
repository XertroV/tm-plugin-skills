# Openplanet agent skillpack specification

**Status:** approved implementation baseline

**Runtime depth:** Trackmania 2020 on explicitly recorded Openplanet versions
**License:** `CC0-1.0 OR Unlicense`

## 1. Goal

Ship a portable, evidence-driven Agent Skills package that helps individual
Openplanet authors initialize, implement, load, validate, visually refine,
control, and adversarially review AngelScript plugins without confusing static
success with live runtime proof.

## 2. Audience and scope

Primary users range from first-time plugin contributors to experienced authors.
The shared core is game-neutral where Openplanet APIs overlap. Version one makes
deep runtime claims only for Trackmania 2020 evidence actually captured.

The starting unit is a plugin folder rooted at `info.toml`. Detect build scripts,
staging, RemoteBuild, lifecycle bridges, and control tools; do not assume them.
Default to one plugin module unless the user accepts cross-plugin dependency and
lifetime costs.

## 3. Skill boundaries

The portable core has six independently triggerable model-invoked skills:

| Skill | Owns | Completion boundary |
| --- | --- | --- |
| `openplanet-init` | scaffold/normalize plugin identity, policy onboarding, initialization brief, clone-local capability state | loadable identity plus first-load evidence or explicit blocker |
| `openplanet-dev` | AngelScript behavior, architecture, settings, dependencies, callbacks, deterministic seams | diagnostics plus applicable live behavior evidence |
| `openplanet-lifecycle` | stage/load/reload/unload, dependent closure, fresh log windows, bytes-running proof | post-action transcript plus observable behavior |
| `openplanet-visual` | theme-respecting ImGui, provenance-cleared NVG, opt-in custom composition, screenshot critique | fresh capture under declared states/themes and lifecycle proof |
| `openplanet-control` | capability ladder and optional bounded DEV-only semantic action router | observed action or lower-rung attempt with explicit blocker |
| `openplanet-reviewer` | findings-first adversarial runtime/state/lifecycle/UI/protocol/architecture review | applicable failure-class coverage with evidence grades and next probes |

Shared capability detection and domain vocabulary are references, not a seventh
invocation surface. Development and visual work finish through lifecycle proof;
review invokes lifecycle/control/visual evidence rather than inferring success.

`docs/skill-manifest.md` is the concise boundary source. The already promoted
`openplanet-reviewer` is the reference implementation for skill shape.

## 4. Domain invariants

1. **Exact bytes:** validate and load the same staged source. Generated artifacts
   must be deterministic and traceable to canonical source/manifest.
2. **LSP plus game:** run `openplanet-lsp`, then compile/load in Openplanet.
   Preserve and compare acceptance, reasons, locations, severities, warnings,
   and deprecations.
3. **Incremental live development:** every changed component expands adjacent
   deterministic `[Test]` coverage where possible and live demo/fault evidence
   before later work builds on it.
4. **Demo topology:** development plugins use category `Skillpack Demos` and a
   tracked initialization brief.
5. **Exports:** prefer ordinary `exports`; use `shared_exports` only when a type
   or interface must be one shared identity across plugins (cross-module
   signatures, passing, casts, or a single shared instance) and prove
   dependent/reload topology in game.
6. **Rendering:** one authoritative owner per UI surface and overlay state.
   Never submit the same ImGui window ID twice in one frame.
7. **Identity:** every interactive widget has a stable explicit ID derived from
   persistent domain identity, numeric/index identity, composed scope, or a
   retained per-instance random value.
8. **UI failure containment:** keep throwing/yielding/I/O/network/game-mutation
   work out of render callbacks. A callback type is not isolation; execution must
   cross a real coroutine boundary. Revalidate state after yields.
9. **Remote actions:** DEV-only, opt-in, localhost-bound, bounded, and
   `force=false` by default. Invisible controls no-op with concise cause and next
   step; forced semantic invocation reports that it was forced.
10. **Themes:** default ImGui preserves installed Openplanet themes. NVG and full
    custom styling are opt-in depths with screenshot review.
11. **Hashes:** mutable/golden hashes explain expected updates, regeneration, and
    drift meaning. Prefer two-build determinism to literal pins unless digest is
    the compatibility contract.
12. **Provenance:** never fabricate it. New/Bosslike snippets may omit a source;
    copied/adapted public material retains source path/repository and compatible
    license.
13. **Store safety:** no deception/evasion, no Reviewer-role workflow, no secret
    handling in public configs, and no upload/sign/publish mutation without a
    human decision at that boundary.

Experienced mechanisms and reviewer checks live in
`docs/openplanet-gotchas.md`, `docs/reviewer-failure-ledger.md`, and
`docs/reviewer-workflow.md`. API deprecations and their replacements are logged
by version in `docs/openplanet-deprecations.md`.

## 5. Validation contract

`docs/validation-tiers.md` is authoritative.

- Tier 0: source-backed ordinary guidance.
- Tier 1: copyable component with LSP, live compile, behavior smoke, and adjacent
  test/demo evidence.
- Tier 2: advanced recipe with ownership/state model, transition/fault matrix,
  and adversarial review.
- Tier 3: promoted skill/release with portable metadata/discovery validation,
  full evidence closure, and real dogfood.

Missing tools lower the supported claim. They never convert “not tested” into a
pass.

## 6. Visual architecture

Three depths are independently chosen per task:

1. Theme-preserving ImGui composition.
2. Provenance-cleared NVG recipes with deterministic capture.
3. Opt-in advanced custom composition when the product goal requires it.

Canonical recipes plus one manifest deterministically generate standalone
`Skillpack Demos` galleries. The manifest owns maturity, license, optional
truthful provenance, expected output, capture frames, and instrumentation.
Promotion requires live load and fresh screenshot critique, not generation alone.

## 7. Lifecycle and control capability ladder

Use the highest available rung while preserving lower-rung recovery:

1. Manual Openplanet UI and `Openplanet.log`.
2. Minimal dependency-closure-aware lifecycle bridge.
3. RemoteBuild staging and load/reload/unload.
4. Optional project-local control bridge for state setup, assertions, and
   semantic component actions.

The control transport uses bounded length-prefixed JSON, maximum frame sizes,
timeouts, single-flight mutation, explicit shutdown, no arbitrary code, and a
checked-in CLI for framing/macros/assertions. Simple frames may remain usable via
`nc` when practical. Public/release enablement is off by default.

## 8. Initialization and local state

Every initialized plugin records a tracked brief containing purpose, game scope,
module topology, dependencies, build/staging flow, expected callbacks, validation
plan, and policy assumptions. Machine-local paths, ports, installed capabilities,
and runtime receipts stay in private clone-local state rather than portable docs.

## 9. Packaging and installation

Promoted skills live flat under `skills/<name>/` with authored `SKILL.md`,
`agents/openai.yaml`, and one-level `references/`/`scripts/`/`assets/` as needed.
Drafts remain outside discovery containers.

Version one supports:

- `npx skills@latest add XertroV/tm-plugin-skills`;
- Claude plugin metadata;
- direct git/local-path installation; and
- Codex/OpenAI metadata.

Do not npm-publish the package. Claude plugin installation and copied/symlinked
Agent Skills are alternative user routes; document that installing both creates
duplicates. Maintainer symlink scripts are development conveniences, not the end
user installer.

## 10. Store-policy boundary

Preparation may cover public metadata, tested games, images/accessibility text,
non-secret settings, version artifacts, changelog, compatibility, broad AI-use
disclosure, and terms checks. Upload, attest, sign, approve, and publish are
distinct states. Mutations remain human-controlled. Reviewer-role interfaces and
actions are excluded.

## 11. Implementation sequence

1. Lock packaging/version metadata and validation scripts around the promoted
   reviewer reference skill.
2. Implement `openplanet-init` and its initialization-brief fixture.
3. Implement `openplanet-lifecycle` against manual and RemoteBuild rungs.
4. Implement `openplanet-dev` with deterministic seams and adjacent `[Test]`
   companions.
5. Implement `openplanet-visual` by promoting vetted gallery recipes.
6. Implement `openplanet-control` incrementally through library/router/component
   fixtures with visibility-safe semantic actions.
7. Run cross-skill dogfood, diagnostics parity, screenshot matrices, and an
   independent `openplanet-reviewer` release pass.
8. Complete Tier 3 packaging/discovery/install gates and prepare—but do not
   perform—store publication actions.

Each step ships only after its tier gate; implementation does not wait for one
final integration pass.

## 12. Out of scope

- Openplanet core development or a mirror of the complete API corpus.
- Guaranteed deep runtime support for games other than Trackmania 2020 in v1.
- A general-purpose game automation framework.
- A mandatory house visual style.
- Native Codex plugin metadata or npm registry publishing in v1.
- Store submission/publication and Reviewer-role administration.

## 13. Traceability

| Decision | Canonical evidence |
| --- | --- |
| Workflow/skill boundaries | issue 2; `docs/skill-manifest.md` |
| Visual depths | issue 3; issue 12 prototype |
| Pattern catalog | issue 4 research |
| Initialization/local state | issue 5; `CONTEXT.md` |
| Lifecycle/control ladder | issue 6 research |
| Packaging | issue 7 research |
| Store policy | issue 8 research |
| Owner admin workflow | issue 9 research |
| Validation tiers | issue 10; `docs/validation-tiers.md` |
| Reviewer | issue 13; reviewer docs and promoted skill |
| Final shape/approval | issue 11; this document |

## 14. Approval checklist

Approve only if all answers are **yes**:

- [ ] Six skill boundaries and cross-links match the intended user workflow.
- [ ] `Skillpack Demos`, adjacent `[Test]`, LSP+game parity, and visible evidence
      are mandatory per increment.
- [ ] Ordinary exports, render ownership, stable IDs, coroutine containment,
      visibility-safe control, themes, hashes, and provenance defaults are right.
- [ ] Validation tiers make claims proportional to actual evidence and degrade
      honestly when tools are missing.
- [ ] Packaging supports Agent Skills, Claude plugin, direct git, and OpenAI/Codex
      metadata without npm publishing.
- [ ] Trackmania 2020 is the only deep v1 runtime claim unless separately tested.
- [ ] Store/reviewer/safety boundaries preserve truthful human control.
- [ ] Implementation sequence has no unresolved product or architecture choice.
- [ ] Out-of-scope items are acceptable.

Approval options:

- **Approve** — this specification becomes the implementation baseline.
- **Approve with named edits** — apply only the listed edits, then lock it.
- **Reject** — identify the unresolved decision; reopen the owning ticket.

After approval, later discoveries update the relevant failure/gotcha/validation
source and receive regression evidence; they do not silently rewrite this scope.