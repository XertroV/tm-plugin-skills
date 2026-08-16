// GENERATED COPY sha256=3d82479ecede94f0de9770dc4a0ba81c4049af2dcfc3a4be3cb75c463b480215 source=recipes/IconHalo.as
namespace RecipeIconHalo {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    float Pulse(int captureFrame) {
        return 0.5f - 0.5f * Math::Cos(Phase(captureFrame) * Math::PI * 2.0f);
    }

    void PushClip(UI::DrawList@ dl, vec2 min, vec2 max) {
        dl.PushClipRect(vec4(min, max - min));
        clipDepth++;
    }

    void PopClip(UI::DrawList@ dl) {
        dl.PopClipRect();
        clipDepth--;
    }

    // The tm-agent waiting badge: a rounded-square tile with a soft breathing
    // halo — many thin concentric rounded rects whose alpha falls off with
    // radius so they sum to a continuous glow rather than discrete rings.
    void DrawBadge(UI::DrawList@ dl, vec2 topLeft, float size, vec4 accent, const string &in glyph, float pulse) {
        float cx = topLeft.x + size * 0.5f;
        float cy = topLeft.y + size * 0.5f;
        int rings = 10;
        float maxExtra = 14.0f + 10.0f * pulse;
        for (int i = rings; i >= 1; i--) {
            float f = float(i) / float(rings);
            float ring = size + f * maxExtra * 2.0f;
            float a = (0.035f + 0.04f * pulse) * (1.0f - f);
            dl.AddRectFilled(vec4(cx - ring * 0.5f, cy - ring * 0.5f, ring, ring), vec4(accent.x, accent.y, accent.z, a), 8.0f + f * 14.0f);
        }
        vec4 fill = vec4(accent.x, accent.y, accent.z, 0.06f + 0.06f * pulse);
        vec4 stroke = vec4(accent.x, accent.y, accent.z, 0.18f + 0.18f * pulse);
        dl.AddRectFilled(vec4(topLeft, vec2(size, size)), fill, 8.0f);
        dl.AddRect(vec4(topLeft, vec2(size, size)), stroke, 8.0f, 1.0f);

        vec2 g = UI::MeasureString(glyph);
        vec4 glyphCol = vec4(accent.x, accent.y, accent.z, 0.72f + 0.20f * pulse);
        dl.AddText(vec2(cx - g.x * 0.5f, cy - g.y * 0.5f), glyphCol, glyph);
    }

    void DrawPanel(int captureFrame) {
        float pulse = Pulse(captureFrame);

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
        vec4 amber = vec4(0.95f, 0.65f, 0.15f, 1.0f);
        vec4 cyan = vec4(0.30f, 0.70f, 0.80f, 1.0f);
        vec4 green = vec4(0.45f, 0.80f, 0.55f, 1.0f);

        dl.AddRectFilled(vec4(pos, size), slate, 0.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(18);
        dl.AddText(vec2(pos.x + 24.0f, pos.y + 16.0f), bone, "ICON HALO BADGE");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(max.x - 24.0f - UI::MeasureString("waiting-state glow").x, pos.y + 20.0f), quiet, "waiting-state glow");

        // Three badges sharing the one breath, so the row pulses in unison.
        float cx = pos.x + size.x * 0.5f;
        float by = pos.y + 78.0f;
        float tile = 44.0f;
        float gap = 84.0f;
        DrawBadge(dl, vec2(cx - gap - tile * 0.5f, by), tile, amber, "!", pulse);
        DrawBadge(dl, vec2(cx - tile * 0.5f, by), tile, cyan, "i", pulse);
        DrawBadge(dl, vec2(cx + gap - tile * 0.5f, by), tile, green, "~", pulse);

        dl.AddText(vec2(pos.x + 24.0f, max.y - 24.0f), quiet, "concentric rounded rects sum to a soft halo");

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · pulse = " + Text::Format("%.3f", pulse));
        UI::Text("tm-agent waiting badge · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
