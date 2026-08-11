// Historical gallery checkpoint: exact initial ribbon-reactor source recovered
// from this Hermes session's original write_file tool call (message 45658).
// This file is intentionally committed once and removed immediately afterward;
// recover it from that commit when comparing visual iterations.

namespace RecipeKineticSpectrumReactor {
    int clipDepth = 0;
    int lastCaptureFrame = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    float Breath(int captureFrame) {
        return 0.5f - 0.5f * Math::Cos(Phase(captureFrame) * Math::PI * 2.0f);
    }

    vec4 LerpColor(const vec4 &in a, const vec4 &in b, float t) {
        float clamped = Math::Clamp(t, 0.0f, 1.0f);
        return vec4(
            a.x + (b.x - a.x) * clamped,
            a.y + (b.y - a.y) * clamped,
            a.z + (b.z - a.z) * clamped,
            a.w + (b.w - a.w) * clamped
        );
    }

    vec4 Spectrum(float phase) {
        float p = phase - Math::Floor(phase);
        vec4 cyan = vec4(0.06f, 0.84f, 0.96f, 1.0f);
        vec4 violet = vec4(0.56f, 0.28f, 0.96f, 1.0f);
        vec4 amber = vec4(1.0f, 0.58f, 0.12f, 1.0f);
        if (p < 0.333333f) return LerpColor(cyan, violet, p * 3.0f);
        if (p < 0.666667f) return LerpColor(violet, amber, (p - 0.333333f) * 3.0f);
        return LerpColor(amber, cyan, (p - 0.666667f) * 3.0f);
    }

    void DrawPanel(int captureFrame) {
        lastCaptureFrame = captureFrame;
        float phase = Phase(captureFrame);
        float breath = Breath(captureFrame);
        vec2 pos = UI::GetCursorScreenPos();
        float width = Math::Max(360.0f, UI::GetContentRegionAvail().x);
        vec2 size = vec2(width, 246.0f);
        vec2 center = pos + size * 0.5f;
        auto dl = UI::GetWindowDrawList();

        clipDepth++;
        dl.PushClipRect(vec4(pos, size));

        vec4 chamberA = vec4(0.018f, 0.028f, 0.065f, 1.0f);
        vec4 chamberB = vec4(0.055f, 0.026f, 0.095f, 1.0f);
        dl.AddRectFilledMultiColor(vec4(pos, size), chamberA, chamberB, vec4(0.008f, 0.015f, 0.038f, 1.0f), chamberA);

        for (int i = 0; i < 7; i++) {
            float y = pos.y + 30.0f + float(i) * 28.0f;
            float wave = Math::Sin(phase * Math::PI * 2.0f + float(i) * 0.83f);
            float x0 = pos.x + 18.0f;
            float x1 = pos.x + size.x - 18.0f;
            vec4 gridColor = Spectrum(phase + float(i) * 0.08f);
            gridColor.w = 0.055f + 0.035f * (wave * 0.5f + 0.5f);
            dl.AddLine(vec2(x0, y), vec2(x1, y + wave * 7.0f), gridColor, 1.0f);
        }

        float ribbonY = pos.y + 44.0f;
        float ribbonH = 18.0f + 8.0f * breath;
        int segments = 28;
        for (int i = 0; i < segments; i++) {
            float a = float(i) / float(segments);
            float b = float(i + 1) / float(segments);
            float x0 = pos.x + 18.0f + a * (size.x - 36.0f);
            float x1 = pos.x + 18.0f + b * (size.x - 36.0f);
            float y0 = ribbonY + Math::Sin((a + phase) * Math::PI * 4.0f) * 9.0f;
            float y1 = ribbonY + Math::Sin((b + phase) * Math::PI * 4.0f) * 9.0f;
            vec4 color = Spectrum(a + phase);
            color.w = 0.35f + 0.42f * breath;
            dl.AddLine(vec2(x0, y0), vec2(x1, y1), color, ribbonH);
            vec4 hot = color;
            hot.w = 0.86f;
            dl.AddLine(vec2(x0, y0), vec2(x1, y1), hot, 2.0f);
        }

        vec4 core = Spectrum(phase + 0.18f);
        float coreRadius = 26.0f + 7.0f * breath;
        for (int ring = 6; ring >= 1; ring--) {
            float f = float(ring) / 6.0f;
            vec4 glow = core;
            glow.w = (1.0f - f) * (0.09f + 0.08f * breath);
            dl.AddCircleFilled(center, coreRadius + f * 34.0f, glow, 48);
        }
        vec4 coreOuter = core;
        coreOuter.w = 0.28f;
        dl.AddCircleFilled(center, coreRadius, coreOuter, 48);
        vec4 coreInner = LerpColor(core, vec4(1.0f), 0.68f);
        coreInner.w = 0.92f;
        dl.AddCircleFilled(center, 8.0f + 4.0f * breath, coreInner, 32);

        for (int spark = 0; spark < 6; spark++) {
            float angle = phase * Math::PI * 2.0f + float(spark) * Math::PI / 3.0f;
            float radius = 58.0f + float(spark % 2) * 17.0f;
            vec2 sparkPos = center + vec2(Math::Cos(angle), Math::Sin(angle)) * radius;
            vec4 sparkColor = Spectrum(phase + float(spark) / 6.0f);
            vec4 sparkGlow = sparkColor;
            sparkGlow.w = 0.12f;
            dl.AddCircleFilled(sparkPos, 7.0f, sparkGlow, 20);
            sparkColor.w = 0.88f;
            dl.AddCircleFilled(sparkPos, 2.2f, sparkColor, 16);
        }

        vec2 meterPos = vec2(pos.x + 24.0f, pos.y + size.y - 34.0f);
        float meterW = size.x - 48.0f;
        for (int i = 0; i < 32; i++) {
            float x = meterPos.x + float(i) / 31.0f * meterW;
            float energy = 5.0f + 13.0f * (0.5f + 0.5f * Math::Sin(float(i) * 0.74f + phase * Math::PI * 4.0f));
            vec4 meterColor = Spectrum(phase + float(i) / 32.0f);
            meterColor.w = 0.78f;
            dl.AddLine(vec2(x, meterPos.y - energy), vec2(x, meterPos.y + energy), meterColor, 2.0f);
        }

        dl.PopClipRect();
        clipDepth--;
        UI::Dummy(size);
        UI::Text("animation-state frame = " + lastCaptureFrame + " · phase = " + Text::Format("%.3f", phase));
        UI::TextDisabled("capture-owned motion · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
