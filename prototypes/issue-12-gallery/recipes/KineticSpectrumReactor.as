namespace RecipeKineticSpectrumReactor {
    int clipDepth = 0;
    int lastCaptureFrame = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    float Breath(int captureFrame) {
        return 0.5f - 0.5f * Math::Cos(Phase(captureFrame) * Math::PI * 2.0f);
    }

    vec4 Spectrum(float t) {
        t = t - Math::Floor(t);
        vec4 cyan = vec4(0.12f, 0.92f, 1.00f, 1.0f);
        vec4 violet = vec4(0.55f, 0.22f, 1.00f, 1.0f);
        vec4 magenta = vec4(1.00f, 0.18f, 0.62f, 1.0f);
        vec4 amber = vec4(1.00f, 0.62f, 0.12f, 1.0f);
        if (t < 0.25f) return Math::Lerp(cyan, violet, t * 4.0f);
        if (t < 0.50f) return Math::Lerp(violet, magenta, (t - 0.25f) * 4.0f);
        if (t < 0.75f) return Math::Lerp(magenta, amber, (t - 0.50f) * 4.0f);
        return Math::Lerp(amber, cyan, (t - 0.75f) * 4.0f);
    }

    void PushClip(UI::DrawList@ dl, vec2 min, vec2 max) {
        dl.PushClipRect(vec4(min, max - min));
        clipDepth++;
    }

    void PopClip(UI::DrawList@ dl) {
        dl.PopClipRect();
        clipDepth--;
    }

    void DrawGradientField(UI::DrawList@ dl, vec2 min, vec2 max, float phase, float breath) {
        float outer = 8.0f + 3.0f * breath;
        vec4 c0 = Spectrum(phase);
        vec4 c1 = Spectrum(phase + 0.25f);
        vec4 c2 = Spectrum(phase + 0.50f);
        vec4 c3 = Spectrum(phase + 0.75f);
        c0.w = c1.w = c2.w = c3.w = 0.18f;
        dl.AddRectFilledMultiColor(vec4(min, max - min), c0, c1, c2, c3);
        dl.AddRectFilled(
            vec4(min + vec2(outer, outer), max - min - vec2(outer * 2.0f, outer * 2.0f)),
            vec4(0.005f, 0.008f, 0.024f, 0.985f)
        );

        float edge = 3.0f + 2.0f * breath;
        c0.w = c1.w = c2.w = c3.w = 0.92f;
        dl.AddRectFilledMultiColor(vec4(min, vec2(max.x - min.x, edge)), c0, c1, c1, c0);
        dl.AddRectFilledMultiColor(vec4(vec2(min.x, max.y - edge), vec2(max.x - min.x, edge)), c3, c2, c2, c3);
        dl.AddRectFilledMultiColor(vec4(min, vec2(edge, max.y - min.y)), c0, c0, c3, c3);
        dl.AddRectFilledMultiColor(vec4(vec2(max.x - edge, min.y), vec2(edge, max.y - min.y)), c1, c1, c2, c2);
    }

    void DrawConduit(UI::DrawList@ dl, vec2 from, vec2 to, vec4 color, float breath) {
        vec4 haze = color;
        haze.w = 0.08f + 0.08f * breath;
        dl.AddLine(from, to, haze, 8.0f);
        color.w = 0.40f + 0.30f * breath;
        dl.AddLine(from, to, color, 1.5f);
    }

    void DrawPanel(int captureFrame) {
        lastCaptureFrame = captureFrame;
        float phase = Phase(captureFrame);
        float breath = Breath(captureFrame);
        vec2 pos = UI::GetCursorScreenPos();
        vec2 size = vec2(Math::Max(470.0f, UI::GetContentRegionAvail().x - 16.0f), 320.0f);
        vec2 max = pos + size;
        vec2 center = pos + size * 0.5f;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);
        DrawGradientField(dl, pos, max, phase, breath);

        vec4 cold = Spectrum(phase);
        vec4 warm = Spectrum(phase + 0.55f);
        vec4 cross = Spectrum(phase + 0.28f);
        DrawConduit(dl, vec2(pos.x + 8.0f, center.y), vec2(center.x - 82.0f, center.y), cold, breath);
        DrawConduit(dl, vec2(max.x - 8.0f, center.y), vec2(center.x + 82.0f, center.y), warm, breath);
        DrawConduit(dl, vec2(center.x, pos.y + 8.0f), vec2(center.x, center.y - 82.0f), cross, breath);
        DrawConduit(dl, vec2(center.x, max.y - 8.0f), vec2(center.x, center.y + 82.0f), Spectrum(phase + 0.78f), breath);

        dl.AddCircleFilled(center, 96.0f, vec4(0.002f, 0.004f, 0.014f, 0.99f), 72);
        dl.AddCircleFilled(center, 86.0f, vec4(0.012f, 0.018f, 0.052f, 0.99f), 72);
        vec4 rim = Spectrum(phase + 0.12f);
        rim.w = 0.15f;
        dl.AddCircleFilled(center, 78.0f, rim, 72);
        dl.AddCircleFilled(center, 70.0f, vec4(0.006f, 0.009f, 0.028f, 0.99f), 72);

        vec4 core = Spectrum(phase + 0.18f);
        float coreRadius = 34.0f + 8.0f * breath;
        for (int ring = 7; ring >= 1; ring--) {
            float f = float(ring) / 7.0f;
            vec4 glow = core;
            glow.w = 0.025f + (1.0f - f) * 0.12f;
            dl.AddCircleFilled(center, coreRadius + float(ring) * 7.0f, glow, 56);
        }
        core.w = 0.72f + 0.20f * breath;
        dl.AddCircleFilled(center, coreRadius, core, 56);
        dl.AddCircleFilled(center, 9.0f + 4.0f * breath, vec4(0.96f, 0.99f, 1.0f, 0.96f), 40);

        for (int spark = 0; spark < 10; spark++) {
            float angle = phase * Math::PI * 2.0f + float(spark) / 10.0f * Math::PI * 2.0f;
            float radius = spark % 2 == 0 ? 61.0f : 78.0f;
            vec2 sparkPos = center + vec2(Math::Cos(angle) * radius, Math::Sin(angle) * radius * 0.62f);
            vec2 trailPos = center + vec2(Math::Cos(angle - 0.09f) * radius, Math::Sin(angle - 0.09f) * radius * 0.62f);
            vec4 sparkColor = Spectrum(phase + float(spark) / 10.0f);
            vec4 trailColor = sparkColor;
            trailColor.w = 0.20f;
            dl.AddLine(trailPos, sparkPos, trailColor, 3.0f);
            sparkColor.w = 0.92f;
            dl.AddCircleFilled(sparkPos, spark % 2 == 0 ? 3.5f : 2.5f, sparkColor, 16);
        }

        for (int tick = 0; tick < 28; tick++) {
            float angle = float(tick) / 28.0f * Math::PI * 2.0f;
            float energy = 4.0f + 7.0f * (0.5f + 0.5f * Math::Sin(float(tick) * 1.7f + phase * Math::PI * 4.0f));
            vec2 a = center + vec2(Math::Cos(angle) * 88.0f, Math::Sin(angle) * 88.0f);
            vec2 b = center + vec2(Math::Cos(angle) * (88.0f + energy), Math::Sin(angle) * (88.0f + energy));
            vec4 tickColor = Spectrum(phase + float(tick) / 28.0f);
            tickColor.w = 0.30f + 0.35f * breath;
            dl.AddLine(a, b, tickColor, 1.5f);
        }

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned containment field · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
