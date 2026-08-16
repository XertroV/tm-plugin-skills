namespace Tests {
    [Test]
    void SlipstreamLoom_WeaveClosesLoop(Tests::Context@ ctx) {
        for (int ribbon = 0; ribbon < RecipeSlipstreamLoom::RibbonCount(); ribbon++) {
            for (int sample = 0; sample <= 6; sample++) {
                float t = float(sample) / 6.0f;
                ctx.AssertSameApprox(
                    RecipeSlipstreamLoom::RibbonY(ribbon, t, 0.0f),
                    RecipeSlipstreamLoom::RibbonY(ribbon, t, 1.0f),
                    "ribbon " + ribbon + " closes the loop at t=" + sample
                );
            }
        }
    }

    [Test]
    void SlipstreamLoom_RibbonsStayOnCanvas(Tests::Context@ ctx) {
        for (int ribbon = 0; ribbon < RecipeSlipstreamLoom::RibbonCount(); ribbon++) {
            for (int sample = 0; sample <= 30; sample++) {
                float y = RecipeSlipstreamLoom::RibbonY(ribbon, float(sample) / 30.0f, 0.4f);
                ctx.AssertTrue(y >= 0.0f && y <= 1.0f, "ribbon " + ribbon + " stays on canvas at sample " + sample);
            }
        }
    }

    [Test]
    void SlipstreamLoom_WeaveOrderIsACompletePermutation(Tests::Context@ ctx) {
        for (int sample = 0; sample <= 12; sample++) {
            float t = float(sample) / 12.0f;
            bool[] seen(RecipeSlipstreamLoom::RibbonCount(), false);
            for (int ribbon = 0; ribbon < RecipeSlipstreamLoom::RibbonCount(); ribbon++) {
                int order = RecipeSlipstreamLoom::RibbonOrder(ribbon, t, 0.5f);
                ctx.AssertTrue(order >= 0 && order < RecipeSlipstreamLoom::RibbonCount(), "order in range at sample " + sample);
                ctx.AssertFalse(seen[order], "no shared order at sample " + sample);
                seen[order] = true;
            }
        }
    }

    [Test]
    void SlipstreamLoom_CrossingsActuallyHappen(Tests::Context@ ctx) {
        // Across a full phase sweep the front ribbon must change hands: the
        // weave is a braid, not four parallel lanes.
        bool[] wasFront(RecipeSlipstreamLoom::RibbonCount(), false);
        for (int sample = 0; sample <= 24; sample++) {
            float t = float(sample) / 24.0f;
            int bestOrder = -1;
            int front = 0;
            for (int ribbon = 0; ribbon < RecipeSlipstreamLoom::RibbonCount(); ribbon++) {
                int order = RecipeSlipstreamLoom::RibbonOrder(ribbon, t, 0.25f);
                if (order > bestOrder) { bestOrder = order; front = ribbon; }
            }
            wasFront[front] = true;
        }
        int frontCount = 0;
        for (int ribbon = 0; ribbon < RecipeSlipstreamLoom::RibbonCount(); ribbon++) {
            if (wasFront[ribbon]) frontCount++;
        }
        ctx.AssertTrue(frontCount >= 2, "at least two ribbons take the front across the weave");
    }

    [Test]
    void SlipstreamLoom_RibbonColorsAreDistinct(Tests::Context@ ctx) {
        for (int a = 0; a < RecipeSlipstreamLoom::RibbonCount(); a++) {
            for (int b = a + 1; b < RecipeSlipstreamLoom::RibbonCount(); b++) {
                vec4 first = RecipeSlipstreamLoom::RibbonColor(a);
                vec4 second = RecipeSlipstreamLoom::RibbonColor(b);
                float distance = Math::Abs(first.x - second.x) + Math::Abs(first.y - second.y) + Math::Abs(first.z - second.z);
                ctx.AssertTrue(distance > 0.15f, "ribbons " + a + " and " + b + " remain distinguishable");
            }
        }
    }

    [Test]
    void SlipstreamLoom_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeSlipstreamLoom::clipDepth == 0, "render-independent start-state assertion");
    }
}
