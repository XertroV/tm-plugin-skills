# Incremental test, demo, and exact-bytes loop

Load this reference for every behavior increment.

## Companion contract

Pair deterministic code in place:

```text
Feature.as
Feature_Test.as
```

Openplanet discovers `[Test]`, not the suffix; companions are ordinary sources
and can break normal compilation. Use the conservative form:

```angelscript
namespace Tests {
    [Test]
    void Feature_Default(Tests::Context@ ctx) {
        ctx.AssertSame(Feature::Compute(2), 4, "two doubles to four");
    }
}
```

Assertions take actual then expected. Keep `Tests::Context@` inside the test's
lifetime. Avoid async/yield and rendering calls; their runner semantics/context
are not documented. Test ordinary-export behavior in a dependent demo because
ordinary exports compile into dependents, not the library module.

## Per-increment evidence loop

1. **RED:** run the new focused test and preserve expected failure attribution.
2. Add a reachable, self-explanatory behavior state to category
   `Skillpack Demos`; use controls/readouts/logs/fault probes for nonvisual work.
3. **GREEN:** implement minimally; run focused tests twice and verify names/count.
4. **REFACTOR:** retain green; run reload-and-test and applicable broad suite.
5. Build/generate deterministically. Record canonical and staged paths. Compare
   the checked source and staged files byte-for-byte (`cmp`) or record digests for
   all generated/staged inputs. Prefer two-clean-build equality over literal
   golden hashes unless the digest is the compatibility contract.
6. Run `openplanet-lsp check` against the real dependency root on those bytes.
7. Load/reload those exact bytes in Openplanet. Preserve the fresh load-to-end log
   window, including warnings and deprecations.
8. Compare LSP/game acceptance, reason, location, severity, warnings, and
   deprecations. Preserve the smallest repro for drift.
9. Run focused tests, reload-and-test, then exercise the effective demo behavior.
10. Probe applicable null/empty, zero/one/limit, duplicate launch, timeout,
    cancellation, transition, and teardown cases. Record reviewed N/A explicitly.
11. For visible behavior, capture declared theme/viewport/scale/state and review
    fresh pixels. Source correctness is not screenshot evidence.
12. Unload/reload as applicable; remove temporary installed fault probes after
    evidence is retained.

## Lifecycle evidence

Runtime completion requires all of:

- fresh `Loaded plugin '…'` after the action;
- no later compile error for that plugin;
- observable behavior result and expected test execution;
- exact staged-byte identity;
- teardown/reload proof where resources or dependencies are involved.

A later success line after an earlier failure does not excuse scanning the wrong
log window. Missing LSP means no parity claim. Missing game means no compile,
test-pass, demo, or runtime claim.

## Feedback record

For each subtle gotcha/reviewer finding record: trigger; symptom and impact;
violated invariant; evidence grade and exact artifact; reviewer probe; prevention
or regression gate. Hypotheses name the next probe. Confirmed mechanisms update
tests and the reachable demo/fault fixture in the same increment.

Primary basis: Openplanet Tests/Context documentation and the approved project
specification, validation tiers, testing guide, and gotcha ledger.
