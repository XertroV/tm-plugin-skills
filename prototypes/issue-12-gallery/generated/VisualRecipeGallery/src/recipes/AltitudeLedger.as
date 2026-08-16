// GENERATED COPY sha256=9f2f0070c271b669e1d7301895e2a1e23b9ace4e10b1786102051d01c3a205d4 source=recipes/AltitudeLedger.as
namespace RecipeAltitudeLedger {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    int ClimberCount() { return 6; }

    string ClimberTag(int climber) {
        if (climber == 0) return "YOU";
        if (climber == 1) return "AKA";
        if (climber == 2) return "ZED";
        if (climber == 3) return "MIU";
        if (climber == 4) return "REX";
        return "JUN";
    }

    // Deterministic ascent: each climber follows its own speed and wobble so
    // the ladder shuffles order as the frame story advances. Frame 120 wraps.
    float ClimberAltitude(int climber, float phase) {
        float speed = 0.55f + float((climber * 37) % 5) * 0.11f;
        float wobble = Math::Sin(phase * Math::PI * 2.0f * (1.0f + float(climber % 3) * 0.5f) + float(climber) * 1.9f) * 0.05f;
        float altitude = phase * speed + wobble + float(climber) * 0.045f;
        altitude = altitude - Math::Floor(altitude); // wrap inside the course
        return altitude;
    }

    int ClimberRank(int climber, float phase) {
        int rank = 0;
        float own = ClimberAltitude(climber, phase);
        for (int other = 0; other < ClimberCount(); other++) {
            if (other != climber && ClimberAltitude(other, phase) > own) rank++;
        }
        return rank;
    }

    bool IsHero(int climber) { return climber == 0; }

    bool IsFalling(int climber, float phase) {
        // Derivative sign from two nearby samples; deterministic and testable.
        float ahead = ClimberAltitude(climber, phase + 0.004f);
        float here = ClimberAltitude(climber, phase);
        float delta = ahead - here;
        if (delta < -0.5f) delta += 1.0f; // unwrap the course wrap
        return delta < -0.0005f;
    }

    // Collision-managed label rows: rank order plus a minimum vertical gap so
    // tags never overlap, no matter how tight the climb gets.
    float LabelRowY(int rank, float ladderTop, float ladderHeight) {
        return ladderTop + float(rank) * (ladderHeight / float(ClimberCount()));
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
        vec2 size = vec2(Math::Max(420.0f, available.x - 8.0f), 320.0f);
        vec2 max = pos + size;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 parchment = vec4(0.90f, 0.88f, 0.82f, 1.0f);
        vec4 parchmentShade = vec4(0.83f, 0.81f, 0.75f, 1.0f);
        vec4 ink = vec4(0.13f, 0.13f, 0.12f, 1.0f);
        vec4 quietInk = vec4(0.30f, 0.30f, 0.28f, 1.0f);
        vec4 heroAccent = vec4(0.62f, 0.28f, 0.20f, 1.0f);
        vec4 fallingAccent = vec4(0.52f, 0.42f, 0.62f, 1.0f);
        vec4 pbAccent = vec4(0.32f, 0.48f, 0.40f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), parchment, parchmentShade, parchment, parchmentShade);

        // Header: course designation and altitude scale legend.
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(20);
        dl.AddText(vec2(pos.x + 28.0f, pos.y + 18.0f), ink, "ALTITUDE LEDGER");
        UI::PopFontSize();
        UI::PopFont();
        string course = "CORKSCREW HILL CLIMB · 412 M";
        vec2 courseSize = UI::MeasureString(course);
        dl.AddText(vec2(max.x - 26.0f - courseSize.x, pos.y + 24.0f), quietInk, course);

        // The ladder: one vertical axis with elevation ticks and summit flag.
        float ladderX = pos.x + 92.0f;
        float ladderTop = pos.y + 62.0f;
        float ladderH = size.y - 118.0f;
        float ladderBottom = ladderTop + ladderH;
        dl.AddLine(vec2(ladderX, ladderTop), vec2(ladderX, ladderBottom), vec4(ink.x, ink.y, ink.z, 0.55f), 2.0f);
        for (int tick = 0; tick <= 8; tick++) {
            float ty = ladderTop + ladderH * float(tick) / 8.0f;
            bool major = tick % 2 == 0;
            dl.AddLine(vec2(ladderX - (major ? 9.0f : 5.0f), ty), vec2(ladderX + (major ? 9.0f : 5.0f), ty), vec4(ink.x, ink.y, ink.z, major ? 0.55f : 0.30f), 1.0f);
            if (major) {
                string elevation = tostring(int(412.0f * (1.0f - float(tick) / 8.0f)));
                vec2 elevSize = UI::MeasureString(elevation);
                dl.AddText(vec2(ladderX - 16.0f - elevSize.x, ty - elevSize.y * 0.5f), quietInk, elevation);
            }
        }
        // Summit pennant.
        dl.AddLine(vec2(ladderX, ladderTop), vec2(ladderX, ladderTop - 16.0f), ink, 2.0f);
        dl.AddQuadFilled(
            vec2(ladderX, ladderTop - 16.0f),
            vec2(ladderX + 18.0f, ladderTop - 11.0f),
            vec2(ladderX, ladderTop - 6.0f),
            heroAccent
        );

        // Climbers on the ladder: markers rise with altitude; labels are
        // collision-managed into fixed rank rows with connector ticks.
        float labelX = ladderX + 34.0f;
        float rowHeight = ladderH / float(ClimberCount());
        for (int rank = 0; rank < ClimberCount(); rank++) {
            // Find the climber holding this rank.
            int climber = -1;
            for (int c = 0; c < ClimberCount(); c++) {
                if (ClimberRank(c, phase) == rank) { climber = c; break; }
            }
            if (climber < 0) continue;
            float altitude = ClimberAltitude(climber, phase);
            bool hero = IsHero(climber);
            bool falling = IsFalling(climber, phase);
            vec4 accent = hero ? heroAccent : (falling ? fallingAccent : pbAccent);

            float markerY = ladderBottom - altitude * ladderH;
            // Marker: hero gets a filled diamond, others a ring; falling gets a down tick.
            if (hero) {
                dl.AddQuadFilled(
                    vec2(ladderX, markerY - 7.0f),
                    vec2(ladderX + 7.0f, markerY),
                    vec2(ladderX, markerY + 7.0f),
                    accent
                );
            } else {
                dl.AddCircleFilled(vec2(ladderX, markerY), 5.5f, vec4(accent.x, accent.y, accent.z, 0.25f), 20);
                dl.AddCircleFilled(vec2(ladderX, markerY), 3.0f, accent, 20);
            }
            if (falling) {
                dl.AddLine(vec2(ladderX - 8.0f, markerY + 8.0f), vec2(ladderX - 8.0f, markerY + 15.0f), fallingAccent, 2.0f);
                dl.AddLine(vec2(ladderX - 11.0f, markerY + 12.0f), vec2(ladderX - 8.0f, markerY + 15.0f), fallingAccent, 2.0f);
                dl.AddLine(vec2(ladderX - 5.0f, markerY + 12.0f), vec2(ladderX - 8.0f, markerY + 15.0f), fallingAccent, 2.0f);
            }

            // Collision-managed label row: rank row position, never the raw altitude.
            float rowY = LabelRowY(rank, ladderTop, ladderH);
            float labelCenterY = rowY + rowHeight * 0.5f;
            dl.AddLine(vec2(ladderX + 12.0f, markerY), vec2(labelX - 8.0f, labelCenterY), vec4(accent.x, accent.y, accent.z, 0.45f), 1.0f);
            string tag = ClimberTag(climber);
            vec4 tagColor = hero ? heroAccent : (falling ? fallingAccent : ink);
            if (hero) {
                UI::PushFont(UI::Font::DefaultBold);
                dl.AddText(vec2(labelX, labelCenterY - 7.0f), tagColor, tag);
                UI::PopFont();
            } else {
                dl.AddText(vec2(labelX, labelCenterY - 7.0f), tagColor, tag);
            }
            string state = hero ? "on pb pace" : (falling ? "falling" : "holding");
            vec2 statePos = vec2(labelX + 44.0f, labelCenterY - 6.0f);
            dl.AddText(statePos, quietInk, state);
        }

        // Footer legend.
        string legend = "diamond = you · ring = rival · down tick = falling · rows = rank order (no overlap)";
        vec2 legendSize = UI::MeasureString(legend);
        dl.AddText(vec2((pos.x + max.x) * 0.5f - legendSize.x * 0.5f, max.y - 28.0f), vec4(quietInk.x, quietInk.y, quietInk.z, 0.85f), legend);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · ascent phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned altitude ladder · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
