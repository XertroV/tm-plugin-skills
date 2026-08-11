// GENERATED COPY sha256=48e9cb404a101fab4d0e91e14b314f34220d339f12bd75d0c86166b7d262b0d5 source=recipes/KineticSpectrumReactor_Test.as
namespace Tests {
    [Test]
    void KineticSpectrumReactor_PhaseIsCaptureOwned(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeKineticSpectrumReactor::Phase(-1), 0.0f, "negative capture frames clamp");
        ctx.AssertSameApprox(RecipeKineticSpectrumReactor::Phase(60), 0.5f, "frame 60 is the deterministic midpoint");
        ctx.AssertSameApprox(RecipeKineticSpectrumReactor::Phase(121), 1.0f, "capture frames above the matrix clamp");
    }

    [Test]
    void KineticSpectrumReactor_BreathClosesItsLoop(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeKineticSpectrumReactor::Breath(0), 0.0f, "the reactor begins at rest");
        ctx.AssertSameApprox(RecipeKineticSpectrumReactor::Breath(60), 1.0f, "the reactor peaks at the midpoint");
        ctx.AssertSameApprox(RecipeKineticSpectrumReactor::Breath(120), 0.0f, "the reactor returns to rest at loop end");
    }

    [Test]
    void KineticSpectrumReactor_SpectrumLoopsWithoutASeam(Tests::Context@ ctx) {
        vec4 atStart = RecipeKineticSpectrumReactor::Spectrum(0.0f);
        vec4 atEnd = RecipeKineticSpectrumReactor::Spectrum(1.0f);
        ctx.AssertSameApprox(atStart.x, atEnd.x, "looped red channel");
        ctx.AssertSameApprox(atStart.y, atEnd.y, "looped green channel");
        ctx.AssertSameApprox(atStart.z, atEnd.z, "looped blue channel");
    }
}
