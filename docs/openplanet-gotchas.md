# Openplanet implementation gotchas

These are defaults learned from real plugin work. Apply them early; they prevent
bugs that are disproportionately difficult to diagnose after components spread
across multiple plugins.

## Render callbacks are not interchangeable

`RenderInterface()` owns ordinary ImGui windows shown with the Openplanet
overlay.

Use `Render()` for the same window only when the feature intentionally remains
visible while the overlay is hidden. In that case:

```angelscript
void RenderInterface() {
    DrawWindow();
}

void Render() {
    if (UI::IsOverlayShown()) return;
    DrawWindow();
}
```

Do not invoke the same ImGui window unconditionally from both callbacks. A
matching window name/ID means ImGui can append a second copy of the interior to
the same window. A frame-number deduplication guard is not the preferred fix;
the callback must follow Openplanet's overlay visibility state.

If the feature has no “show while UI hidden” mode, omit the `Render()` path.
Test both overlay states whenever both callbacks exist.

## Keep throwing work out of render callbacks

An exception escaping UI code can make Openplanet unwind the current UI stack
and stop invoking that plugin's render callbacks. Treat render paths as fragile:
keep them deterministic, bounded, and limited to drawing plus cheap local state
changes.

Button presses and other UI events should launch potentially throwing,
yielding, networked, filesystem, or multi-step mutations through `startnew(...)`
or a similarly isolated coroutine. Pass required arguments in an explicit typed
state carrier or class when a callback signature cannot carry them directly.
The coroutine boundary isolates failure from UI-stack cleanup; it does not
replace validation, error reporting, cancellation, ownership, or stale-state
checks.

Reusable button/component classes can provide a stable ID, render-epoch state,
an overridable semantic `OnClick` method, and one guarded coroutine launcher.
Subclasses then express behavior without duplicating callback plumbing.

Catalog concrete failure patterns and adversarial checks in
`reviewer-failure-ledger.md`; this file keeps the preferred development default.

## Interactive controls need stable IDs

Assign explicit stable IDs to every interactive item:

- windows;
- buttons and selectable rows;
- inputs, sliders, and combo boxes;
- trees and collapsing headers;
- tabs and popups; and
- custom UI/NVG hit targets.

Prefer `label###stable-id` when the visible label may change while identity must
remain stable. Use `##suffix` only when the visible label should remain part of
identity. Scope looped controls with balanced `UI::PushID(...)` and
`UI::PopID()` or compose IDs from stable keys and indices.

A random ID is safe only when generated once and retained for the component's
lifetime. Regenerating it each frame loses widget state and produces subtle
interaction bugs.

Reusable interactive helpers should centralize:

- stable ID composition from strings, indices, and combinations;
- retained per-instance random IDs when necessary;
- render-epoch visibility marking; and
- remote-control registration and teardown.

## Visibility means drawn this epoch

A `Visible` property alone does not prove that a component submitted its hit
target. Track a render epoch and mark a component drawn only after its UI/NVG
control is actually submitted.

Remote actions default to `force=false`. If the component was not drawn in the
current completed epoch:

- make no state change;
- return a concise `not_drawn` error;
- explain how to open/render and retry; and
- mention `force=true` as the explicit semantic override.

A forced action invokes the registered semantic callback. It must report that
it was forced and must not claim a physical mouse click or hover occurred.

## Ordinary exports are compiled into dependents

Prefer ordinary `exports` for stateless demo helpers and classes that do not
need shared cross-plugin identity. Openplanet compiles those files into each
dependent module, which keeps development plugins isolated and avoids shared
instance lifecycle problems.

Consequences:

- test ordinary-export symbols from a dependent demo module;
- do not expect them to exist in the exporting library's own module; and
- use `shared_exports` only for genuine shared identity or state.

All skill-dev, test, and demo plugins use the `Skillpack Demos` category and may
depend on `SkillpackDemoLib` for common infrastructure.

## Test files are normal source files

Openplanet discovers tests through `[Test]`, not an `_Test.as` filename. The
adjacent suffix is the skillpack convention. Companions compile during normal
plugin loading, so a broken test prevents the plugin from compiling even if the
suite is never run.

`Tests::Context@` is invalid after the test returns. Never retain or capture it.
Do not assume async/yield support, test ordering, isolation, or a render context.
Extract pure seams for ordinary tests and validate UI/NVG behavior in the live
demo. See `testing-openplanet-plugins.md`.

## LSP acceptance is not runtime acceptance

For each increment, run `openplanet-lsp` and compile the exact same bytes in
Openplanet. Preserve both diagnostics, including warnings and deprecations.

- Game accepts while LSP reports an error: file an `openplanet-lsp` bug with the
  smallest known reproduction.
- Both reject for materially different reasons: file an investigation issue
  with both transcripts.
- Warning or deprecation sets differ: record and investigate the parity gap.

Zero LSP diagnostics alone is never live proof.

## Demo evidence grows with components

Every new or changed reusable component expands:

- a neighboring automated test companion;
- a reachable `Skillpack Demos` example;
- deterministic states and capture cases;
- expected behavior text;
- a fresh in-game compile and behavior smoke; and
- screenshot evidence when it renders.

Do not leave helper code unreachable from a demo or defer all integration until
the end. Keep development plugins loaded and inspectable while building.

## Remote control is bounded and explicit

The development control bridge is optional, opt-in, DEV-only, and loopback
bound. Use bounded length-prefixed JSON request/reply frames with:

- a strict maximum frame size;
- read and execution timeouts;
- fixed named routes rather than arbitrary code execution;
- single-flight mutation where races would be unsafe;
- explicit shutdown and reload cleanup; and
- concise structured failures containing both cause and next step.

Provide a checked-in CLI for framing, macros, timeouts, and assertions. Simple
manual frames may be usable through `nc`; do not make hand-built framing the
normal automation interface. Dips++ `BetterSocket` is an advanced design input,
not a reason to copy server/client-specific behavior blindly.

## Golden hashes need an update policy

Prefer comparing two clean builds for determinism. Pin a literal digest only
when cross-version byte identity is itself part of the contract.

Every mutable hash assertion needs a nearby comment explaining:

- what expected source changes should alter it;
- how and when to regenerate it; and
- what unexpected change indicates drift or breakage.

## Themes and visual evidence

Default ImGui examples inherit the active Openplanet theme. Do not force a
palette merely to make a demo look consistent. Advanced custom styling is an
explicit opt-in tier and must restore every pushed style, clip, transform, and
scissor state on all paths.

Visual changes require fresh screenshots under the declared theme, viewport,
scale, game state, and deterministic component state. Review pixels against the
written expectation; source inspection is not a substitute.

## Provenance and assets are separate

Newly authored and owner-authorized Bosslike-derived snippets do not need a
listed external source. Never fabricate provenance. Code permission does not
clear fonts, images, audio, or other assets; review those separately.

## Development plugins still need initialization

Even temporary or local-only plugins receive a tracked initialization brief.
Keep machine-local paths, credentials, capability probes, and receipts in
clone-local excluded state rather than portable project documentation.
