// GENERATED COPY sha256=551e203b63d4e5b21f0fe7d567fcb4ffabec89155a9c83c5b1718e1f9c970c55 source=recipes/GradientRule.as
namespace RecipeGradientRule {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    void PushClip(UI::DrawList@ dl, vec2 min, vec2 max) {
        dl.PushClipRect(vec4(min, max - min));
        clipDepth++;
    }

    void PopClip(UI::DrawList@ dl) {
        dl.PopClipRect();
        clipDepth--;
    }

    // A horizontal rule whose alpha peaks at the center and falls to zero at
    // both edges. Optionally the peak slides across the rule with phase.
    void DrawGradientRule(UI::DrawList@ dl, vec2 leftTop, float width, vec4 color, float peakCenter, float thickness) {
        int segments = 48;
        for (int s = 0; s < segments; s++) {
            float t0 = float(s) / float(segments);
            float t1 = float(s + 1) / float(segments);
            float mid = (t0 + t1) * 0.5f;
            // Triangular alpha profile around peakCenter (0..1 along the rule).
            float d = Math::Abs(mid - peakCenter);
            float a = Math::Max(0.0f, 1.0f - d * 2.4f);
            vec4 col = vec4(color.x, color.y, color.z, color.w * a);
            dl.AddLine(
                vec2(leftTop.x + t0 * width, leftTop.y),
                vec2(leftTop.x + t1 * width, leftTop.y),
                col, thickness
            );
        }
    }

    void DrawPanel(int captureFrame) {
        float phase = Phase(captureFrame);

        vec2 pos = UI::GetCursorScreenPos();
        vec2 available = UI::GetContentRegionAvail();
        vec2 size = vec2(Math::Max(380.0f, available.x - 16.0f), 200.0f);
        vec2 max = pos + size;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 slate = vec4(0.070f, 0.080f, 0.098f, 1.0f);
        vec4 bone = vec4(0.88f, 0.87f, 0.84f, 1.0f);
        vec4 quiet = vec4(0.62f, 0.63f, 0.60f, 1.0f);
        vec4 amber = vec4(0.95f, 0.65f, 0.15f, 0.9f);
        vec4 green = vec4(0.45f, 0.80f, 0.55f, 0.9f);
        vec4 sienna = vec4(0.85f, 0.45f, 0.32f, 0.9f);

        dl.AddRectFilled(vec4(pos, size), slate, 0.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(18);
        dl.AddText(vec2(pos.x + 24.0f, pos.y + 16.0f), bone, "GRADIENT RULE");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(max.x - 24.0f - UI::MeasureString("edge-mid-edge fade").x, pos.y + 20.0f), quiet, "edge-mid-edge fade");

        float ruleLeft = pos.x + 30.0f;
        float ruleW = size.x - 60.0f;

        // Static center-peaked rule (the tm-agent section-anchor).
        DrawGradientRule(dl, vec2(ruleLeft, pos.y + 64.0f), ruleW, amber, 0.5f, 2.0f);
        dl.AddText(vec2(ruleLeft, pos.y + 74.0f), quiet, "static section anchor");

        // A rule whose bright peak sweeps left→right with the loop.
        DrawGradientRule(dl, vec2(ruleLeft, pos.y + 122.0f), ruleW, green, phase, 2.0f);
        dl.AddText(vec2(ruleLeft, pos.y + 132.0f), quiet, "travelling peak");

        // A thicker, softer sienna rule.
        DrawGradientRule(dl, vec2(ruleLeft, pos.y + 172.0f), ruleW, sienna, 0.5f, 4.0f);
        dl.AddText(vec2(ruleLeft, pos.y + 184.0f), quiet, "heavy emphasis");

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · sweep phase = " + Text::Format("%.3f", phase));
        UI::Text("gradient section rule · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
