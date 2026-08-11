#if DEV
namespace Tests {
    uint g_RegistryMutationCount = 0;
    void RegistryMutation() { g_RegistryMutationCount++; }

    [Test]
    void ComponentRegistry_NeverDrawnDoesNotMutate(Tests::Context@ ctx) {
        g_RegistryMutationCount = 0;
        SemanticControl::g_SealedRenderEpoch = 0;
        SemanticControl::UnregisterGeneration(700);
        ctx.AssertTrue(SemanticControl::Register("never-drawn", 700, "click", SemanticControl::SemanticAction(RegistryMutation)));
        ctx.AssertSame(SemanticControl::Invoke("never-drawn", 700, "click", false), "not_drawn");
        ctx.AssertSame(g_RegistryMutationCount, 0);
    }

    [Test]
    void ComponentRegistry_NotDrawnDoesNotMutateUnlessForced(Tests::Context@ ctx) {
        g_RegistryMutationCount = 0;
        SemanticControl::UnregisterGeneration(701);
        ctx.AssertTrue(SemanticControl::Register("registry-test", 701, "click", SemanticControl::SemanticAction(RegistryMutation)), "register unique component");
        SemanticControl::BeginRenderEpoch();
        SemanticControl::SealRenderEpoch();
        ctx.AssertSame(SemanticControl::Invoke("registry-test", 701, "click", false), "not_drawn", "hidden component is rejected");
        ctx.AssertSame(g_RegistryMutationCount, 0, "rejection does not mutate");
        ctx.AssertSame(SemanticControl::Invoke("registry-test", 701, "click", true), "forced", "explicit force is truthful");
        ctx.AssertSame(g_RegistryMutationCount, 1, "forced semantic callback runs once");
        SemanticControl::UnregisterGeneration(701);
    }

    [Test]
    void ComponentRegistry_CompletedEpochAndGenerationAreRequired(Tests::Context@ ctx) {
        g_RegistryMutationCount = 0;
        SemanticControl::Register("epoch-test", 702, "click", SemanticControl::SemanticAction(RegistryMutation));
        SemanticControl::BeginRenderEpoch();
        SemanticControl::MarkDrawn("epoch-test");
        SemanticControl::SealRenderEpoch();
        ctx.AssertSame(SemanticControl::Invoke("epoch-test", 999, "click", false), "stale_registration", "stale owner is rejected");
        ctx.AssertSame(SemanticControl::Invoke("epoch-test", 702, "click", false), "performed", "drawn component runs semantically");
        ctx.AssertSame(g_RegistryMutationCount, 1, "visible callback runs once");
        SemanticControl::UnregisterGeneration(702);
    }
}
#endif
