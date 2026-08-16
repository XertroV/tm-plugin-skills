// GENERATED COPY sha256=119da6cbe7a015367ba2ce259b4e4ced296a07907154f82ca6498c5fe6591c93 source=recipes/StatusPulse_Test.as
namespace Tests {
    [Test]
    void StatusPulse_PulseClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeStatusPulse::Pulse(0), RecipeStatusPulse::Pulse(120), "approx equal");
        ctx.AssertSameApprox(RecipeStatusPulse::Pulse(60), 1.0f, "approx equal");
    }

    [Test]
    void StatusPulse_ClipRestoresDepth(Tests::Context@ ctx) {
        auto dl = UI::GetWindowDrawList();
        int before = RecipeStatusPulse::clipDepth;
        RecipeStatusPulse::PushClip(dl, vec2(0, 0), vec2(10, 10));
        RecipeStatusPulse::PopClip(dl);
        ctx.AssertSame(RecipeStatusPulse::clipDepth, before, "clip depth restores");
    }
}
