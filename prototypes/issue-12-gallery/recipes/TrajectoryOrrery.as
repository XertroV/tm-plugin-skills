namespace RecipeTrajectoryOrrery {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    // Deterministic pseudo-3D orbit: each body rides a tilted ring; depth is
    // the sine term before projection, so near/far segmentation is testable.
    vec3 BodyPosition(int body, float phase) {
        float baseAngle = phase * Math::PI * 2.0f + float(body) * Math::PI * 2.0f / 5.0f;
        float tilt = 0.42f + float(body % 3) * 0.17f;
        float radius = 0.38f + float(body) * 0.115f;
        float x = Math::Cos(baseAngle) * radius;
        float y = Math::Sin(baseAngle) * radius;
        // Tilt the ring around the horizontal axis; z carries the depth cue.
        float z = y * Math::Sin(tilt);
        float py = y * Math::Cos(tilt);
        return vec3(x, py, z);
    }

    bool IsNear(int body, float phase) {
        return BodyPosition(body, phase).z >= 0.0f;
    }

    float DepthShade(float z, float radius) {
        // 0 at the far rim, 1 at the near rim.
        return SkillpackDemoLib::ClampUnit(0.5f + 0.5f * z / Math::Max(0.001f, radius));
    }

    float BodyRadius(int body, float phase) {
        vec3 p = BodyPosition(body, phase);
        float shade = DepthShade(p.z, 0.38f + float(body) * 0.115f);
        return 3.0f + shade * 3.5f;
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
        vec2 size = vec2(Math::Max(430.0f, available.x - 16.0f), 310.0f);
        vec2 max = pos + size;
        vec2 center = pos + size * 0.5f;
        float unit = Math::Min(size.x, size.y) * 0.46f;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 void_ = vec4(0.030f, 0.034f, 0.052f, 1.0f);
        vec4 voidLift = vec4(0.048f, 0.054f, 0.078f, 1.0f);
        vec4 starlight = vec4(0.82f, 0.86f, 0.94f, 1.0f);
        vec4 quiet = vec4(0.46f, 0.50f, 0.60f, 1.0f);
        vec4 amber = vec4(0.94f, 0.70f, 0.30f, 1.0f);
        vec4 comet = vec4(0.45f, 0.78f, 0.92f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), void_, voidLift, void_, voidLift);

        // Instrument graticule: cross hairs and degree ticks on the outer rim.
        dl.AddLine(vec2(center.x - unit, center.y), vec2(center.x + unit, center.y), vec4(starlight.x, starlight.y, starlight.z, 0.10f), 1.0f);
        dl.AddLine(vec2(center.x, center.y - unit), vec2(center.x, center.y + unit), vec4(starlight.x, starlight.y, starlight.z, 0.10f), 1.0f);
        for (int tick = 0; tick < 24; tick++) {
            float a = float(tick) / 24.0f * Math::PI * 2.0f;
            float inner = tick % 6 == 0 ? 0.90f : 0.95f;
            vec2 t0 = center + vec2(Math::Cos(a), Math::Sin(a)) * unit * inner;
            vec2 t1 = center + vec2(Math::Cos(a), Math::Sin(a)) * unit;
            dl.AddLine(t0, t1, vec4(starlight.x, starlight.y, starlight.z, tick % 6 == 0 ? 0.40f : 0.18f), 1.0f);
        }

        // Rings: for each ring we walk the segments once, computing position
        // and the near/far split a single time, then emit the far stroke, the
        // dashed guide, and the near stroke for that segment — the split-depth
        // read without tripling the trig. Draw order (far, guide, near) keeps
        // the near stroke visually on top.
        int segments = 72;
        for (int body = 0; body < 5; body++) {
            float tilt = 0.42f + float(body % 3) * 0.17f;
            float radius = 0.38f + float(body) * 0.115f;
            float cosTilt = Math::Cos(tilt);
            float sinTilt = Math::Sin(tilt);
            vec4 base = body == 0 ? comet : quiet;
            for (int s = 0; s < segments; s++) {
                float a0 = float(s) / float(segments) * Math::PI * 2.0f;
                float a1 = float(s + 1) / float(segments) * Math::PI * 2.0f;
                float zMid = Math::Sin((a0 + a1) * 0.5f) * sinTilt;
                bool near = zMid >= 0.0f;
                vec2 p0 = center + vec2(Math::Cos(a0) * radius, Math::Sin(a0) * radius * cosTilt) * unit;
                vec2 p1 = center + vec2(Math::Cos(a1) * radius, Math::Sin(a1) * radius * cosTilt) * unit;
                if (!near) {
                    vec4 far = base; far.w = 0.10f;
                    dl.AddLine(p0, p1, far, 1.0f);
                }
                if (s % 2 == 0) {
                    vec4 guide = base; guide.w = 0.34f;
                    dl.AddLine(p0, p1, guide, 1.0f);
                }
                if (near) {
                    vec4 nearC = base; nearC.w = 0.62f;
                    dl.AddLine(p0, p1, nearC, 2.0f);
                }
            }
        }

        // Primary: a warm core with a measured glow falloff.
        for (int ring = 6; ring >= 1; ring--) {
            float f = float(ring) / 6.0f;
            vec4 glow = amber;
            glow.w = 0.03f + (1.0f - f) * 0.10f;
            dl.AddCircleFilled(center, 12.0f + f * 26.0f, glow, 48);
        }
        dl.AddCircleFilled(center, 13.0f, amber, 48);
        dl.AddCircleFilled(center, 6.0f, vec4(1.0f, 0.95f, 0.82f, 1.0f), 32);

        // Bodies: far bodies behind the primary pass, near bodies in front.
        for (int half = 0; half < 2; half++) {
            for (int body = 0; body < 5; body++) {
                vec3 p = BodyPosition(body, phase);
                bool near = p.z >= 0.0f;
                if ((half == 1) != near) continue;
                float radius = 0.38f + float(body) * 0.115f;
                float shade = DepthShade(p.z, radius);
                vec2 at = center + vec2(p.x, p.y) * unit;
                float bodyR = BodyRadius(body, phase);
                vec4 bodyColor = body == 0 ? comet : Math::Lerp(quiet, starlight, shade);
                // Trail: short arc of recent positions, fading with age.
                for (int trail = 4; trail >= 1; trail--) {
                    vec3 tp = BodyPosition(body, phase - float(trail) * 0.006f);
                    vec2 tAt = center + vec2(tp.x, tp.y) * unit;
                    vec4 trailColor = bodyColor;
                    trailColor.w = 0.05f + (4 - trail) * 0.03f;
                    dl.AddLine(tAt, at, trailColor, bodyR * 0.8f);
                }
                bodyColor.w = 0.55f + shade * 0.45f;
                dl.AddCircleFilled(at, bodyR, bodyColor, 24);
                if (body == 0) {
                    dl.AddCircleFilled(at, bodyR + 3.0f, vec4(comet.x, comet.y, comet.z, 0.25f), 24);
                }
            }
        }

        // Readout plate: designation and a depth legend.
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(19);
        dl.AddText(vec2(pos.x + 26.0f, pos.y + 20.0f), starlight, "TRAJECTORY ORRERY");
        UI::PopFontSize();
        UI::PopFont();
        dl.AddText(vec2(pos.x + 26.0f, pos.y + 48.0f), quiet, "five bodies · tilted rings · split-depth stroke");
        string legend = "NEAR stroke x2  ·  FAR stroke dim  ·  DASHED guide ring";
        vec2 legendSize = UI::MeasureString(legend);
        dl.AddText(vec2((pos.x + max.x) * 0.5f - legendSize.x * 0.5f, max.y - 30.0f), vec4(starlight.x, starlight.y, starlight.z, 0.55f), legend);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · orbital phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned pseudo-3D instrument · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
