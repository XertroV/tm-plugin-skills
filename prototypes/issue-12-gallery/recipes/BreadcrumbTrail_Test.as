namespace Tests {
    [Test]
    void BreadcrumbTrail_ActiveAdvancesAndLoops(Tests::Context@ ctx) {
        ctx.AssertSame(int(RecipeBreadcrumbTrail::Phase(0) * 3.0f) % 3, 0, "frame 0 activates first segment");
        ctx.AssertSame(int(RecipeBreadcrumbTrail::Phase(120) * 3.0f) % 3, 0, "loop returns to first segment");
    }

    [Test]
    void BreadcrumbTrail_ClipRestoresDepth(Tests::Context@ ctx) {
        auto dl = UI::GetWindowDrawList();
        int before = RecipeBreadcrumbTrail::clipDepth;
        RecipeBreadcrumbTrail::PushClip(dl, vec2(0, 0), vec2(10, 10));
        RecipeBreadcrumbTrail::PopClip(dl);
        ctx.AssertSame(RecipeBreadcrumbTrail::clipDepth, before, "clip depth restores");
    }
}
