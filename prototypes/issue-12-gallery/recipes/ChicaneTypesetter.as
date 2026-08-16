namespace RecipeChicaneTypesetter {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    string TrackText() { return "CHICANE"; }

    // The racing line: a closed S-curve the type physically rides. Position
    // along the line is parameterized by t in [0,1); the loop closes at 120.
    vec2 LinePoint(float t) {
        float a = t * Math::PI * 2.0f;
        float x = a / (Math::PI * 2.0f); // 0..1 sweep
        float y = 0.5f + 0.26f * Math::Sin(a * 1.5f) + 0.06f * Math::Sin(a * 4.0f + 1.2f);
        return vec2(x, y);
    }

    vec2 LineTangent(float t) {
        float dt = 0.004f;
        vec2 before = LinePoint(t - dt < 0.0f ? t - dt + 1.0f : t - dt);
        vec2 after = LinePoint((t + dt) - Math::Floor(t + dt));
        vec2 d = after - before;
        float len = d.Length();
        if (len < 0.0001f) return vec2(1.0f, 0.0f);
        return d / len;
    }

    // Where the text mass sits on the line as the story advances; the wordmark
    // surfs the chicane and returns home.
    float TextAnchor(float phase) {
        return phase - Math::Floor(phase);
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
        vec2 size = vec2(Math::Max(440.0f, available.x - 16.0f), 290.0f);
        vec2 max = pos + size;
        vec2 origin = pos + vec2(30.0f, 56.0f);
        vec2 field = vec2(size.x - 60.0f, size.y - 126.0f);
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 asphalt = vec4(0.070f, 0.072f, 0.075f, 1.0f);
        vec4 asphaltLift = vec4(0.095f, 0.098f, 0.100f, 1.0f);
        vec4 curbRed = vec4(0.72f, 0.26f, 0.22f, 1.0f);
        vec4 curbWhite = vec4(0.88f, 0.88f, 0.85f, 1.0f);
        vec4 linePaint = vec4(0.92f, 0.90f, 0.80f, 1.0f);
        vec4 typeInk = vec4(0.94f, 0.93f, 0.88f, 1.0f);
        vec4 typeGlow = vec4(0.45f, 0.75f, 0.85f, 1.0f);
        vec4 quiet = vec4(0.48f, 0.50f, 0.50f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), asphalt, asphaltLift, asphalt, asphaltLift);

        // Header strip.
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(19);
        dl.AddText(vec2(pos.x + 26.0f, pos.y + 16.0f), typeInk, "CHICANE TYPESETTER");
        UI::PopFontSize();
        UI::PopFont();
        string sector = "SECTOR · T7–T9";
        vec2 sectorSize = UI::MeasureString(sector);
        dl.AddText(vec2(max.x - 26.0f - sectorSize.x, pos.y + 22.0f), quiet, sector);

        // Kerbs: alternating red/white blocks flanking the racing line.
        for (int s = 0; s < 64; s++) {
            float t0 = float(s) / 64.0f;
            float t1 = float(s + 1) / 64.0f;
            vec2 p0 = origin + LinePoint(t0) * field;
            vec2 p1 = origin + LinePoint(t1) * field;
            vec2 tan0 = LineTangent(t0);
            vec2 norm0 = vec2(-tan0.y, tan0.x);
            bool red = (s % 2) == 0;
            vec4 curb = red ? curbRed : curbWhite;
            curb.w = 0.55f;
            for (int side = -1; side <= 1; side += 2) {
                vec2 off = norm0 * float(side) * 26.0f;
                dl.AddLine(p0 + off, p1 + off, curb, 7.0f);
            }
        }

        // The racing line itself: dashed paint down the center.
        for (int s = 0; s < 48; s++) {
            if (s % 2 == 1) continue;
            float t0 = float(s) / 48.0f;
            float t1 = float(s + 1) / 48.0f;
            vec2 p0 = origin + LinePoint(t0) * field;
            vec2 p1 = origin + LinePoint(t1) * field;
            dl.AddLine(p0, p1, vec4(linePaint.x, linePaint.y, linePaint.z, 0.65f), 2.0f);
        }

        // The wordmark: each glyph is placed on the line at its own arc
        // offset and rotated to the local tangent — type as a vehicle.
        string word = TrackText();
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(30);
        float anchor = TextAnchor(phase);
        float glyphSpacing = 0.052f;
        for (int i = 0; i < word.Length; i++) {
            float t = anchor + float(i) * glyphSpacing;
            t = t - Math::Floor(t);
            vec2 at = origin + LinePoint(t) * field;
            vec2 tan = LineTangent(t);
            string glyph = word.SubStr(i, 1);
            // Slip glow behind the glyph, brighter on the racing apex.
            float apex = Math::Abs(Math::Sin(t * Math::PI * 2.0f * 1.5f));
            vec4 glow = typeGlow;
            glow.w = 0.10f + apex * 0.20f;
            dl.AddText(at + vec2(-1.5f, -14.0f), glow, glyph);
            vec4 ink = typeInk;
            ink.w = 0.75f + apex * 0.25f;
            dl.AddText(at + vec2(0.0f, -12.0f), ink, glyph);
            // Direction tick under each glyph follows the tangent.
            dl.AddLine(at + vec2(0.0f, 8.0f), at + vec2(0.0f, 8.0f) + tan * 9.0f, vec4(typeGlow.x, typeGlow.y, typeGlow.z, 0.5f), 1.5f);
        }
        UI::PopFontSize();
        UI::PopFont();

        // Apex markers: the tightest points earn a measured flag.
        for (int apex = 0; apex < 3; apex++) {
            float t = float(apex) / 3.0f + 0.17f;
            t = t - Math::Floor(t);
            vec2 at = origin + LinePoint(t) * field;
            dl.AddLine(at + vec2(-8.0f, 22.0f), at + vec2(8.0f, 22.0f), vec4(curbWhite.x, curbWhite.y, curbWhite.z, 0.5f), 1.5f);
            dl.AddCircleFilled(at + vec2(0.0f, 22.0f), 2.5f, vec4(curbRed.x, curbRed.y, curbRed.z, 0.8f), 12);
            dl.AddText(at + vec2(-9.0f, 28.0f), quiet, "APEX");
        }

        // Legend strip.
        string legend = "glyphs ride the racing line · tangent ticks show travel · apex flags mark the tightest kerbs";
        vec2 legendSize = UI::MeasureString(legend);
        dl.AddText(vec2((pos.x + max.x) * 0.5f - legendSize.x * 0.5f, max.y - 24.0f), vec4(typeInk.x, typeInk.y, typeInk.z, 0.5f), legend);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · line phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned typeset line · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
