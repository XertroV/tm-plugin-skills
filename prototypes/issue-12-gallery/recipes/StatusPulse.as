namespace RecipeStatusPulse {
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

    // A status row: a pulsing dot with an expanding sonar ring, plus a label
    // whose alpha tracks the same pulse.
    void DrawStatus(UI::DrawList@ dl, vec2 at, vec4 accent, const string &in label, float pulse) {
        vec2 dot = vec2(at.x + 7.0f, at.y + 7.0f);
        float ringR = 6.0f + 10.0f * pulse;
        vec4 ringCol = vec4(accent.x, accent.y, accent.z, 0.45f * (1.0f - pulse));
        dl.AddCircle(dot, ringR, ringCol, 20, 1.5f);
        vec4 dotCol = vec4(accent.x, accent.y, accent.z, 0.55f + 0.45f * pulse);
        dl.AddCircleFilled(dot, 4.0f, dotCol, 16);
        vec4 textCol = vec4(accent.x, accent.y, accent.z, 0.55f + 0.35f * pulse);
        dl.AddText(vec2(at.x + 22.0f, at.y), textCol, label);
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
        vec4 green = vec4(0.45f, 0.85f, 0.55f, 1.0f);
        vec4 amber = vec4(0.95f, 0.65f, 0.15f, 1.0f);
        vec4 sienna = vec4(0.88f, 0.42f, 0.30f, 1.0f);

        dl.AddRectFilled(vec4(pos, size), slate, 0.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(18);
        dl.AddText(vec2(pos.x + 24.0f, pos.y + 16.0f), bone, "STATUS PULSE");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(max.x - 24.0f - UI::MeasureString("sonar indicator").x, pos.y + 20.0f), quiet, "sonar indicator");

        float lx = pos.x + 30.0f;
        DrawStatus(dl, vec2(lx, pos.y + 62.0f), green, "LIVE · tracking ghost", pulse);
        DrawStatus(dl, vec2(lx, pos.y + 104.0f), amber, "SYNCING · replay buffer", pulse);
        DrawStatus(dl, vec2(lx, pos.y + 146.0f), sienna, "DEGRADED · packet loss", pulse);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · pulse = " + Text::Format("%.3f", pulse));
        UI::Text("sonar status dot · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
