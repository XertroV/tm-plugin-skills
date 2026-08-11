// GENERATED COPY sha256=bc4a1f566f90fb76982fbe2da8eeba070022200f8a91b25a47f7c756477925d4 source=recipes/NvgScissor_Test.as
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