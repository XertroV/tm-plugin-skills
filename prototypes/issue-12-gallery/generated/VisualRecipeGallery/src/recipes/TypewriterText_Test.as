// GENERATED COPY sha256=d30d92e1a1387f94253770f58880f5adbd34b4ef92989e894890e128382bb773 source=recipes/TypewriterText_Test.as
namespace Tests {
    [Test]
    void TypewriterText_RevealIsMonotonicThenFull(Tests::Context@ ctx) {
        int total = 20;
        ctx.AssertSame(RecipeTypewriterText::RevealedGlyphs(total, 0), 0, "frame 0 reveals nothing");
        ctx.AssertTrue(RecipeTypewriterText::RevealedGlyphs(total, 42) > 0, "mid-reveal shows glyphs");
        ctx.AssertSame(RecipeTypewriterText::RevealedGlyphs(total, 84), total, "70% holds full string");
        ctx.AssertSame(RecipeTypewriterText::RevealedGlyphs(total, 120), 0, "loop wraps back to empty");
    }

    [Test]
    void TypewriterText_CaretBlinks(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeTypewriterText::CaretAlpha(0), 1.0f, "approx equal");
        ctx.AssertSameApprox(RecipeTypewriterText::CaretAlpha(15), 0.0f, "approx equal");
    }

    [Test]
    void TypewriterText_ClipRestoresDepth(Tests::Context@ ctx) {
        auto dl = UI::GetWindowDrawList();
        int before = RecipeTypewriterText::clipDepth;
        RecipeTypewriterText::PushClip(dl, vec2(0, 0), vec2(10, 10));
        RecipeTypewriterText::PopClip(dl);
        ctx.AssertSame(RecipeTypewriterText::clipDepth, before, "clip depth restores");
    }
}
