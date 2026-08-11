// GENERATED COPY sha256=57b2ddc136f8177a503725a5987f3fc378f034973f8818539799705e0fca1839 source=recipes/DrawListGradient_Test.as
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