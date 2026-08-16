namespace Tests {
    [Test]
    void IconHalo_PulseClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeIconHalo::Pulse(0), RecipeIconHalo::Pulse(120), "approx equal");
        ctx.AssertSameApprox(RecipeIconHalo::Pulse(60), 1.0f, "approx equal");
    }

    [Test]
    void IconHalo_ClipRestoresDepth(Tests::Context@ ctx) {
        auto dl = UI::GetWindowDrawList();
        int before = RecipeIconHalo::clipDepth;
        RecipeIconHalo::PushClip(dl, vec2(0, 0), vec2(10, 10));
        RecipeIconHalo::PopClip(dl);
        ctx.AssertSame(RecipeIconHalo::clipDepth, before, "clip depth restores");
    }
}
