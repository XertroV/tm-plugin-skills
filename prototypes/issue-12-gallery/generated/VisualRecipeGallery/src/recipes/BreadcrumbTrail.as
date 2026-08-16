// GENERATED COPY sha256=d85ff40884b54b61845973096d24a6cf95f0c1e98fe95122d69fed80c4981065 source=recipes/BreadcrumbTrail.as
namespace RecipeBreadcrumbTrail {
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

    // tm-agent breadcrumb: left / separator / right measured and centered as a
    // unit, with the left dim, the separator mid, and the active segment bright.
    // The active segment advances with the loop.
    void DrawBreadcrumb(UI::DrawList@ dl, vec2 centerTop, string[]@ segs, int active, vec4 dimCol, vec4 sepCol, vec4 brightCol) {
        float gap = 8.0f;
        float totalW = 0.0f;
        for (uint i = 0; i < segs.Length; i++) totalW += UI::MeasureString(segs[i]).x;
        totalW += UI::MeasureString("›").x * float(segs.Length - 1) + gap * 2.0f * float(segs.Length - 1);

        float x = centerTop.x - totalW * 0.5f;
        for (uint i = 0; i < segs.Length; i++) {
            vec4 col = int(i) == active ? brightCol : dimCol;
            dl.AddText(vec2(x, centerTop.y), col, segs[i]);
            x += UI::MeasureString(segs[i]).x;
            if (i + 1 < segs.Length) {
                dl.AddText(vec2(x + gap, centerTop.y), sepCol, "›");
                x += gap * 2.0f + UI::MeasureString("›").x;
            }
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
        vec4 dim = vec4(0.48f, 0.52f, 0.58f, 1.0f);
        vec4 sepCol = vec4(0.55f, 0.58f, 0.64f, 1.0f);
        vec4 bright = vec4(0.95f, 0.65f, 0.15f, 1.0f);
        vec4 bright2 = vec4(0.30f, 0.75f, 0.85f, 1.0f);

        dl.AddRectFilled(vec4(pos, size), slate, 0.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(18);
        dl.AddText(vec2(pos.x + 24.0f, pos.y + 16.0f), bone, "BREADCRUMB TRAIL");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(max.x - 24.0f - UI::MeasureString("centered segments").x, pos.y + 20.0f), quiet, "centered segments");

        float cx = pos.x + size.x * 0.5f;
        int active = int(phase * 3.0f) % 3;
        string[] path = {"replay", "sector 2", "split"};
        DrawBreadcrumb(dl, vec2(cx, pos.y + 70.0f), path, active, dim, sepCol, bright);

        string[] deep = {"library", "ghosts", "2026", "week 33"};
        DrawBreadcrumb(dl, vec2(cx, pos.y + 118.0f), deep, int(phase * 4.0f) % 4, dim, sepCol, bright2);

        dl.AddText(vec2(pos.x + 24.0f, max.y - 24.0f), quiet, "measured + centered as a unit · active segment advances");

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · active = " + active);
        UI::Text("tm-agent breadcrumb · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
