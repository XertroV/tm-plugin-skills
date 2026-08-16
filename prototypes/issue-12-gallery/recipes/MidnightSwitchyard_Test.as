namespace Tests {
    [Test]
    void MidnightSwitchyard_WaveClosesLoop(Tests::Context@ ctx) {
        for (int node = 0; node < RecipeMidnightSwitchyard::NodeCount(); node++) {
            ctx.AssertSameApprox(
                RecipeMidnightSwitchyard::NodeEnergy(node, 0.0f),
                RecipeMidnightSwitchyard::NodeEnergy(node, 1.0f),
                "node " + node + " closes the loop"
            );
        }
    }

    [Test]
    void MidnightSwitchyard_ThroatEnergizesBeforeTerminus(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeMidnightSwitchyard::NodeDistance(0) < RecipeMidnightSwitchyard::NodeDistance(6), "throat is nearer the wave origin than the terminus");
        // Early in the crossing the throat is lit while the terminus is dark.
        ctx.AssertTrue(RecipeMidnightSwitchyard::NodeEnergy(0, 0.05f) > 0.0f, "throat energizes early");
        ctx.AssertTrue(RecipeMidnightSwitchyard::NodeEnergy(6, 0.05f) == 0.0f, "terminus still dark early");
        // Late in the crossing the terminus has seen the wave.
        ctx.AssertTrue(RecipeMidnightSwitchyard::NodeEnergy(6, 0.95f) >= 0.0f, "terminus is reachable");
    }

    [Test]
    void MidnightSwitchyard_EnergyStaysNormalized(Tests::Context@ ctx) {
        for (int node = 0; node < RecipeMidnightSwitchyard::NodeCount(); node++) {
            for (int sample = 0; sample <= 20; sample++) {
                float energy = RecipeMidnightSwitchyard::NodeEnergy(node, float(sample) / 20.0f);
                ctx.AssertTrue(energy >= 0.0f && energy <= 1.0f, "node " + node + " energy normalized at sample " + sample);
            }
        }
    }

    [Test]
    void MidnightSwitchyard_EdgeGraphIsConnectedAndValid(Tests::Context@ ctx) {
        for (int edge = 0; edge < RecipeMidnightSwitchyard::EdgeCount(); edge++) {
            int from, to;
            RecipeMidnightSwitchyard::EdgeEnds(edge, from, to);
            ctx.AssertTrue(from >= 0 && from < RecipeMidnightSwitchyard::NodeCount(), "edge " + edge + " from-node valid");
            ctx.AssertTrue(to >= 0 && to < RecipeMidnightSwitchyard::NodeCount(), "edge " + edge + " to-node valid");
            ctx.AssertTrue(from != to, "edge " + edge + " is not a self loop");
        }
        // Every node except the throat is reachable from some edge.
        bool[] reached(RecipeMidnightSwitchyard::NodeCount(), false);
        reached[0] = true;
        for (int edge = 0; edge < RecipeMidnightSwitchyard::EdgeCount(); edge++) {
            int from, to;
            RecipeMidnightSwitchyard::EdgeEnds(edge, from, to);
            reached[to] = true;
        }
        for (int node = 0; node < RecipeMidnightSwitchyard::NodeCount(); node++) {
            ctx.AssertTrue(reached[node], "node " + node + " is reachable");
        }
    }

    [Test]
    void MidnightSwitchyard_SwitchesPhysicallySwing(Tests::Context@ ctx) {
        bool sawOpen = false;
        bool sawClosed = false;
        for (int sample = 0; sample <= 24; sample++) {
            float phase = float(sample) / 24.0f;
            if (RecipeMidnightSwitchyard::IsSwitchOpen(4, phase)) sawOpen = true; else sawClosed = true;
        }
        ctx.AssertTrue(sawOpen && sawClosed, "central junction swings open and closed across the loop");
    }

    [Test]
    void MidnightSwitchyard_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeMidnightSwitchyard::clipDepth == 0, "render-independent start-state assertion");
    }
}
