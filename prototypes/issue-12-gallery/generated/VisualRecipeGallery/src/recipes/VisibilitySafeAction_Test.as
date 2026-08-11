// GENERATED COPY sha256=032e2abb3386592f741be8b9f2a0f8cce8120393eeb3c75c75dab89b4ea2ed0d source=recipes/VisibilitySafeAction_Test.as
namespace Tests {
    [Test]
    void VisibilitySafeAction_HiddenDefaultDoesNotMutate(Tests::Context@ ctx) {
        string result = RecipeVisibilitySafeAction::InvokeAction(false, false);
        ctx.AssertSame(
            RecipeVisibilitySafeAction::MutationDelta(false, false),
            0,
            "an undrawn component must reject the default action without mutation"
        );
        ctx.AssertTrue(result.StartsWith("not_drawn:"), "failure must report the concrete cause");
        ctx.AssertTrue(result.Contains("retry"), "failure must report a concrete next action");
    }

    [Test]
    void VisibilitySafeAction_VisibleAndForcedPathsAreTruthful(Tests::Context@ ctx) {
        string visible = RecipeVisibilitySafeAction::InvokeAction(true, false);
        ctx.AssertSame(RecipeVisibilitySafeAction::MutationDelta(true, false), 1, "visible action mutates once");
        ctx.AssertTrue(visible.Contains("visible semantic callback"), "visible result describes semantic invocation");

        string forced = RecipeVisibilitySafeAction::InvokeAction(false, true);
        ctx.AssertSame(RecipeVisibilitySafeAction::MutationDelta(false, true), 1, "forced action mutates once");
        ctx.AssertTrue(forced.Contains("forced semantic callback"), "forced result must not claim a physical click");
    }
}
