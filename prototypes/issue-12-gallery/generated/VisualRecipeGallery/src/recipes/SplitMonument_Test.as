// GENERATED COPY sha256=f746e7aaf1766b892f53838144a182bfcece115b99a4a96f152f43c0454af3b9 source=recipes/SplitMonument_Test.as
namespace Tests {
    [Test]
    void SplitMonument_PhaseIsCaptureOwned(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeSplitMonument::Phase(-1), 0.0f, "negative frames clamp");
        ctx.AssertSameApprox(RecipeSplitMonument::Phase(60), 0.5f, "frame 60 is midpoint");
        ctx.AssertSameApprox(RecipeSplitMonument::Phase(121), 1.0f, "frames above matrix clamp");
    }

    [Test]
    void SplitMonument_HighlightSequenceClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSame(RecipeSplitMonument::HighlightSector(0), 0, "frame 0 starts at sector I");
        ctx.AssertSame(RecipeSplitMonument::HighlightSector(30), 1, "frame 30 highlights sector II");
        ctx.AssertSame(RecipeSplitMonument::HighlightSector(60), 2, "frame 60 highlights sector III");
        ctx.AssertSame(RecipeSplitMonument::HighlightSector(90), 3, "frame 90 highlights final result");
        ctx.AssertSame(RecipeSplitMonument::HighlightSector(120), 0, "frame 120 closes the loop");
    }

    [Test]
    void SplitMonument_DeltasRemainStable(Tests::Context@ ctx) {
        ctx.AssertSame(RecipeSplitMonument::SectorDelta(0), "−0.118", "sector I delta");
        ctx.AssertSame(RecipeSplitMonument::SectorDelta(1), "+0.036", "sector II delta");
        ctx.AssertSame(RecipeSplitMonument::SectorDelta(2), "−0.202", "sector III delta");
        ctx.AssertSame(RecipeSplitMonument::SectorDelta(3), "−0.284", "final delta");
    }

    [Test]
    void SplitMonument_LossUsesDistinctAccent(Tests::Context@ ctx) {
        vec4 gain = RecipeSplitMonument::AccentForSector(0);
        vec4 loss = RecipeSplitMonument::AccentForSector(1);
        ctx.AssertTrue(loss.x > gain.x, "loss accent is warmer than gain");
        ctx.AssertTrue(gain.y > loss.y, "gain accent is greener than loss");
    }
}
