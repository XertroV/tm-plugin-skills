namespace Tests {
    [Test]
    void GradientRule_SweepClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeGradientRule::Phase(0), RecipeGradientRule::Phase(120), "approx equal");
    }

    [Test]
    void GradientRule_ClipRestoresDepth(Tests::Context@ ctx) {
        auto dl = UI::GetWindowDrawList();
        int before = RecipeGradientRule::clipDepth;
        RecipeGradientRule::PushClip(dl, vec2(0, 0), vec2(10, 10));
        RecipeGradientRule::PopClip(dl);
        ctx.AssertSame(RecipeGradientRule::clipDepth, before, "clip depth restores");
    }
}
