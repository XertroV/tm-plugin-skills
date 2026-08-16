namespace Tests {
    [Test]
    void BreathingDivider_PulseClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeBreathingDivider::Pulse(0), RecipeBreathingDivider::Pulse(120), "approx equal");
        ctx.AssertSameApprox(RecipeBreathingDivider::Pulse(0), 0.0f, "approx equal");
        ctx.AssertSameApprox(RecipeBreathingDivider::Pulse(60), 1.0f, "approx equal");
        ctx.AssertTrue(RecipeBreathingDivider::Pulse(30) > RecipeBreathingDivider::Pulse(0), "pulse rises from trough");
    }

    [Test]
    void BreathingDivider_ClipRestoresDepth(Tests::Context@ ctx) {
        auto dl = UI::GetWindowDrawList();
        int before = RecipeBreathingDivider::clipDepth;
        RecipeBreathingDivider::PushClip(dl, vec2(0, 0), vec2(10, 10));
        RecipeBreathingDivider::PopClip(dl);
        ctx.AssertSame(RecipeBreathingDivider::clipDepth, before, "clip depth restores");
    }
}
