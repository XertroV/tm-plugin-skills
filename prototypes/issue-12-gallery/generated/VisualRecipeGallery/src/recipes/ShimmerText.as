// GENERATED COPY sha256=b69c9ba8a9f5fe8d38d2de30857ecbaf740b3b84950aabac4ab48ec9e103aa6e source=recipes/ShimmerText.as
namespace RecipeShimmerText {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    // Shimmer: a bright band sweeps across the text left→right. Glyphs near the
    // band center lift toward a hot color; others sit at the base tone. The
    // band loops, so frame 0 and 120 both place it at the leading edge.
    float BandCenter(int captureFrame) {
        // -0.2 .. 1.2 so the band fully enters and exits the text.
        return -0.2f + Phase(captureFrame) * 1.4f;
    }

    vec4 ShimmerColor(int glyph, int glyphCount, int captureFrame, vec4 base, vec4 hot) {
        float band = BandCenter(captureFrame);
        float t = glyphCount <= 1 ? 0.5f : float(glyph) / float(glyphCount - 1);
        float d = Math::Abs(t - band);
        float lift = Math::Max(0.0f, 1.0f - d * 6.0f);
        return vec4(
            base.x + (hot.x - base.x) * lift,
            base.y + (hot.y - base.y) * lift,
            base.z + (hot.z - base.z) * lift,
            base.w
        );
    }

    void PushClip(UI::DrawList@ dl, vec2 min, vec2 max) {
        dl.PushClipRect(vec4(min, max - min));
        clipDepth++;
    }

    void PopClip(UI::DrawList@ dl) {
        dl.PopClipRect();
        clipDepth--;
    }

    // Draw a string glyph-by-glyph, coloring each with the shimmer band.
    void DrawShimmer(UI::DrawList@ dl, vec2 at, const string &in text, int captureFrame, vec4 base, vec4 hot) {
        int n = int(text.Length);
        float x = at.x;
        for (int i = 0; i < n; i++) {
            string glyph = text.SubStr(uint(i), 1);
            vec4 col = ShimmerColor(i, n, captureFrame, base, hot);
            dl.AddText(vec2(x, at.y), col, glyph);
            x += UI::MeasureString(glyph).x;
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
        vec4 dim = vec4(0.42f, 0.44f, 0.48f, 1.0f);
        vec4 hot = vec4(0.98f, 0.86f, 0.55f, 1.0f);

        dl.AddRectFilled(vec4(pos, size), slate, 0.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(18);
        dl.AddText(vec2(pos.x + 24.0f, pos.y + 16.0f), bone, "SHIMMER TEXT");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(max.x - 24.0f - UI::MeasureString("sweep highlight").x, pos.y + 20.0f), quiet, "sweep highlight");

        UI::PushFontSize(22);
        DrawShimmer(dl, vec2(pos.x + 30.0f, pos.y + 66.0f), "SYNCHRONIZING GHOST DELTA", captureFrame, dim, hot);
        UI::PopFontSize();

        UI::PushFontSize(16);
        DrawShimmer(dl, vec2(pos.x + 30.0f, pos.y + 116.0f), "a bright band travels across the text", captureFrame, dim, vec4(0.55f, 0.85f, 0.95f, 1.0f));
        UI::PopFontSize();

        DrawShimmer(dl, vec2(pos.x + 30.0f, pos.y + 156.0f), "glyphs lift near the band center", captureFrame, dim, vec4(0.80f, 0.70f, 0.98f, 1.0f));

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · band = " + Text::Format("%.3f", BandCenter(captureFrame)));
        UI::Text("per-glyph shimmer sweep · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
