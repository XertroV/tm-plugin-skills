// GENERATED COPY sha256=c103955659194f6a007b15bad3d15bd7e216129010aa9e3e51bcc0bd19339509 source=recipes/TypewriterText.as
namespace RecipeTypewriterText {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    // How many glyphs are revealed at this frame. The string fills over the
    // first 70% of the loop, holds, then snaps back to empty at the wrap.
    int RevealedGlyphs(int total, int captureFrame) {
        float phase = Phase(captureFrame);
        if (phase >= 0.7f) return total;
        float f = phase / 0.7f;
        return int(Math::Floor(f * float(total)));
    }

    // Caret alpha: a hard blink at ~2Hz, independent of the reveal.
    float CaretAlpha(int captureFrame) {
        return (captureFrame / 15) % 2 == 0 ? 1.0f : 0.0f;
    }

    void PushClip(UI::DrawList@ dl, vec2 min, vec2 max) {
        dl.PushClipRect(vec4(min, max - min));
        clipDepth++;
    }

    void PopClip(UI::DrawList@ dl) {
        dl.PopClipRect();
        clipDepth--;
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
        vec4 green = vec4(0.45f, 0.85f, 0.55f, 1.0f);
        vec4 amber = vec4(0.95f, 0.65f, 0.15f, 1.0f);

        dl.AddRectFilled(vec4(pos, size), slate, 0.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(18);
        dl.AddText(vec2(pos.x + 24.0f, pos.y + 16.0f), bone, "TYPEWRITER TEXT");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(max.x - 24.0f - UI::MeasureString("reveal + caret").x, pos.y + 20.0f), quiet, "reveal + caret");

        string line1 = "Loading replay buffer ...";
        string line2 = "Resolving ghost delta ...";
        int r1 = RevealedGlyphs(int(line1.Length), captureFrame);
        int r2 = RevealedGlyphs(int(line2.Length), captureFrame);
        string shown1 = line1.SubStr(0, uint(r1));
        string shown2 = line2.SubStr(0, uint(r2));

        float caret = CaretAlpha(captureFrame);
        vec4 caretCol = vec4(green.x, green.y, green.z, caret);

        dl.AddText(vec2(pos.x + 30.0f, pos.y + 66.0f), green, shown1);
        vec2 s1 = UI::MeasureString(shown1);
        dl.AddRectFilled(vec4(pos.x + 30.0f + s1.x + 3.0f, pos.y + 66.0f, 9.0f, s1.y), caretCol, 0.0f);

        dl.AddText(vec2(pos.x + 30.0f, pos.y + 112.0f), amber, shown2);
        vec2 s2 = UI::MeasureString(shown2);
        dl.AddRectFilled(vec4(pos.x + 30.0f + s2.x + 3.0f, pos.y + 112.0f, 9.0f, s2.y), caretCol, 0.0f);

        dl.AddText(vec2(pos.x + 24.0f, max.y - 24.0f), quiet, "glyphs reveal over 70% of the loop · 2Hz block caret");

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · revealed = " + r1);
        UI::Text("typewriter reveal + blinking caret · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
