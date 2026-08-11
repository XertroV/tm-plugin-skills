// GENERATED COPY sha256=4af89e50b5b96bc67148b8d3b5b5b202774202b19ba10cb2d96523eb727eb900 source=recipes/OverlayRenderOwner_Test.as
namespace Tests {
    [Test]
    void OverlayRenderOwner_SelectsExpectedCallback(Tests::Context@ ctx) {
        ctx.AssertSame(
            RecipeOverlayRenderOwner::OwnerForOverlayState(true),
            "RenderInterface",
            "overlay-visible UI must be owned by RenderInterface"
        );
        ctx.AssertSame(
            RecipeOverlayRenderOwner::OwnerForOverlayState(false),
            "Render",
            "the explicit overlay-hidden fallback belongs to Render"
        );
    }

    [Test]
    void OverlayRenderOwner_SubmitsExactlyOnceInEachState(Tests::Context@ ctx) {
        ctx.AssertSame(
            RecipeOverlayRenderOwner::SubmissionCount(true, true, true),
            1,
            "Render must be ignored while the overlay is shown"
        );
        ctx.AssertSame(
            RecipeOverlayRenderOwner::SubmissionCount(false, true, true),
            1,
            "RenderInterface must be ignored while the overlay is hidden"
        );
    }
}
