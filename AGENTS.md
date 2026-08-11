# Agent instructions

This repository is in Wayfinder planning mode. GitHub Issues are the canonical decision map; implementation must follow closed decision tickets rather than inventing unresolved product choices.

## Planning

- Read `docs/agents/issue-tracker.md` before operating on the map.
- Refer to issues by linked title in human-facing prose, not bare issue numbers.
- Keep decisions in their resolution tickets. The map only links and gists them.
- One decision ticket per session, except parallel research tickets.

## Product direction

- Portable default: the plugin repository may itself be a folder inside Openplanet's `Plugins/` directory.
- Project-specific build scripts, `openplanet-lsp`, RemoteBuild, MCP bridges, and screenshot tooling are capabilities to detect, not universal prerequisites.
- Skills must be concise, opinionated, progressively disclosed, and backed by observable completion gates.
- Read `docs/openplanet-gotchas.md` before designing or changing Openplanet components. Preserve its experienced defaults unless current evidence justifies and documents an exception.
- Maintain `docs/reviewer-failure-ledger.md` as the adversarial complement to the gotchas guide. Record every newly observed way a plugin can subtly fail, lose synchronization, corrupt game/plugin state, stop rendering, misuse mode-specific APIs, or become structurally unmaintainable; feed each applicable entry into `openplanet-reviewer`, development guidance, and a test/demo gate.

## Repository work

- Do not implement a skill while its governing decision remains open.
- Add every promoted skill to the top-level index and plugin manifests.
- Validate frontmatter, internal links, invocation metadata, and any bundled scripts before committing.

## Components, tests, and demos

- Every new or changed reusable component, helper, recipe, or behavioral feature must expand both automated tests and an incrementally runnable demo. Do not add implementation without adding or updating its evidence in the same change.
- Put Openplanet `[Test]` coverage in a neighboring `Feature_Test.as` companion when the behavior is testable. The companion must exercise the public behavior and important failure or boundary cases, not merely compile.
- Follow `docs/testing-openplanet-plugins.md` for signatures, assertions, context lifetime, safe test seams, invocation, and live evidence.
- Add each visual or interactive component to a `Skillpack Demos` plugin so it can be selected and inspected in Trackmania. Extend the manifest, deterministic state/capture matrix, and expected result instead of leaving unreachable sample code.
- Reusable demo infrastructure belongs in `SkillpackDemoLib`. Prefer ordinary `exports` so stateless helpers are compiled into each dependent demo plugin; reserve `shared_exports` for genuine cross-plugin identity or shared state.
- Before moving to the next component, dogfood the changed example: run `openplanet-lsp`, compile/load it in Openplanet, compare diagnostics and warnings, execute applicable `[Test]` cases, exercise behavior, and capture/review fresh visual evidence when it renders.
- Treat missing test/demo coverage as incomplete work. When touching an older component, bring it up to this standard rather than preserving the gap.

## Architecture and adversarial review

- Spend architecture effort up front for nontrivial plugins. Choose explicit namespace, class, ownership, state-machine, packet-routing, and callback boundaries before feature growth makes them expensive to change.
- Keep render callbacks exception-minimal. Move potentially throwing, yielding, networked, filesystem, or complex state-changing work behind coroutine/task boundaries such as `startnew(...)`; pass arguments through explicit state carriers or typed classes rather than ambient mutable globals.
- Review game-state and plugin-state transitions adversarially: wrong app/editor/playground mode, stale nods/handles, map/server/session changes, reentrant callbacks, unload/reload cleanup, packet ordering, retries, and UI stack unwinding are first-class failure classes.
- Search Max's plugin corpus for proven API structures before inventing one, but compare requirements and performance characteristics before transplanting an architecture. Dips++, Map Together, Bosslike, and reusable button/component classes are design evidence, not universal templates.
