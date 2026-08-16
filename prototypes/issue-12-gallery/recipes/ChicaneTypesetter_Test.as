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
    void ChicaneTypesetter_ArcTHitsTheEnds(Tests::Context@ ctx) {
        vec2 field = RecipeChicaneTypesetter::DemoField();
        ctx.AssertSameApprox(RecipeChicaneTypesetter::ArcT(0.0f, field), 0.0f, "arc start is t = 0");
        ctx.AssertSameApprox(RecipeChicaneTypesetter::ArcT(1.0f, field), 1.0f, "arc end is t = 1");
    }

    [Test]
    void ChicaneTypesetter_EqualArcDashesHaveUniformScreenLength(Tests::Context@ ctx) {
        // Equal-t sampling stretches/bunches dashes on the S-bends (ratio ~1.6
        // on the demo field). Arc-length samples must stay within 8%.
        vec2 field = RecipeChicaneTypesetter::DemoField();
        float minLen = 1000.0f;
        float maxLen = 0.0f;
        for (int s = 0; s < 32; s++) {
            float t0 = RecipeChicaneTypesetter::ArcT(float(s) / 32.0f, field);
            float t1 = RecipeChicaneTypesetter::ArcT(float(s + 1) / 32.0f, field);
            float len = RecipeChicaneTypesetter::ScreenSegLen(t0, t1, field);
            if (len < minLen) minLen = len;
            if (len > maxLen) maxLen = len;
        }
        ctx.AssertTrue(minLen > 0.5f, "arc dashes have real length");
        ctx.AssertTrue(maxLen / minLen < 1.08f, "equal-arc dashes stay within 8% length");
    }

    [Test]
    void ChicaneTypesetter_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeChicaneTypesetter::clipDepth == 0, "render-independent start-state assertion");
    }
}
