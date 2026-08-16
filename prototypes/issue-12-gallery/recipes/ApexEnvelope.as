namespace RecipeApexEnvelope {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    float MarkerPosition(int captureFrame) {
        float phase = Phase(captureFrame);
        if (phase <= 0.75f) return phase / 0.75f * 0.88f;
        return (1.0f - phase) / 0.25f * 0.88f;
    }

    float SafeHalfWidth(int captureFrame) {
        float phase = Phase(captureFrame);
        float pressure = phase <= 0.75f ? phase / 0.75f : (1.0f - phase) / 0.25f;
        return 0.72f - pressure * 0.18f;
    }

    float Margin(int captureFrame) {
        return SafeHalfWidth(captureFrame) - Math::Abs(MarkerPosition(captureFrame));
    }

    bool IsOverslip(int captureFrame) {
        return Margin(captureFrame) < 0.0f;
    }

    void PushClip(UI::DrawList@ dl, vec2 min, vec2 max) {
        dl.PushClipRect(vec4(min, max - min));
        clipDepth++;
    }

    void PopClip(UI::DrawList@ dl) {
        dl.PopClipRect();
        clipDepth--;
    }

    string SignedPercent(float value) {
        return Text::Format(value >= 0.0f ? "+%.0f%%" : "%.0f%%", value * 100.0f);
    }

    void DrawReadout(UI::DrawList@ dl, vec2 pos, float width, const string &in label, const string &in value, vec4 labelColor, vec4 valueColor) {
        dl.AddText(pos, labelColor, label);
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(20);
        vec2 measured = UI::MeasureString(value);
        dl.AddText(vec2(pos.x + width - measured.x, pos.y + 21.0f), valueColor, value);
        UI::PopFontSize();
        UI::PopFont();
    }

    void DrawPanel(int captureFrame) {
        float phase = Phase(captureFrame);
        float marker = MarkerPosition(captureFrame);
        float safe = SafeHalfWidth(captureFrame);
        float margin = Margin(captureFrame);
        bool overslip = IsOverslip(captureFrame);

        vec2 pos = UI::GetCursorScreenPos();
        vec2 available = UI::GetContentRegionAvail();
        // The calibrated composition intentionally uses a wide layout. The gallery
        // enforces a matching minimum; 450 also keeps independent embeds honest.
        vec2 size = vec2(Math::Max(430.0f, available.x - 16.0f), 300.0f);
        vec2 max = pos + size;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 carbon = vec4(0.067f, 0.078f, 0.086f, 1.0f);
        vec4 carbonLift = vec4(0.092f, 0.108f, 0.116f, 1.0f);
        vec4 ivory = vec4(0.914f, 0.886f, 0.827f, 1.0f);
        vec4 quiet = vec4(0.65f, 0.66f, 0.64f, 1.0f);
        vec4 teal = vec4(0.431f, 0.616f, 0.592f, 1.0f);
        vec4 sienna = vec4(0.718f, 0.361f, 0.263f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), carbon, carbonLift, carbon, carbonLift);

        float left = pos.x + 38.0f;
        float right = max.x - 38.0f;
        float centerX = (left + right) * 0.5f;
        float span = (right - left) * 0.5f;
        float railY = pos.y + 137.0f;
        float envelopeTopY = pos.y + 58.0f;
        float safeLeft = centerX - span * safe;
        float safeRight = centerX + span * safe;

        dl.AddRectFilled(vec4(vec2(left, railY - 1.0f), vec2(right - left, 2.0f)), vec4(ivory.x, ivory.y, ivory.z, 0.28f), 0.0f);
        dl.AddRectFilled(vec4(vec2(centerX - 1.0f, envelopeTopY - 8.0f), vec2(2.0f, railY - envelopeTopY + 18.0f)), vec4(ivory.x, ivory.y, ivory.z, 0.22f), 0.0f);

        dl.AddQuadFilled(vec2(centerX, envelopeTopY), vec2(safeLeft, railY), vec2(centerX, railY), vec4(teal.x, teal.y, teal.z, 0.24f));
        dl.AddQuadFilled(vec2(centerX, envelopeTopY), vec2(centerX, railY), vec2(safeRight, railY), vec4(teal.x, teal.y, teal.z, 0.24f));
        dl.AddLine(vec2(centerX, envelopeTopY), vec2(safeLeft, railY), teal, captureFrame == 60 ? 3.0f : 1.5f);
        dl.AddLine(vec2(centerX, envelopeTopY), vec2(safeRight, railY), teal, captureFrame == 60 ? 3.0f : 1.5f);

        float warningStart = centerX + span * safe;
        float warningEnd = right - 12.0f;
        dl.AddQuadFilled(vec2(warningStart, railY), vec2(warningEnd, railY), vec2(warningEnd, railY - 42.0f), vec4(sienna.x, sienna.y, sienna.z, overslip ? 0.72f : 0.20f));
        dl.AddLine(vec2(warningStart, railY - 8.0f), vec2(warningStart, railY + 14.0f), sienna, 2.0f);
        dl.AddText(vec2(warningStart - 19.0f, railY + 31.0f), quiet, "LIMIT");
        dl.AddText(vec2(warningEnd - 76.0f, railY - 64.0f), overslip ? sienna : quiet, "OVERSLIP");
        dl.AddText(vec2(centerX - 55.0f, envelopeTopY + 24.0f), vec4(teal.x, teal.y, teal.z, 0.80f), "SAFE ENVELOPE");

        float markerX = centerX + span * marker;
        vec4 markerColor = overslip ? sienna : ivory;
        dl.AddCircleFilled(vec2(markerX, railY), 3.0f, markerColor, 16);
        dl.AddQuadFilled(vec2(markerX, railY - 17.0f), vec2(markerX - 9.0f, railY - 34.0f), vec2(markerX + 9.0f, railY - 34.0f), markerColor);
        dl.AddLine(vec2(markerX, railY - 14.0f), vec2(markerX, railY + 13.0f), markerColor, 2.0f);
        if (overslip) {
            float tailStart = Math::Max(warningStart, markerX - 66.0f);
            dl.AddLine(vec2(tailStart, railY + 10.0f), vec2(markerX - 6.0f, railY + 10.0f), sienna, 3.0f);
        }

        for (int i = -4; i <= 4; i++) {
            float tickX = centerX + span * float(i) / 4.0f;
            float tickHeight = i == 0 ? 10.0f : 6.0f;
            dl.AddLine(vec2(tickX, railY + 18.0f), vec2(tickX, railY + 18.0f + tickHeight), vec4(ivory.x, ivory.y, ivory.z, 0.34f), 1.0f);
        }
        dl.AddText(vec2(left, railY + 31.0f), quiet, "-100");
        dl.AddText(vec2(centerX - 5.0f, railY + 31.0f), quiet, "0");
        dl.AddText(vec2(right - 32.0f, railY + 31.0f), quiet, "+100");

        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(22);
        dl.AddText(vec2(left, pos.y + 23.0f), ivory, "APEX ENVELOPE");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(right - 150.0f, pos.y + 28.0f), overslip ? sienna : quiet, overslip ? "LIMIT EXCEEDED" : "STEERING LOAD / %");

        float readoutY = pos.y + 213.0f;
        float gap = 22.0f;
        float cellWidth = (right - left - gap * 2.0f) / 3.0f;
        DrawReadout(dl, vec2(left, readoutY), cellWidth, "SIDE", SignedPercent(marker), quiet, markerColor);
        DrawReadout(dl, vec2(left + cellWidth + gap, readoutY), cellWidth, "TARGET", SignedPercent(safe), quiet, teal);
        DrawReadout(dl, vec2(left + (cellWidth + gap) * 2.0f, readoutY), cellWidth, "MARGIN", SignedPercent(margin), quiet, overslip ? sienna : ivory);
        dl.AddLine(vec2(left, readoutY - 18.0f), vec2(right, readoutY - 18.0f), vec4(ivory.x, ivory.y, ivory.z, 0.18f), 1.0f);
        dl.AddLine(vec2(left + cellWidth + gap * 0.5f, readoutY - 8.0f), vec2(left + cellWidth + gap * 0.5f, readoutY + 46.0f), vec4(ivory.x, ivory.y, ivory.z, 0.12f), 1.0f);
        dl.AddLine(vec2(left + cellWidth * 2.0f + gap * 1.5f, readoutY - 8.0f), vec2(left + cellWidth * 2.0f + gap * 1.5f, readoutY + 46.0f), vec4(ivory.x, ivory.y, ivory.z, 0.12f), 1.0f);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · instrument phase = " + Text::Format("%.3f", phase));
        UI::Text("normalized-range rail · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
