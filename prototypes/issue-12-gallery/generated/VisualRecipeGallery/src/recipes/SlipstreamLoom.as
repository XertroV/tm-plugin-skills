// GENERATED COPY sha256=2d8ed1015bbd649f22d54bffeaee488765f53672bcb2f443af205d4e50d5a98f source=recipes/SlipstreamLoom.as
namespace RecipeSlipstreamLoom {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    int RibbonCount() { return 4; }

    int RibbonSegments() { return 44; }

    // Each ribbon is a deterministic sine braid strand; phase slides the whole
    // weave so the over/under crossings travel, and the loop closes at 120.
    float RibbonY(int ribbon, float t, float phase) {
        float a = t * Math::PI * 2.0f;
        float slide = phase * Math::PI * 2.0f;
        return 0.5f
            + 0.20f * Math::Sin(a * 2.0f + float(ribbon) * Math::PI * 0.5f + slide)
            + 0.05f * Math::Sin(a * 5.0f - float(ribbon) * 1.1f);
    }

    // Weave order at parameter t: which ribbon is on top at a crossing is
    // decided by relative y (lower y draws later = on top), so the loom is
    // physically consistent rather than faked per-segment.
    int RibbonOrder(int ribbon, float t, float phase) {
        int order = 0;
        float own = RibbonY(ribbon, t, phase);
        for (int other = 0; other < RibbonCount(); other++) {
            if (other != ribbon && RibbonY(other, t, phase) < own) order++;
        }
        return order;
    }

    vec4 RibbonColor(int ribbon) {
        if (ribbon == 0) return vec4(0.88f, 0.42f, 0.30f, 1.0f); // signal orange
        if (ribbon == 1) return vec4(0.35f, 0.62f, 0.78f, 1.0f); // aero blue
        if (ribbon == 2) return vec4(0.55f, 0.72f, 0.42f, 1.0f); // grass
        return vec4(0.78f, 0.68f, 0.88f, 1.0f);                  // haze violet
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
        float phase = Phase(captureFrame);
        vec2 pos = UI::GetCursorScreenPos();
        vec2 available = UI::GetContentRegionAvail();
        vec2 size = vec2(Math::Max(440.0f, available.x - 16.0f), 300.0f);
        vec2 max = pos + size;
        vec2 origin = pos + vec2(28.0f, 54.0f);
        vec2 field = vec2(size.x - 56.0f, size.y - 118.0f);
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 dusk = vec4(0.055f, 0.050f, 0.075f, 1.0f);
        vec4 duskLift = vec4(0.075f, 0.070f, 0.100f, 1.0f);
        vec4 thread = vec4(0.82f, 0.80f, 0.88f, 1.0f);
        vec4 quiet = vec4(0.46f, 0.45f, 0.55f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), dusk, duskLift, dusk, duskLift);

        // Header strip.
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(19);
        dl.AddText(vec2(pos.x + 26.0f, pos.y + 16.0f), thread, "SLIPSTREAM LOOM");
        UI::PopFontSize();
        UI::PopFont();
        string weave = "DRAFT " + Text::Format("%03d", captureFrame) + "/120";
        vec2 weaveSize = UI::MeasureString(weave);
        dl.AddText(vec2(max.x - 26.0f - weaveSize.x, pos.y + 22.0f), quiet, weave);

        // Warp threads: faint vertical guides the ribbons weave through.
        for (int warp = 0; warp <= 10; warp++) {
            float x = origin.x + field.x * float(warp) / 10.0f;
            dl.AddLine(vec2(x, origin.y), vec2(x, origin.y + field.y), vec4(thread.x, thread.y, thread.z, 0.06f), 1.0f);
        }

        // Draw ribbons back-to-front per segment so crossings read as a real
        // weave: for each segment slot, the ribbon lowest in the order (front)
        // is drawn last, sitting on top of the ones behind it.
        for (int s = 0; s < RibbonSegments(); s++) {
            float t0 = float(s) / float(RibbonSegments());
            float t1 = float(s + 1) / float(RibbonSegments());
            float tMid = (t0 + t1) * 0.5f;
            // Sort ribbons by weave order at this segment (insertion, N=4).
            int order0 = 0, order1 = 1, order2 = 2, order3 = 3;
            int[] ribbons = {0, 1, 2, 3};
            for (int a = 0; a < RibbonCount(); a++) {
                for (int b = a + 1; b < RibbonCount(); b++) {
                    if (RibbonOrder(ribbons[b], tMid, phase) < RibbonOrder(ribbons[a], tMid, phase)) {
                        int tmp = ribbons[a];
                        ribbons[a] = ribbons[b];
                        ribbons[b] = tmp;
                    }
                }
            }
            for (int slot = 0; slot < RibbonCount(); slot++) {
                int ribbon = ribbons[slot];
                vec2 p0 = origin + vec2(t0 * field.x, RibbonY(ribbon, t0, phase) * field.y);
                vec2 p1 = origin + vec2(t1 * field.x, RibbonY(ribbon, t1, phase) * field.y);
                vec4 color = RibbonColor(ribbon);
                // Under-shadow, then body, then a bright spine: three strokes
                // per segment give the ribbon physical width.
                dl.AddLine(p0 + vec2(2.0f, 3.0f), p1 + vec2(2.0f, 3.0f), vec4(0.0f, 0.0f, 0.0f, 0.35f), 9.0f);
                dl.AddLine(p0, p1, vec4(color.x, color.y, color.z, 0.90f), 8.0f);
                dl.AddLine(p0, p1, vec4(Math::Min(1.0f, color.x + 0.25f), Math::Min(1.0f, color.y + 0.25f), Math::Min(1.0f, color.z + 0.25f), 0.55f), 2.0f);
            }
            // Crossing marker: when the front ribbon changes between segments,
            // drop a small knot so the weave reads as interlaced.
            if (s > 0) {
                float tPrev = (float(s) - 0.5f) / float(RibbonSegments());
                int frontNow = ribbons[RibbonCount() - 1];
                int bestPrev = 0;
                int bestOrder = -1;
                for (int r = 0; r < RibbonCount(); r++) {
                    int o = RibbonOrder(r, tPrev, phase);
                    if (o > bestOrder) { bestOrder = o; bestPrev = r; }
                }
                if (frontNow != bestPrev) {
                    vec2 knot = origin + vec2(t0 * field.x, RibbonY(frontNow, t0, phase) * field.y);
                    dl.AddCircleFilled(knot, 3.0f, vec4(thread.x, thread.y, thread.z, 0.7f), 12);
                }
            }
        }

        // Legend strip: ribbon key.
        float keyX = (pos.x + max.x) * 0.5f - 150.0f;
        float keyY = max.y - 28.0f;
        for (int ribbon = 0; ribbon < RibbonCount(); ribbon++) {
            vec4 color = RibbonColor(ribbon);
            dl.AddCircleFilled(vec2(keyX + float(ribbon) * 100.0f, keyY + 5.0f), 4.0f, color, 14);
            string label = ribbon == 0 ? "lead" : (ribbon == 1 ? "chase" : (ribbon == 2 ? "draft" : "wake"));
            dl.AddText(vec2(keyX + float(ribbon) * 100.0f + 9.0f, keyY), vec4(thread.x, thread.y, thread.z, 0.65f), label);
        }

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · weave phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned ribbon weave · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
