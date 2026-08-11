namespace Tests {
    [Test]
    void DrawListGradient_InstrumentationStaysBalanced(Tests::Context@ ctx) {
        RecipeDrawListGradient::DrawPanel(0);
        ctx.AssertSame(
            RecipeDrawListGradient::clipDepth,
            0,
            "draw-list recipe must restore its clip state"
        );
    }
}