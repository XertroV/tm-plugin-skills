namespace Tests {
    [Test]
    void ApexEnvelope_PhaseAndLoopAreCaptureOwned(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeApexEnvelope::Phase(-1), 0.0f, "negative frames clamp");
        ctx.AssertSameApprox(RecipeApexEnvelope::Phase(0), 0.0f, "frame zero");
        ctx.AssertSameApprox(RecipeApexEnvelope::Phase(60), 0.5f, "frame midpoint");
        ctx.AssertSameApprox(RecipeApexEnvelope::Phase(120), 1.0f, "frame endpoint");
        ctx.AssertSameApprox(RecipeApexEnvelope::MarkerPosition(0), RecipeApexEnvelope::MarkerPosition(120), "marker closes loop");
        ctx.AssertSameApprox(RecipeApexEnvelope::SafeHalfWidth(0), RecipeApexEnvelope::SafeHalfWidth(120), "envelope closes loop");
    }

    [Test]
    void ApexEnvelope_StoryCrossesThresholdOnlyAtOverslip(Tests::Context@ ctx) {
        ctx.AssertFalse(RecipeApexEnvelope::IsOverslip(0), "settled state is safe");
        ctx.AssertFalse(RecipeApexEnvelope::IsOverslip(30), "loading state is safe");
        ctx.AssertFalse(RecipeApexEnvelope::IsOverslip(60), "threshold state remains contained");
        ctx.AssertTrue(RecipeApexEnvelope::IsOverslip(90), "overslip state crosses envelope");
        ctx.AssertFalse(RecipeApexEnvelope::IsOverslip(120), "loop returns safe");
        ctx.AssertTrue(RecipeApexEnvelope::Margin(90) < 0.0f, "overslip margin is negative");
    }

    [Test]
    void ApexEnvelope_ClipInstrumentationBalances(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeApexEnvelope::clipDepth == 0, "clip depth starts balanced");
    }
}
