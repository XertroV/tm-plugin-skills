// GENERATED COPY sha256=9fde872bb6f881cc22eba42177430dc51336986f0a4a8dc864932c4dc20adc39 source=recipes/SplitMonument.as
namespace RecipeSplitMonument {
    int clipDepth = 0;
    int lastCaptureFrame = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    int HighlightSector(int captureFrame) {
        if (captureFrame < 30) return 0;
        if (captureFrame < 60) return 1;
        if (captureFrame < 90) return 2;
        if (captureFrame < 120) return 3;
        return 0;
    }

    string SectorDelta(int sector) {
        if (sector == 0) return "−0.118";
        if (sector == 1) return "+0.036";
        if (sector == 2) return "−0.202";
        return "−0.284";
    }

    vec4 AccentForSector(int sector) {
        vec4 bottleGreen = vec4(0.25f, 0.36f, 0.32f, 1.0f);
        vec4 vermilion = vec4(0.63f, 0.31f, 0.24f, 1.0f);
        if (sector == 1) return vermilion;
        return bottleGreen;
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
        lastCaptureFrame = captureFrame;
        int highlighted = HighlightSector(captureFrame);
        float phase = Phase(captureFrame);
        vec2 pos = UI::GetCursorScreenPos();
        vec2 available = UI::GetContentRegionAvail();
        vec2 size = vec2(Math::Max(280.0f, available.x - 8.0f), 270.0f);
        vec2 max = pos + size;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 limestone = vec4(0.84f, 0.81f, 0.76f, 1.0f);
        vec4 limestoneShade = vec4(0.76f, 0.73f, 0.68f, 1.0f);
        vec4 ink = vec4(0.11f, 0.11f, 0.11f, 1.0f);
        vec4 quietInk = vec4(0.18f, 0.19f, 0.18f, 0.94f);
        vec4 green = vec4(0.25f, 0.36f, 0.32f, 1.0f);

        dl.AddRectFilledMultiColor(
            vec4(pos, size),
            limestone,
            vec4(0.88f, 0.85f, 0.80f, 1.0f),
            limestoneShade,
            vec4(0.81f, 0.78f, 0.72f, 1.0f)
        );

        float splitX = pos.x + size.x * 0.43f;
        float ruleY = pos.y + size.y * 0.71f;
        vec4 hairline = vec4(ink.x, ink.y, ink.z, 0.32f);
        dl.AddLine(vec2(pos.x + 22.0f, ruleY), vec2(max.x - 22.0f, ruleY), hairline, 1.0f);
        dl.AddLine(vec2(splitX, pos.y + 25.0f), vec2(splitX, ruleY), hairline, 1.0f);

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(104);
        string monument = "01";
        vec2 monumentSize = UI::MeasureString(monument);
        vec2 monumentPos = vec2(pos.x + 8.0f, pos.y + 42.0f);
        dl.AddText(monumentPos, ink, monument);
        UI::PopFontSize();
        UI::PopFont();

        vec4 seam = highlighted == 3 ? green : vec4(ink.x, ink.y, ink.z, 0.18f);
        dl.AddRectFilled(vec4(vec2(pos.x + 21.0f, ruleY - 3.0f), vec2(size.x * 0.33f, 3.0f)), seam, 0.0f);

        float ledgerX = splitX + 24.0f;
        float ledgerRight = max.x - 26.0f;
        float rowStartY = pos.y + 48.0f;
        string[] labels = {"SECTOR I", "SECTOR II", "SECTOR III"};
        for (int i = 0; i < 3; i++) {
            float rowY = rowStartY + float(i) * 48.0f;
            bool active = highlighted == i;
            vec4 accent = AccentForSector(i);
            vec4 labelColor = active ? ink : quietInk;
            vec4 valueColor = active ? accent : quietInk;

            if (active) {
                dl.AddRectFilled(vec4(vec2(ledgerX - 12.0f, rowY - 8.0f), vec2(3.0f, 27.0f)), accent, 0.0f);
            }

            dl.AddText(vec2(ledgerX, rowY), labelColor, labels[i]);
            string delta = SectorDelta(i);
            vec2 deltaSize = UI::MeasureString(delta);
            dl.AddText(vec2(ledgerRight - deltaSize.x, rowY), valueColor, delta);
        }

        string totalLabel = "FINAL";
        string totalDelta = SectorDelta(3);
        float totalY = ruleY + 24.0f;
        dl.AddText(vec2(ledgerX, totalY), highlighted == 3 ? ink : quietInk, totalLabel);
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(24);
        vec2 totalSize = UI::MeasureString(totalDelta);
        dl.AddText(vec2(ledgerRight - totalSize.x, totalY - 5.0f), highlighted == 3 ? green : ink, totalDelta);
        UI::PopFontSize();
        UI::PopFont();

        string badge = "NEW BEST";
        vec2 badgeText = UI::MeasureString(badge);
        vec2 badgeSize = badgeText + vec2(24.0f, 10.0f);
        vec2 badgePos = vec2(splitX - badgeSize.x * 0.5f, ruleY - badgeSize.y * 0.5f);
        vec4 badgeFill = highlighted == 3 ? green : limestone;
        vec4 badgeTextColor = highlighted == 3 ? limestone : green;
        dl.AddRectFilled(vec4(badgePos, badgeSize), badgeFill, badgeSize.y * 0.5f);
        dl.AddCircleFilled(vec2(badgePos.x + 9.0f, badgePos.y + badgeSize.y * 0.5f), 2.0f, badgeTextColor, 12);
        dl.AddText(badgePos + vec2(15.0f, 5.0f), badgeTextColor, badge);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · editorial phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned result plate · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
