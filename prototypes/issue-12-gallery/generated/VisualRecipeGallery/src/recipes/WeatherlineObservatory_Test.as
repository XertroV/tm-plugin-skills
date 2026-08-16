// GENERATED COPY sha256=5aac74534869cd245eb0a8dfe476032daca4f6d517dc20485eb7c0b0068d9542 source=recipes/WeatherlineObservatory_Test.as
namespace Tests {
    [Test]
    void WeatherlineObservatory_FieldClosesLoop(Tests::Context@ ctx) {
        for (int gy = 0; gy < RecipeWeatherlineObservatory::GridH(); gy += 5) {
            for (int gx = 0; gx < RecipeWeatherlineObservatory::GridW(); gx += 7) {
                ctx.AssertSameApprox(
                    RecipeWeatherlineObservatory::Pressure(gx, gy, 0.0f),
                    RecipeWeatherlineObservatory::Pressure(gx, gy, 1.0f),
                    "pressure at " + gx + "," + gy + " closes the loop"
                );
            }
        }
    }

    [Test]
    void WeatherlineObservatory_ContourLevelsAreOrdered(Tests::Context@ ctx) {
        float previous = -1000.0f;
        for (int contour = 0; contour < RecipeWeatherlineObservatory::ContourCount(); contour++) {
            float level = RecipeWeatherlineObservatory::ContourLevel(contour);
            ctx.AssertTrue(level > previous, "contour " + contour + " rises above the last");
            previous = level;
        }
    }

    [Test]
    void WeatherlineObservatory_FieldSpansContourLevels(Tests::Context@ ctx) {
        float lowest = 1000.0f;
        float highest = -1000.0f;
        for (int gy = 0; gy < RecipeWeatherlineObservatory::GridH(); gy++) {
            for (int gx = 0; gx < RecipeWeatherlineObservatory::GridW(); gx++) {
                float p = RecipeWeatherlineObservatory::Pressure(gx, gy, 0.35f);
                lowest = Math::Min(lowest, p);
                highest = Math::Max(highest, p);
            }
        }
        float firstLevel = RecipeWeatherlineObservatory::ContourLevel(0);
        float lastLevel = RecipeWeatherlineObservatory::ContourLevel(RecipeWeatherlineObservatory::ContourCount() - 1);
        ctx.AssertTrue(lowest < firstLevel, "field dips below the lowest contour so lines exist");
        ctx.AssertTrue(highest > lastLevel, "field rises above the highest contour so lines exist");
    }

    [Test]
    void WeatherlineObservatory_CellMaskMatchesCornerStates(Tests::Context@ ctx) {
        for (int sample = 0; sample <= 8; sample++) {
            float phase = float(sample) / 8.0f;
            for (int contour = 0; contour < RecipeWeatherlineObservatory::ContourCount(); contour++) {
                float level = RecipeWeatherlineObservatory::ContourLevel(contour);
                for (int gy = 0; gy + 1 < RecipeWeatherlineObservatory::GridH(); gy += 3) {
                    for (int gx = 0; gx + 1 < RecipeWeatherlineObservatory::GridW(); gx += 4) {
                        int mask = RecipeWeatherlineObservatory::CellMask(gx, gy, level, phase);
                        bool hasContour = RecipeWeatherlineObservatory::CellHasContour(gx, gy, level, phase);
                        ctx.AssertTrue(hasContour == (mask != 0 && mask != 15), "mask and contour agree at " + gx + "," + gy);
                    }
                }
            }
        }
    }

    [Test]
    void WeatherlineObservatory_ContoursExistAcrossTheLoop(Tests::Context@ ctx) {
        for (int sample = 0; sample <= 6; sample++) {
            float phase = float(sample) / 6.0f;
            int crossings = 0;
            float level = RecipeWeatherlineObservatory::ContourLevel(RecipeWeatherlineObservatory::ContourCount() / 2);
            for (int gy = 0; gy + 1 < RecipeWeatherlineObservatory::GridH(); gy++) {
                for (int gx = 0; gx + 1 < RecipeWeatherlineObservatory::GridW(); gx++) {
                    if (RecipeWeatherlineObservatory::CellHasContour(gx, gy, level, phase)) crossings++;
                }
            }
            ctx.AssertTrue(crossings > 8, "primary isobar draws at sample " + sample);
        }
    }

    [Test]
    void WeatherlineObservatory_ClipInstrumentationStartsBalanced(Tests::Context@ ctx) {
        ctx.AssertTrue(RecipeWeatherlineObservatory::clipDepth == 0, "render-independent start-state assertion");
    }
}
