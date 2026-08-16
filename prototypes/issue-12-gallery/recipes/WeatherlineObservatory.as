namespace RecipeWeatherlineObservatory {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    int GridW() { return 30; }
    int GridH() { return 16; }

    // Procedural pressure field: two drifting highs and one low; the field
    // wraps at frame 120 so every contour returns home.
    float Pressure(int gx, int gy, float phase) {
        float x = float(gx) / float(GridW() - 1);
        float y = float(gy) / float(GridH() - 1);
        float a = phase * Math::PI * 2.0f;
        float high1 = Math::Cos((x - 0.30f - 0.10f * Math::Cos(a)) * Math::PI * 2.0f) * Math::Cos((y - 0.35f) * Math::PI * 2.0f);
        float high2 = Math::Cos((x - 0.72f + 0.08f * Math::Sin(a)) * Math::PI * 2.0f + 1.3f) * Math::Cos((y - 0.62f) * Math::PI * 2.0f);
        float low = Math::Sin((x - 0.5f) * Math::PI * 2.0f + a) * Math::Sin((y - 0.5f) * Math::PI * 2.0f);
        return (high1 + high2) * 0.35f - low * 0.30f;
    }

    int ContourCount() { return 7; }

    float ContourLevel(int contour) {
        return -0.60f + float(contour) * 0.20f;
    }

    // Cell classification for marching-squares style line placement: which
    // corners of a grid cell sit above the contour level.
    int CellMask(int gx, int gy, float level, float phase) {
        int mask = 0;
        if (Pressure(gx, gy, phase) > level) mask |= 1;
        if (Pressure(gx + 1, gy, phase) > level) mask |= 2;
        if (Pressure(gx + 1, gy + 1, phase) > level) mask |= 4;
        if (Pressure(gx, gy + 1, phase) > level) mask |= 8;
        return mask;
    }

    bool CellHasContour(int gx, int gy, float level, float phase) {
        int mask = CellMask(gx, gy, level, phase);
        return mask != 0 && mask != 15;
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
        vec2 size = vec2(Math::Max(470.0f, available.x - 8.0f), 300.0f);
        vec2 max = pos + size;
        vec2 origin = pos + vec2(30.0f, 52.0f);
        vec2 field = vec2(size.x - 60.0f, size.y - 116.0f);
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 chart = vec4(0.93f, 0.92f, 0.87f, 1.0f);
        vec4 chartShade = vec4(0.88f, 0.87f, 0.82f, 1.0f);
        vec4 ink = vec4(0.16f, 0.17f, 0.16f, 1.0f);
        vec4 quiet = vec4(0.42f, 0.43f, 0.41f, 1.0f);
        vec4 isobar = vec4(0.28f, 0.42f, 0.52f, 1.0f);
        vec4 warmFront = vec4(0.75f, 0.35f, 0.28f, 1.0f);
        vec4 coldFront = vec4(0.30f, 0.45f, 0.70f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), chart, chartShade, chart, chartShade);

        // Header: station designation and observation time.
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(19);
        dl.AddText(vec2(pos.x + 26.0f, pos.y + 16.0f), ink, "WEATHERLINE OBSERVATORY");
        UI::PopFontSize();
        UI::PopFont();
        string obs = "PRESSURE FIELD " + Text::Format("%03d", captureFrame) + " / 120";
        vec2 obsSize = UI::MeasureString(obs);
        dl.AddText(vec2(max.x - 26.0f - obsSize.x, pos.y + 22.0f), quiet, obs);

        // Graticule: lat/long survey lines.
        for (int gx = 0; gx <= 6; gx++) {
            float x = origin.x + field.x * float(gx) / 6.0f;
            dl.AddLine(vec2(x, origin.y), vec2(x, origin.y + field.y), vec4(ink.x, ink.y, ink.z, 0.08f), 1.0f);
        }
        for (int gy = 0; gy <= 4; gy++) {
            float y = origin.y + field.y * float(gy) / 4.0f;
            dl.AddLine(vec2(origin.x, y), vec2(origin.x + field.x, y), vec4(ink.x, ink.y, ink.z, 0.08f), 1.0f);
        }

        // Contours: marching-squares line segments per level; the bold middle
        // level reads as the primary isobar.
        float cellW = field.x / float(GridW() - 1);
        float cellH = field.y / float(GridH() - 1);
        for (int contour = 0; contour < ContourCount(); contour++) {
            float level = ContourLevel(contour);
            bool bold = contour == ContourCount() / 2;
            vec4 lineColor = isobar;
            lineColor.w = bold ? 0.85f : 0.40f;
            float thick = bold ? 2.2f : 1.0f;
            for (int gy = 0; gy + 1 < GridH(); gy++) {
                for (int gx = 0; gx + 1 < GridW(); gx++) {
                    int mask = CellMask(gx, gy, level, phase);
                    if (mask == 0 || mask == 15) continue;
                    vec2 c00 = origin + vec2(float(gx) * cellW, float(gy) * cellH);
                    vec2 c10 = c00 + vec2(cellW, 0.0f);
                    vec2 c01 = c00 + vec2(0.0f, cellH);
                    vec2 c11 = c00 + vec2(cellW, cellH);
                    vec2 midT = (c00 + c10) * 0.5f;
                    vec2 midR = (c10 + c11) * 0.5f;
                    vec2 midB = (c01 + c11) * 0.5f;
                    vec2 midL = (c00 + c01) * 0.5f;
                    // Connect edge midpoints per the classic 16-case table.
                    if (mask == 1 || mask == 14) dl.AddLine(midL, midT, lineColor, thick);
                    else if (mask == 2 || mask == 13) dl.AddLine(midT, midR, lineColor, thick);
                    else if (mask == 3 || mask == 12) dl.AddLine(midL, midR, lineColor, thick);
                    else if (mask == 4 || mask == 11) dl.AddLine(midR, midB, lineColor, thick);
                    else if (mask == 5 || mask == 10) { dl.AddLine(midL, midT, lineColor, thick); dl.AddLine(midR, midB, lineColor, thick); }
                    else if (mask == 6 || mask == 9) dl.AddLine(midT, midB, lineColor, thick);
                    else if (mask == 7 || mask == 8) dl.AddLine(midL, midB, lineColor, thick);
                }
            }
        }

        // Fronts: two sweeping curves with alternating teeth conventions.
        for (int s = 0; s < 40; s++) {
            float t0 = float(s) / 40.0f;
            float t1 = float(s + 1) / 40.0f;
            float a = phase * Math::PI * 2.0f;
            vec2 w0 = origin + vec2(t0 * field.x, field.y * (0.30f + 0.10f * Math::Sin(t0 * Math::PI * 2.0f + a)));
            vec2 w1 = origin + vec2(t1 * field.x, field.y * (0.30f + 0.10f * Math::Sin(t1 * Math::PI * 2.0f + a)));
            dl.AddLine(w0, w1, vec4(warmFront.x, warmFront.y, warmFront.z, 0.8f), 2.0f);
            if (s % 4 == 0) {
                dl.AddCircleFilled(w0, 3.5f, warmFront, 12);
            }
            vec2 c0 = origin + vec2(t0 * field.x, field.y * (0.72f + 0.08f * Math::Cos(t0 * Math::PI * 2.0f - a)));
            vec2 c1 = origin + vec2(t1 * field.x, field.y * (0.72f + 0.08f * Math::Cos(t1 * Math::PI * 2.0f - a)));
            dl.AddLine(c0, c1, vec4(coldFront.x, coldFront.y, coldFront.z, 0.8f), 2.0f);
            if (s % 4 == 2) {
                vec2 dir = c1 - c0;
                float len = dir.Length();
                if (len > 0.5f) {
                    vec2 norm = vec2(-dir.y, dir.x) / len;
                    dl.AddQuadFilled(c0, c0 + dir * 0.5f + norm * 5.0f, c0 + dir * 0.5f, coldFront);
                }
            }
        }

        // Station model: a small instrument readout in the corner.
        vec2 station = origin + vec2(field.x - 54.0f, 14.0f);
        dl.AddCircleFilled(station, 4.0f, vec4(ink.x, ink.y, ink.z, 0.8f), 16);
        dl.AddLine(station, station + vec2(0.0f, -14.0f), ink, 1.5f);
        dl.AddLine(station + vec2(0.0f, -14.0f), station + vec2(8.0f, -18.0f), ink, 1.5f);
        dl.AddText(station + vec2(10.0f, -8.0f), quiet, "1013 hPa");

        // Legend strip.
        string legend = "bold = primary isobar · red discs = warm front · blue teeth = cold front";
        vec2 legendSize = UI::MeasureString(legend);
        dl.AddText(vec2((pos.x + max.x) * 0.5f - legendSize.x * 0.5f, max.y - 26.0f), vec4(ink.x, ink.y, ink.z, 0.6f), legend);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · field phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned contour field · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
