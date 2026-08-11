namespace Tests {
    [Test]
    void ThemeTable_InstrumentationStaysBalanced(Tests::Context@ ctx) {
        RecipeThemeTable::DrawPanel(0);
        ctx.AssertSame(
            RecipeThemeTable::styleDepth,
            0,
            "theme table must not leak style state"
        );
    }
}