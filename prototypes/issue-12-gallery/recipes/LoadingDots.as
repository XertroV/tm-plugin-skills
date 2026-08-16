namespace RecipeLoadingDots {
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

    // N dots bounce in sequence: each dot's lift is a raised-cosine bump
    // centered on its own phase offset, so the row reads as a travelling wave.
    float DotLift(int index, int count, int captureFrame) {
        float phase = Phase(captureFrame);
        float offset = float(index) / float(count);
        float d = Math::Abs(phase - offset);
        d = Math::Min(d, 1.0f - d);  // wrap-around distance on the loop
        return Math::Max(0.0f, 1.0f - d * float(count) * 0.5f);
    }

    void DrawDots(UI::DrawList@ dl, vec2 baseline, int count, float spacing, vec4 color, int captureFrame) {
        for (int i = 0; i < count; i++) {
            float lift = DotLift(i, count, captureFrame);
            float y = baseline.y - lift * 8.0f;
            float a = 0.35f + 0.65f * lift;
            dl.AddCircleFilled(vec2(baseline.x + float(i) * spacing, y), 3.5f, vec4(color.x, color.y, color.z, a), 14);
        }
    }

    void DrawPanel(int captureFrame) {
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
        vec4 cyan = vec4(0.30f, 0.75f, 0.85f, 1.0f);
        vec4 violet = vec4(0.70f, 0.55f, 0.90f, 1.0f);

        dl.AddRectFilled(vec4(pos, size), slate, 0.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(18);
        dl.AddText(vec2(pos.x + 24.0f, pos.y + 16.0f), bone, "LOADING DOTS");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(max.x - 24.0f - UI::MeasureString("wave indicator").x, pos.y + 20.0f), quiet, "wave indicator");

        float cx = pos.x + size.x * 0.5f;
        DrawDots(dl, vec2(cx - 4.0f * 16.0f, pos.y + 84.0f), 9, 16.0f, cyan, captureFrame);
        dl.AddText(vec2(pos.x + 30.0f, pos.y + 104.0f), quiet, "thinking ...");

        DrawDots(dl, vec2(cx - 6.0f * 14.0f, pos.y + 152.0f), 13, 14.0f, violet, captureFrame);
        dl.AddText(vec2(pos.x + 30.0f, pos.y + 168.0f), quiet, "streaming ...");

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · phase = " + Text::Format("%.3f", Phase(captureFrame)));
        UI::Text("wave loading dots · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
