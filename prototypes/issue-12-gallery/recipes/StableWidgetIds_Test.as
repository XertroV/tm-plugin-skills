namespace Tests {
    [Test]
    void StableWidgetIds_VisibleLabelDoesNotChangeIdentity(Tests::Context@ ctx) {
        ctx.AssertSame(
            RecipeStableWidgetIds::ButtonId("Run", "primary-action"),
            RecipeStableWidgetIds::ButtonId("Run again", "primary-action"),
            "the explicit identity must survive visible label changes"
        );
    }

    [Test]
    void StableWidgetIds_RepeatedControlsStayDistinct(Tests::Context@ ctx) {
        ctx.AssertNotSame(
            RecipeStableWidgetIds::ButtonId("Run", "action-0"),
            RecipeStableWidgetIds::ButtonId("Run", "action-1"),
            "same-label controls need distinct stable identities"
        );
    }
}
