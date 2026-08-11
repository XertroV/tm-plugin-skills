// GENERATED COPY sha256=7ce151784fd3d35e60a6b5720eba03a5b5fb3b2ef85ed9bfe3dffb6cd8ea3633 source=recipes/NvgScissor_Test.as
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