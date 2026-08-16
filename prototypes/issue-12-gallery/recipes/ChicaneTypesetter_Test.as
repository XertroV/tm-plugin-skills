namespace Tests {
    [Test]
    void ChicaneTypesetter_LineClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeChicaneTypesetter::TextAnchor(0.0f), RecipeChicaneTypesetter::TextAnchor(1.0f), "text anchor closes the loop");
        // The line is periodic in y: the sweep returns to the same height.
        vec2 start = RecipeChicaneTypesetter::LinePoint(0.0f);
        vec2 end = RecipeChicaneTypesetter::LinePoint(0.9999f);
        ctx.AssertSameApprox(start.y, end.y, "line height closes the loop");
    }

    [Test]
    void ChicaneTypesetter_LineStaysOnCanvas(Tests::Context@ ctx) {
        for (int sample = 0; sample <= 40; sample++) {
            vec2 p = RecipeChicaneTypesetter::LinePoint(float(sample) / 40.0f);
            ctx.AssertTrue(p.x >= 0.0f && p.x <= 1.0f, "line x in range at sample " + sample);
            ctx.AssertTrue(p.y >= 0.0f && p.y <= 1.0f, "line y in range at sample " + sample);
        }
    }

    [Test]
    void ChicaneTypesetter_TangentIsUnitLength(Tests::Context@ ctx) {
        for (int sample = 0; sample <= 24; sample++) {
            vec2 tan = RecipeChicaneTypesetter::LineTangent(float(sample) / 24.0f);
            ctx.AssertSameApprox(tan.Length(), 1.0f, "tangent is unit length at sample " + sample);
        }
    }

    [Test]
    void ChicaneTypesetter_TangentPointsAlongTravel(Tests::Context@ ctx) {
        // Tangent x must stay positive: the line always sweeps rightward.
        for (int sample = 0; sample <= 24; sample++) {
            vec2 tan = RecipeChicaneTypesetter::LineTangent(float(sample) / 24.0f);
            ctx.AssertTrue(tan.x > 0.0f, "tangent points forward at sample " + sample);
        }
    }

    [Test]
    void ChicaneTypesetter_WordmarkHasGlyphs(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeChicaneTypesetter::TrackText().Length >= 4, "the wordmark carries several glyphs");
    }

    [Test]
    void ChicaneTypesetter_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeChicaneTypesetter::clipDepth == 0, "render-independent start-state assertion");
    }
}
