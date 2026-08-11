# Testing Openplanet plugins

Use Openplanet's built-in `[Test]` metadata for deterministic feature behavior,
then pair it with an in-game behavior or visual smoke. Static compilation does
not execute tests, and unit tests do not prove rendering behavior.

## Standard companion layout

Keep each testable feature beside its test companion:

```text
Feature.as
Feature_Test.as
```

`_Test.as` is this skillpack's naming convention. Openplanet discovers test
functions from `[Test]`, not from the filename, and compiles companions as
ordinary plugin sources. A broken companion can therefore break normal plugin
compilation even when no test command is run.

Use the conservative confirmed signature:

```angelscript
namespace Tests {
    [Test]
    void Feature_DefaultBehavior(Tests::Context@ ctx) {
        ctx.AssertSame(Feature::Compute(2), 4, "two doubles to four");
    }
}
```

The function must return `void` and accept `Tests::Context@`. `namespace Tests`
is the official convention, although discovery is driven by `[Test]` metadata.

## Assertion API

Use descriptive messages and pass **actual first, expected second**:

- `AssertTrue` and `AssertFalse`
- `AssertNull` and `AssertNotNull`
- `AssertSame` and `AssertNotSame`
- `AssertSameApprox` and `AssertNotSameApprox`

Exact equality supports integer types, `float`, `double`, and `string`.
Approximate equality is published only for `float` and `double`; its epsilon is
not documented. Compare vectors, arrays, dictionaries, enums, and script-object
fields element by element or reduce the check to a boolean assertion.

## Context lifetime and async work

Openplanet documents `Tests::Context` as invalid immediately after the test
function returns:

- do not store it globally;
- do not retain it in a class;
- do not capture it in `startnew(...)` or a later callback; and
- do not use fire-and-forget work for assertions.

Yielding, awaiting, runner timeouts, overlap, and async exception attribution
are not currently documented. Treat async tests as experimental live probes,
not as portable skillpack guidance.

## What to test

Prefer deterministic pure seams:

- input normalization and boundary cases;
- state transitions extracted from callbacks;
- ID composition and remote-control routing;
- error envelopes and force/visibility decisions;
- balanced instrumentation modeled without calling rendering APIs; and
- ordinary-export behavior through a dependent consumer.

Ordinary `exports` are compiled into dependent modules, not into the exporting
library's own module. Put focused tests for those helpers in a dependent demo
companion. Do not create a library-local test that assumes its ordinary export
symbols exist in the library module. Use `shared_exports` only when real shared
identity or state is required, not merely to make a test visible.

Do not call ImGui, draw-list, or NVG drawing APIs from a normal `[Test]` unless
a dedicated live probe proves that the test runner supplies a valid render
context. Validate actual drawing through the live demo and screenshot gate.

Treat test order and state isolation as unspecified. Reset mutated global state
and never rely on one test preparing another.

## Running tests in Openplanet

After loading the exact staged bytes and checking the fresh compile-log window,
use Openplanet's Developer menu:

1. **Run all tests for recent** for the focused plugin.
2. **Reload and run all tests for recent** when initialization state matters.
3. **Run all plugin tests** for the broad regression gate.

The exact rules selecting the “recent” plugin are not publicly documented.
No public headless test-runner API was found.

## Required dogfood loop

1. Run `openplanet-lsp check` against the plugin and real dependency root.
2. Load/reload the same bytes in Openplanet and preserve its diagnostics and warnings.
3. Compare LSP and Openplanet results, including deprecations.
4. Run the focused suite twice and verify the expected count and names.
5. Run reload-and-test to catch initialization assumptions.
6. Temporarily introduce one failing assertion, verify file/test attribution, and revert it.
7. Exercise behavior through the `Skillpack Demos` plugin.
8. Capture and review fresh visual evidence for rendered components.

If the game compiles while `openplanet-lsp` reports an error, file an LSP bug
with the smallest known reproduction. If both reject the code for materially
different reasons, or warnings differ, file an investigation issue containing
both exact transcripts.

## Version and primary sources

The feature is present in Openplanet-maintained plugin source from June 2024 and
confirmed in Openplanet 1.29.x. The exact minimum release is not documented; do
not invent one. Require a build exposing `[Test]` and `Tests::Context`.

- <https://openplanet.dev/docs/api/Tests>
- <https://openplanet.dev/docs/api/Tests/Context>
- <https://github.com/openplanet-nl/nadeoservices/blob/master/Tests.as>
