namespace Tests {
    [Test]
    void NvgScissor_InstrumentationStaysBalanced(Tests::Context@ ctx) {
        RecipeNvgScissor::DrawCanvas(0);
        ctx.AssertSame(
            RecipeNvgScissor::scissorDepth,
            0,
            "NVG recipe must restore its scissor state"
        );
    }
}