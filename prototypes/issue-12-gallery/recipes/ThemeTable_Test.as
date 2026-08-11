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