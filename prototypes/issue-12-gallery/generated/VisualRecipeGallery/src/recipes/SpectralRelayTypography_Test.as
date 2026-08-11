// GENERATED COPY sha256=efa1f459cd9e4ddcc417f8c3c40d496c3ff453baae89b474dd1c2959574b57cf source=recipes/SpectralRelayTypography_Test.as
namespace Tests {
    [Test]
    void SpectralRelayTypography_PhaseIsCaptureOwned(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::Phase(-1), 0.0f, "negative frames clamp");
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::Phase(60), 0.5f, "frame 60 is midpoint");
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::Phase(121), 1.0f, "frames above matrix clamp");
    }

    [Test]
    void SpectralRelayTypography_PingPongClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::PingPong(0.0f), 0.0f, "starts at edge");
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::PingPong(0.5f), 1.0f, "peaks at midpoint");
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::PingPong(1.0f), 0.0f, "returns to edge");
    }

    [Test]
    void SpectralRelayTypography_SignalWeightIsBounded(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::SignalWeight(5.0f, 5.0f, 4.0f), 1.0f, "signal center is hot");
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::SignalWeight(9.0f, 5.0f, 4.0f), 0.0f, "signal edge is dark");
        ctx.AssertSameApprox(RecipeSpectralRelayTypography::SignalWeight(12.0f, 5.0f, 4.0f), 0.0f, "outside signal is dark");
    }

    [Test]
    void SpectralRelayTypography_RelayColorLoops(Tests::Context@ ctx) {
        vec4 atStart = RecipeSpectralRelayTypography::RelayColor(0.0f);
        vec4 atEnd = RecipeSpectralRelayTypography::RelayColor(1.0f);
        ctx.AssertSameApprox(atStart.x, atEnd.x, "looped red channel");
        ctx.AssertSameApprox(atStart.y, atEnd.y, "looped green channel");
        ctx.AssertSameApprox(atStart.z, atEnd.z, "looped blue channel");
    }
}
