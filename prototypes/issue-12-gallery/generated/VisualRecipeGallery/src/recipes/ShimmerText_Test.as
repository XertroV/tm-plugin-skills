// GENERATED COPY sha256=3b8ece847a277c43a3c80a2f3addc8ccbe358208692546dfee1512329883e7b0 source=recipes/ShimmerText_Test.as
namespace Tests {
    [Test]
    void ShimmerText_BandClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeShimmerText::BandCenter(0), RecipeShimmerText::BandCenter(120), "approx equal");
        ctx.AssertTrue(RecipeShimmerText::BandCenter(0) < 0.0f, "band starts off the leading edge");
        ctx.AssertTrue(RecipeShimmerText::BandCenter(120) < 0.0f, "band returns off the leading edge");
        ctx.AssertTrue(RecipeShimmerText::BandCenter(60) > 0.0f && RecipeShimmerText::BandCenter(60) < 1.0f, "band crosses mid-text at frame 60");
    }

    [Test]
    void ShimmerText_EdgeGlyphAtBaseColor(Tests::Context@ ctx) {
        vec4 base = vec4(0.4f, 0.4f, 0.4f, 1.0f);
        vec4 hot = vec4(1.0f, 1.0f, 1.0f, 1.0f);
        // At frame 0 the band is off the leading edge, so the last glyph sits at base.
        vec4 edge = RecipeShimmerText::ShimmerColor(19, 20, 0, base, hot);
        ctx.AssertSameApprox(edge.x, base.x, "approx equal");
    }

    [Test]
    void ShimmerText_ClipRestoresDepth(Tests::Context@ ctx) {
        auto dl = UI::GetWindowDrawList();
        int before = RecipeShimmerText::clipDepth;
        RecipeShimmerText::PushClip(dl, vec2(0, 0), vec2(10, 10));
        RecipeShimmerText::PopClip(dl);
        ctx.AssertSame(RecipeShimmerText::clipDepth, before, "clip depth restores");
    }
}
