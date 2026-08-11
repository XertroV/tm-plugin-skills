namespace Tests {
    [Test]
    void DeterministicPulse_PhaseClampsAndNormalizes(Tests::Context@ ctx) {
        ctx.AssertSameApprox(RecipeDeterministicPulse::Phase(-1), 0.0f, "negative frames clamp to zero");
        ctx.AssertSameApprox(RecipeDeterministicPulse::Phase(0), 0.0f, "frame zero starts the pulse");
        ctx.AssertSameApprox(RecipeDeterministicPulse::Phase(60), 0.5f, "frame 60 is the midpoint");
        ctx.AssertSameApprox(RecipeDeterministicPulse::Phase(120), 1.0f, "frame 120 completes the pulse");
        ctx.AssertSameApprox(RecipeDeterministicPulse::Phase(121), 1.0f, "frames above 120 clamp to one");
    }

    [Test]
    void SkillpackDemoLib_PhaseHandlesInvalidRange(Tests::Context@ ctx) {
        ctx.AssertSameApprox(SkillpackDemoLib::PhaseFromFrame(10, 0), 0.0f, "an invalid maximum returns zero");
    }
}
