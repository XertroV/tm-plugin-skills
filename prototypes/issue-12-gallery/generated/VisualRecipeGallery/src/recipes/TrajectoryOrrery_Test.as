// GENERATED COPY sha256=5fb2de3c50c33227eead5675d742a63d707e79daa89f3c7bfa4b4e81976d8414 source=recipes/TrajectoryOrrery_Test.as
namespace Tests {
    [Test]
    void TrajectoryOrrery_OrbitClosesLoop(Tests::Context@ ctx) {
        for (int body = 0; body < 5; body++) {
            vec3 start = RecipeTrajectoryOrrery::BodyPosition(body, 0.0f);
            vec3 end = RecipeTrajectoryOrrery::BodyPosition(body, 1.0f);
            ctx.AssertSameApprox(start.x, end.x, "body " + body + " x closes loop");
            ctx.AssertSameApprox(start.y, end.y, "body " + body + " y closes loop");
            ctx.AssertSameApprox(start.z, end.z, "body " + body + " z closes loop");
        }
    }

    [Test]
    void TrajectoryOrrery_EachBodyCrossesNearAndFar(Tests::Context@ ctx) {
        for (int body = 0; body < 5; body++) {
            bool sawNear = false;
            bool sawFar = false;
            for (int sample = 0; sample < 16; sample++) {
                float phase = float(sample) / 16.0f;
                if (RecipeTrajectoryOrrery::IsNear(body, phase)) sawNear = true; else sawFar = true;
            }
            ctx.AssertTrue(sawNear && sawFar, "body " + body + " crosses the near/far divide each orbit");
        }
    }

    [Test]
    void TrajectoryOrrery_DepthShadeOrdersNearAboveFar(Tests::Context@ ctx) {
        for (int body = 0; body < 5; body++) {
            float radius = 0.38f + float(body) * 0.115f;
            float nearShade = RecipeTrajectoryOrrery::DepthShade(radius * 0.9f, radius);
            float farShade = RecipeTrajectoryOrrery::DepthShade(-radius * 0.9f, radius);
            ctx.AssertTrue(nearShade > farShade, "body " + body + " near rim shades brighter than far rim");
            ctx.AssertTrue(nearShade <= 1.0f && farShade >= 0.0f, "body " + body + " shade stays normalized");
        }
    }

    [Test]
    void TrajectoryOrrery_ApparentSizeFollowsDepth(Tests::Context@ ctx) {
        for (int body = 0; body < 5; body++) {
            float largest = 0.0f;
            float smallest = 1000.0f;
            for (int sample = 0; sample < 24; sample++) {
                float r = RecipeTrajectoryOrrery::BodyRadius(body, float(sample) / 24.0f);
                largest = Math::Max(largest, r);
                smallest = Math::Min(smallest, r);
            }
            ctx.AssertTrue(largest > smallest, "body " + body + " breathes with depth");
            ctx.AssertTrue(smallest >= 3.0f, "body " + body + " never vanishes");
        }
    }

    [Test]
    void TrajectoryOrrery_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeTrajectoryOrrery::clipDepth == 0, "render-independent start-state assertion");
    }
}
