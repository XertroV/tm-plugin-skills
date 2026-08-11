// GENERATED COPY sha256=af4c2b78e187d08a4ad81436e8f2949d2afc6658ac764dd2df47a86072d82094 source=recipes/ThemeTable_Test.as
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