namespace RecipeSpectralRelayTypography {
    int clipDepth = 0;
    int lastCaptureFrame = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    float PingPong(float t) {
        t = t - Math::Floor(t);
        return 1.0f - Math::Abs(t * 2.0f - 1.0f);
    }

    float SignalWeight(float index, float center, float halfWidth) {
        float distance = Math::Abs(index - center);
        if (distance >= halfWidth) return 0.0f;
        float normalized = 1.0f - distance / halfWidth;
        return 0.5f - 0.5f * Math::Cos(normalized * Math::PI);
    }

    vec4 RelayColor(float t) {
        t = t - Math::Floor(t);
        vec4 electricBlue = vec4(0.16f, 0.68f, 1.00f, 1.0f);
        vec4 ultraviolet = vec4(0.68f, 0.30f, 1.00f, 1.0f);
        vec4 signalRed = vec4(1.00f, 0.20f, 0.34f, 1.0f);
        if (t < 0.5f) return Math::Lerp(electricBlue, ultraviolet, t * 2.0f);
        return Math::Lerp(ultraviolet, signalRed, (t - 0.5f) * 2.0f);
    }

    void PushClip(UI::DrawList@ dl, vec2 min, vec2 max) {
        dl.PushClipRect(vec4(min, max - min));
        clipDepth++;
    }

    void PopClip(UI::DrawList@ dl) {
        dl.PopClipRect();
        clipDepth--;
    }

    void DrawSignalNode(UI::DrawList@ dl, vec2 at, vec4 color, float strength) {
        vec4 haze = color;
        haze.w = 0.05f + strength * 0.12f;
        dl.AddCircleFilled(at, 13.0f + strength * 5.0f, haze, 28);
        color.w = 0.42f + strength * 0.48f;
        dl.AddCircleFilled(at, 3.0f + strength * 2.0f, color, 20);
    }

    void DrawPanel(int captureFrame) {
        lastCaptureFrame = captureFrame;
        float phase = Phase(captureFrame);
        vec2 pos = UI::GetCursorScreenPos();
        vec2 available = UI::GetContentRegionAvail();
        vec2 size = vec2(Math::Max(280.0f, available.x - 16.0f), 270.0f);
        vec2 max = pos + size;
        vec2 center = pos + size * 0.5f;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        dl.AddRectFilledMultiColor(
            vec4(pos, size),
            vec4(0.008f, 0.014f, 0.040f, 1.0f),
            vec4(0.030f, 0.010f, 0.050f, 1.0f),
            vec4(0.006f, 0.012f, 0.030f, 1.0f),
            vec4(0.002f, 0.006f, 0.020f, 1.0f)
        );

        for (int lane = -2; lane <= 2; lane++) {
            float y = center.y + float(lane) * 35.0f;
            vec4 laneColor = RelayColor(phase + float(lane + 2) * 0.10f);
            laneColor.w = lane == 0 ? 0.18f : 0.07f;
            dl.AddLine(vec2(pos.x + 22.0f, y), vec2(max.x - 22.0f, y), laneColor, lane == 0 ? 2.0f : 1.0f);
            for (int marker = 0; marker < 13; marker++) {
                float x = pos.x + 28.0f + float(marker) / 12.0f * (size.x - 56.0f);
                vec4 mark = laneColor;
                mark.w *= marker % 3 == 0 ? 1.8f : 0.7f;
                dl.AddLine(vec2(x, y - 3.0f), vec2(x, y + 3.0f), mark, 1.0f);
            }
        }

        vec2 titleBandMin = vec2(pos.x + 20.0f, center.y - 34.0f);
        vec2 titleBandSize = vec2(size.x - 40.0f, 68.0f);
        dl.AddRectFilledMultiColor(
            vec4(titleBandMin, titleBandSize),
            vec4(0.004f, 0.008f, 0.024f, 0.94f),
            vec4(0.012f, 0.005f, 0.030f, 0.94f),
            vec4(0.012f, 0.005f, 0.030f, 0.94f),
            vec4(0.004f, 0.008f, 0.024f, 0.94f)
        );

        string label = "CHECKPOINT RELAY";
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(22);
        vec2 measured = UI::MeasureString(label);
        float startX = center.x - measured.x * 0.5f;
        float textY = center.y - measured.y * 0.5f;
        float leftCenter = -3.0f + phase * float(label.Length + 6);
        float rightCenter = float(label.Length + 2) - phase * float(label.Length + 6);
        float cursorX = startX;
        float collision = 0.0f;

        for (int i = 0; i < label.Length; i++) {
            string ch = label.SubStr(i, 1);
            vec2 chSize = UI::MeasureString(ch);
            float leftWeight = SignalWeight(float(i), leftCenter, 4.5f);
            float rightWeight = SignalWeight(float(i), rightCenter, 4.5f);
            float strength = Math::Clamp(leftWeight + rightWeight, 0.0f, 1.0f);
            collision = Math::Max(collision, Math::Min(leftWeight, rightWeight));
            vec4 base = vec4(0.48f, 0.53f, 0.66f, 1.0f);
            vec4 leftColor = RelayColor(phase + float(i) * 0.015f);
            vec4 rightColor = RelayColor(phase + 0.58f - float(i) * 0.012f);
            vec4 lit = Math::Lerp(leftColor, rightColor, rightWeight / Math::Max(0.001f, leftWeight + rightWeight));
            vec4 color = Math::Lerp(base, lit, strength * 0.70f);
            vec2 at = vec2(cursorX, textY);

            if (strength > 0.12f) {
                vec4 glow = lit;
                glow.w = 0.04f + strength * 0.11f;
                float echoOffset = 1.0f + strength * 0.8f;
                dl.AddText(at + vec2(-echoOffset, 0.0f), glow, ch);
                dl.AddText(at + vec2(echoOffset, 0.0f), glow, ch);
            }
            vec4 readable = Math::Lerp(color, vec4(0.92f, 0.95f, 1.0f, 1.0f), 0.22f);
            dl.AddText(at, readable, ch);
            cursorX += chSize.x;
        }
        UI::PopFontSize();
        UI::PopFont();

        float leftX = startX + Math::Clamp(leftCenter, 0.0f, float(label.Length - 1)) / float(label.Length - 1) * measured.x;
        float rightX = startX + Math::Clamp(rightCenter, 0.0f, float(label.Length - 1)) / float(label.Length - 1) * measured.x;
        float safeLeftX = Math::Clamp(leftX, pos.x + 42.0f, max.x - 42.0f);
        float safeRightX = Math::Clamp(rightX, pos.x + 42.0f, max.x - 42.0f);
        DrawSignalNode(dl, vec2(safeLeftX, center.y - 54.0f), RelayColor(phase), SignalWeight(leftCenter, rightCenter, 7.0f));
        DrawSignalNode(dl, vec2(safeRightX, center.y + 54.0f), RelayColor(phase + 0.58f), SignalWeight(rightCenter, leftCenter, 7.0f));

        float meetingX = (safeLeftX + safeRightX) * 0.5f;
        vec4 bloom = RelayColor(phase + 0.27f);
        for (int ring = 6; ring >= 1; ring--) {
            float f = float(ring) / 6.0f;
            vec4 ringColor = bloom;
            ringColor.w = collision * (1.0f - f) * 0.13f;
            dl.AddCircleFilled(vec2(meetingX, center.y), 12.0f + f * 42.0f, ringColor, 36);
        }

        vec4 tracer = RelayColor(phase + 0.14f);
        tracer.w = 0.34f;
        dl.AddLine(vec2(safeLeftX, center.y - 54.0f), vec2(meetingX, center.y), tracer, 1.5f);
        tracer = RelayColor(phase + 0.70f);
        tracer.w = 0.34f;
        dl.AddLine(vec2(safeRightX, center.y + 54.0f), vec2(meetingX, center.y), tracer, 1.5f);

        string phaseLabel = "COUNTER-PHASE  " + Text::Format("%03d", captureFrame) + " / 120";
        vec2 phaseSize = UI::MeasureString(phaseLabel);
        dl.AddText(vec2(center.x - phaseSize.x * 0.5f, max.y - 28.0f), vec4(0.58f, 0.66f, 0.80f, 0.94f), phaseLabel);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned spectral relay · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
