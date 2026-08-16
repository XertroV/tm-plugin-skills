// GENERATED COPY sha256=86dacdc9b8cf5cc660ed805d788d3c7a16557abc8e73565b7b67d25c5bd9ed9f source=recipes/AltitudeLedger_Test.as
namespace Tests {
    [Test]
    void AltitudeLedger_AscentClosesLoop(Tests::Context@ ctx) {
        for (int c = 0; c < RecipeAltitudeLedger::ClimberCount(); c++) {
            ctx.AssertSameApprox(
                RecipeAltitudeLedger::ClimberAltitude(c, 0.0f),
                RecipeAltitudeLedger::ClimberAltitude(c, 1.0f),
                "climber " + c + " closes the loop"
            );
        }
    }

    [Test]
    void AltitudeLedger_AltitudeStaysOnCourse(Tests::Context@ ctx) {
        for (int c = 0; c < RecipeAltitudeLedger::ClimberCount(); c++) {
            for (int sample = 0; sample <= 20; sample++) {
                float altitude = RecipeAltitudeLedger::ClimberAltitude(c, float(sample) / 20.0f);
                ctx.AssertTrue(altitude >= 0.0f && altitude < 1.0f, "climber " + c + " stays inside the course at sample " + sample);
            }
        }
    }

    [Test]
    void AltitudeLedger_RanksFormACompleteOrder(Tests::Context@ ctx) {
        for (int sample = 0; sample <= 12; sample++) {
            float phase = float(sample) / 12.0f;
            bool[] seen(RecipeAltitudeLedger::ClimberCount(), false);
            for (int c = 0; c < RecipeAltitudeLedger::ClimberCount(); c++) {
                int rank = RecipeAltitudeLedger::ClimberRank(c, phase);
                ctx.AssertTrue(rank >= 0 && rank < RecipeAltitudeLedger::ClimberCount(), "rank in range at sample " + sample);
                ctx.AssertFalse(seen[rank], "no shared rank at sample " + sample);
                seen[rank] = true;
            }
        }
    }

    [Test]
    void AltitudeLedger_LabelRowsNeverOverlap(Tests::Context@ ctx) {
        float ladderTop = 62.0f;
        float ladderH = 202.0f;
        float rowHeight = ladderH / float(RecipeAltitudeLedger::ClimberCount());
        float previous = -1000.0f;
        for (int rank = 0; rank < RecipeAltitudeLedger::ClimberCount(); rank++) {
            float rowY = RecipeAltitudeLedger::LabelRowY(rank, ladderTop, ladderH);
            ctx.AssertTrue(rowY - previous >= rowHeight - 0.001f, "rank row " + rank + " keeps the minimum gap");
            previous = rowY;
        }
    }

    [Test]
    void AltitudeLedger_HeroAndFallingStatesAreDistinct(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeAltitudeLedger::IsHero(0), "climber zero is the hero");
        ctx.AssertFalse(RecipeAltitudeLedger::IsHero(3), "rivals are not the hero");
        bool anyFalling = false;
        bool anyHolding = false;
        for (int c = 0; c < RecipeAltitudeLedger::ClimberCount(); c++) {
            for (int sample = 0; sample < 24; sample++) {
                if (RecipeAltitudeLedger::IsFalling(c, float(sample) / 24.0f)) anyFalling = true; else anyHolding = true;
            }
        }
        ctx.AssertTrue(anyFalling && anyHolding, "the ladder tells both falling and holding stories");
    }

    [Test]
    void AltitudeLedger_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeAltitudeLedger::clipDepth == 0, "render-independent start-state assertion");
    }
}
