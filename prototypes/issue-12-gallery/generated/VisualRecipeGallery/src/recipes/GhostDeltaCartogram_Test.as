// GENERATED COPY sha256=676047fe53f018b6ad8fc056d795b9e280e9bd6a81377a515f82e62f9c66840a source=recipes/GhostDeltaCartogram_Test.as
namespace Tests {
    [Test]
    void GhostDeltaCartogram_RouteIsClosedAndOnCanvas(Tests::Context@ ctx) {
        for (int i = 0; i < RecipeGhostDeltaCartogram::RoutePoints(); i++) {
            vec2 p = RecipeGhostDeltaCartogram::RoutePoint(i);
            ctx.AssertTrue(Math::Abs(p.x) <= 1.0f && Math::Abs(p.y) <= 1.0f, "route point " + i + " stays inside the unit field");
        }
        // First and last neighbors must connect: the route wraps cleanly.
        vec2 first = RecipeGhostDeltaCartogram::RoutePoint(0);
        vec2 last = RecipeGhostDeltaCartogram::RoutePoint(RecipeGhostDeltaCartogram::RoutePoints() - 1);
        float gap = (first - last).Length();
        ctx.AssertTrue(gap < 0.35f, "route closes without a visible seam");
    }

    [Test]
    void GhostDeltaCartogram_DeltaFieldClosesLoop(Tests::Context@ ctx) {
        for (int i = 0; i < RecipeGhostDeltaCartogram::RoutePoints(); i += 6) {
            ctx.AssertSameApprox(
                RecipeGhostDeltaCartogram::DeltaAt(i, 0.0f),
                RecipeGhostDeltaCartogram::DeltaAt(i, 1.0f),
                "delta at point " + i + " closes the loop"
            );
        }
    }

    [Test]
    void GhostDeltaCartogram_FieldTellsGainAndLoss(Tests::Context@ ctx) {
        bool sawGain = false;
        bool sawLoss = false;
        for (int i = 0; i < RecipeGhostDeltaCartogram::RoutePoints(); i++) {
            float delta = RecipeGhostDeltaCartogram::DeltaAt(i, 0.5f);
            if (delta > 0.05f) sawGain = true;
            if (delta < -0.05f) sawLoss = true;
        }
        ctx.AssertTrue(sawGain && sawLoss, "mid-run field carries both gain and loss");
    }

    [Test]
    void GhostDeltaCartogram_ChaseKeepsGhostBehind(Tests::Context@ ctx) {
        int n = RecipeGhostDeltaCartogram::RoutePoints();
        for (int sample = 0; sample < 12; sample++) {
            float phase = float(sample) / 12.0f;
            int live = RecipeGhostDeltaCartogram::TracerIndex(phase);
            int ghost = RecipeGhostDeltaCartogram::GhostIndex(phase);
            int gap = (live - ghost + n) % n;
            ctx.AssertSame(gap, 9, "ghost holds a constant nine-point trail at sample " + sample);
        }
        ctx.AssertSame(RecipeGhostDeltaCartogram::TracerIndex(0.0f), RecipeGhostDeltaCartogram::TracerIndex(1.0f), "tracer closes the loop");
    }

    [Test]
    void GhostDeltaCartogram_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeGhostDeltaCartogram::clipDepth == 0, "render-independent start-state assertion");
    }
}
