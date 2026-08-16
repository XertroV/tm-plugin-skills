namespace Tests {
    [Test]
    void StrategySwitchboard_RouteSequenceClosesLoop(Tests::Context@ ctx) {
        ctx.AssertSame(RecipeStrategySwitchboard::SelectedRoute(0), 0, "frame 0 starts on push");
        ctx.AssertSame(RecipeStrategySwitchboard::SelectedRoute(30), 1, "frame 30 holds balanced");
        ctx.AssertSame(RecipeStrategySwitchboard::SelectedRoute(60), 2, "frame 60 conserves");
        ctx.AssertSame(RecipeStrategySwitchboard::SelectedRoute(90), 3, "frame 90 commits overtake");
        ctx.AssertSame(RecipeStrategySwitchboard::SelectedRoute(120), 0, "frame 120 closes the loop");
    }

    [Test]
    void StrategySwitchboard_RoutesKeepDistinctAccents(Tests::Context@ ctx) {
        for (int a = 0; a < 4; a++) {
            for (int b = a + 1; b < 4; b++) {
                vec4 first = RecipeStrategySwitchboard::RouteAccent(a);
                vec4 second = RecipeStrategySwitchboard::RouteAccent(b);
                float distance = Math::Abs(first.x - second.x) + Math::Abs(first.y - second.y) + Math::Abs(first.z - second.z);
                ctx.AssertTrue(distance > 0.15f, "routes " + a + " and " + b + " remain distinguishable");
            }
        }
    }

    [Test]
    void StrategySwitchboard_EveryRouteHasNameAndDirective(Tests::Context@ ctx) {
        for (int route = 0; route < 4; route++) {
            ctx.AssertTrue(RecipeStrategySwitchboard::RouteName(route).Length > 0, "route " + route + " names itself");
            ctx.AssertTrue(RecipeStrategySwitchboard::RouteDirective(route).Length > 0, "route " + route + " carries a directive");
        }
    }

    [Test]
    void StrategySwitchboard_RailStopsStayOrderedInsideBounds(Tests::Context@ ctx) {
        float railLeft = 42.0f;
        float railRight = 418.0f;
        float previous = railLeft - 1.0f;
        for (int stop = 0; stop < 4; stop++) {
            float center = RecipeStrategySwitchboard::StopCenter(stop, railLeft, railRight);
            ctx.AssertTrue(center >= railLeft && center <= railRight, "stop " + stop + " stays on the rail");
            ctx.AssertTrue(center > previous, "stop " + stop + " advances along the rail");
            previous = center;
        }
    }

    [Test]
    void StrategySwitchboard_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeStrategySwitchboard::clipDepth == 0, "render-independent start-state assertion");
    }
}
