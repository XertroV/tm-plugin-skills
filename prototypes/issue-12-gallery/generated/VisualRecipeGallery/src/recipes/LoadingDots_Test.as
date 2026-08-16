// GENERATED COPY sha256=7f4774963ed0855659c4259e1eb1cfc7dd6fb2bae45389d887a6ce1c46acb213 source=recipes/LoadingDots_Test.as
namespace Tests {
    [Test]
    void LoadingDots_WaveClosesLoop(Tests::Context@ ctx) {
        for (int i = 0; i < 9; i++) {
            ctx.AssertSameApprox(RecipeLoadingDots::DotLift(i, 9, 0), RecipeLoadingDots::DotLift(i, 9, 120), "approx equal");
        }
    }

    [Test]
    void LoadingDots_LiftIsBounded(Tests::Context@ ctx) {
        for (int f = 0; f <= 120; f += 15) {
            float lift = RecipeLoadingDots::DotLift(2, 9, f);
            ctx.AssertTrue(lift >= 0.0f && lift <= 1.0f, "lift stays in [0,1] at frame " + f);
        }
    }

    [Test]
    void LoadingDots_ClipRestoresDepth(Tests::Context@ ctx) {
        auto dl = UI::GetWindowDrawList();
        int before = RecipeLoadingDots::clipDepth;
        RecipeLoadingDots::PushClip(dl, vec2(0, 0), vec2(10, 10));
        RecipeLoadingDots::PopClip(dl);
        ctx.AssertSame(RecipeLoadingDots::clipDepth, before, "clip depth restores");
    }
}
