// GENERATED COPY sha256=25f3706802f617e237d03be75df44b04a838b33aa375dd4f612f6443432c3cde source=recipes/ThemeTable_Test.as
namespace Tests {
    [Test]
    void ThemeTable_InstrumentationStaysBalanced(Tests::Context@ ctx) {
        ctx.AssertSame(
            RecipeThemeTable::StyleDepthAfterBalancedOperations(3),
            3,
            "theme table must not leak style state"
        );
    }
}