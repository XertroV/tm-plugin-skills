namespace Tests {
    [Test]
    void NvgScissor_InstrumentationStaysBalanced(Tests::Context@ ctx) {
        ctx.AssertSame(
            RecipeNvgScissor::ScissorDepthAfterBalancedOperations(2),
            2,
            "NVG recipe must restore its scissor state"
        );
    }
}