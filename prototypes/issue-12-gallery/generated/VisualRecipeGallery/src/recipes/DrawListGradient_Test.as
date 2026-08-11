// GENERATED COPY sha256=ff4444c2e57b6e4839e5311ec3feb71b76209035a57efe6bd66eafd70484a5e4 source=recipes/DrawListGradient_Test.as
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