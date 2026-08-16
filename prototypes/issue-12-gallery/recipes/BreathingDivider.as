namespace RecipeBreathingDivider {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    // The tm-agent ornament: a horizontal rule with a breathing dot at its
    // center. Frame 0/60/120 sample the pulse at trough/peak/trough.
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

    // One divider: two line segments meeting at a glowing dot, all breathing.
    void DrawDivider(UI::DrawList@ dl, vec2 center, float width, vec4 color, float pulse) {
        float leftX = center.x - width * 0.5f;
        float y = center.y;
        vec4 lineCol = vec4(color.x, color.y, color.z, color.w * (0.55f + 0.45f * pulse));
        vec4 dotCol = vec4(color.x, color.y, color.z, 0.35f + 0.55f * pulse);
        float dotR = 2.0f + 1.2f * pulse;

        dl.AddLine(vec2(leftX, y), vec2(center.x - 8.0f, y), lineCol, 1.0f);
        dl.AddLine(vec2(center.x + 8.0f, y), vec2(leftX + width, y), lineCol, 1.0f);
        vec4 glowCol = vec4(color.x, color.y, color.z, 0.08f + 0.12f * pulse);
        dl.AddCircleFilled(center, dotR + 3.0f, glowCol, 16);
        dl.AddCircleFilled(center, dotR, dotCol, 16);
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
        vec4 amber = vec4(0.95f, 0.65f, 0.15f, 0.9f);
        vec4 cyan = vec4(0.30f, 0.70f, 0.80f, 0.9f);
        vec4 violet = vec4(0.70f, 0.55f, 0.85f, 0.9f);

        dl.AddRectFilled(vec4(pos, size), slate, 0.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(18);
        dl.AddText(vec2(pos.x + 24.0f, pos.y + 16.0f), bone, "BREATHING DIVIDER");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(max.x - 24.0f - UI::MeasureString("section ornament").x, pos.y + 20.0f), quiet, "section ornament");

        // Three dividers at different accents and widths, all sharing the one
        // breathing cycle — the tm-agent insight is that every pulsing element
        // breathes together.
        float cx = pos.x + size.x * 0.5f;
        DrawDivider(dl, vec2(cx, pos.y + 64.0f), size.x * 0.72f, amber, pulse);
        DrawDivider(dl, vec2(cx, pos.y + 108.0f), size.x * 0.55f, cyan, pulse);
        DrawDivider(dl, vec2(cx, pos.y + 152.0f), size.x * 0.40f, violet, pulse);

        dl.AddText(vec2(pos.x + 24.0f, max.y - 24.0f), quiet, "shared 6s breath · line fades · dot swells + glows");

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · pulse = " + Text::Format("%.3f", pulse));
        UI::Text("tm-agent centered ornament · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
