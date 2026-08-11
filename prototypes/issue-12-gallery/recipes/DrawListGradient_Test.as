namespace Tests {
    [Test]
    void DrawListGradient_InstrumentationStaysBalanced(Tests::Context@ ctx) {
        ctx.AssertSame(
            RecipeDrawListGradient::ClipDepthAfterBalancedOperations(4),
            4,
            "draw-list recipe must restore its clip state"
        );
    }
}