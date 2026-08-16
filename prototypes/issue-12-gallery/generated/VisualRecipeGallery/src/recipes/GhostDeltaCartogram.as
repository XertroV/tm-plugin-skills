// GENERATED COPY sha256=d47dc7b9ba6a172c8e3a76bfe93fa379dbb8aaa8f21794a06b57b96288e03e6a source=recipes/GhostDeltaCartogram.as
namespace RecipeGhostDeltaCartogram {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    int RoutePoints() { return 48; }

    // Deterministic closed route: a rounded kidney-circuit in normalized space.
    vec2 RoutePoint(int index) {
        float t = float(index) / float(RoutePoints());
        float a = t * Math::PI * 2.0f;
        float r = 0.62f + 0.16f * Math::Sin(a * 3.0f + 0.7f) + 0.07f * Math::Cos(a * 5.0f);
        return vec2(Math::Cos(a) * r, Math::Sin(a) * r * 0.72f);
    }

    // Signed gain/loss field along the route: positive means the live run is
    // ahead of the ghost at that point. Deterministic, wraps at frame 120.
    float DeltaAt(int index, float phase) {
        float t = float(index) / float(RoutePoints());
        float wave = Math::Sin(t * Math::PI * 4.0f + phase * Math::PI * 2.0f);
        float detail = Math::Sin(t * Math::PI * 14.0f - phase * Math::PI * 4.0f) * 0.35f;
        return (wave + detail) * 0.5f;
    }

    // The live tracer's progress along the route; the ghost sits a fixed
    // offset behind so the pair reads as a chase.
    float TracerProgress(float phase) {
        return phase - Math::Floor(phase);
    }

    int TracerIndex(float phase) {
        return int(TracerProgress(phase) * float(RoutePoints())) % RoutePoints();
    }

    int GhostIndex(float phase) {
        return (TracerIndex(phase) + RoutePoints() - 9) % RoutePoints();
    }

    vec4 GainColor() { return vec4(0.30f, 0.72f, 0.55f, 1.0f); }
    vec4 LossColor() { return vec4(0.82f, 0.38f, 0.30f, 1.0f); }

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
        vec2 center = pos + size * 0.5f + vec2(0.0f, 6.0f);
        float unit = Math::Min(size.x, size.y) * 0.46f;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 deepSea = vec4(0.035f, 0.055f, 0.065f, 1.0f);
        vec4 deepSeaLift = vec4(0.055f, 0.080f, 0.090f, 1.0f);
        vec4 foam = vec4(0.85f, 0.90f, 0.88f, 1.0f);
        vec4 quiet = vec4(0.45f, 0.55f, 0.54f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), deepSea, deepSeaLift, deepSea, deepSeaLift);

        // Header strip.
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(19);
        dl.AddText(vec2(pos.x + 26.0f, pos.y + 18.0f), foam, "GHOST DELTA CARTOGRAM");
        UI::PopFontSize();
        UI::PopFont();
        string session = "BEST vs GHOST";
        vec2 sessionSize = UI::MeasureString(session);
        dl.AddText(vec2(max.x - 26.0f - sessionSize.x, pos.y + 24.0f), quiet, session);

        // Signed delta field: route segments glow gain-green or loss-red with
        // magnitude-driven width; the base line stays a quiet constant.
        for (int i = 0; i < RoutePoints(); i++) {
            int next = (i + 1) % RoutePoints();
            vec2 p0 = center + RoutePoint(i) * unit;
            vec2 p1 = center + RoutePoint(next) * unit;
            float delta = DeltaAt(i, phase);
            float magnitude = Math::Abs(delta);
            vec4 field = delta >= 0.0f ? GainColor() : LossColor();
            field.w = 0.18f + magnitude * 0.55f;
            dl.AddLine(p0, p1, field, 2.0f + magnitude * 7.0f);
        }
        // Crisp center line keeps the route legible over the glow.
        for (int i = 0; i < RoutePoints(); i++) {
            int next = (i + 1) % RoutePoints();
            vec2 p0 = center + RoutePoint(i) * unit;
            vec2 p1 = center + RoutePoint(next) * unit;
            dl.AddLine(p0, p1, vec4(foam.x, foam.y, foam.z, 0.75f), 1.2f);
        }

        // Sector gates: six spokes with signed state at the gate.
        for (int gate = 0; gate < 6; gate++) {
            int at = gate * RoutePoints() / 6;
            vec2 onRoute = center + RoutePoint(at) * unit;
            vec2 outward = RoutePoint(at);
            float outwardLen = outward.Length();
            if (outwardLen > 0.001f) outward = outward / outwardLen;
            float delta = DeltaAt(at, phase);
            vec4 gateColor = delta >= 0.0f ? GainColor() : LossColor();
            dl.AddLine(onRoute, onRoute + outward * 12.0f, vec4(gateColor.x, gateColor.y, gateColor.z, 0.8f), 2.0f);
            dl.AddCircleFilled(onRoute, 3.0f, gateColor, 16);
        }

        // The chase: ghost marker trails, live tracer leads with a pulse ring.
        int ghostAt = GhostIndex(phase);
        int liveAt = TracerIndex(phase);
        vec2 ghostPos = center + RoutePoint(ghostAt) * unit;
        vec2 livePos = center + RoutePoint(liveAt) * unit;
        dl.AddCircleFilled(ghostPos, 6.0f, vec4(foam.x, foam.y, foam.z, 0.20f), 24);
        dl.AddCircleFilled(ghostPos, 3.5f, vec4(foam.x, foam.y, foam.z, 0.55f), 24);
        dl.AddText(ghostPos + vec2(9.0f, -6.0f), vec4(foam.x, foam.y, foam.z, 0.6f), "GHOST");

        float liveDelta = DeltaAt(liveAt, phase);
        vec4 liveColor = liveDelta >= 0.0f ? GainColor() : LossColor();
        dl.AddCircleFilled(livePos, 9.0f, vec4(liveColor.x, liveColor.y, liveColor.z, 0.22f), 28);
        dl.AddCircleFilled(livePos, 5.0f, liveColor, 28);
        dl.AddCircleFilled(livePos, 2.0f, foam, 20);
        dl.AddText(livePos + vec2(11.0f, -6.0f), liveColor, "YOU");

        // Delta readout: signed sum across the field, like a sector board.
        float total = 0.0f;
        for (int i = 0; i < RoutePoints(); i++) total += DeltaAt(i, phase);
        float mean = total / float(RoutePoints());
        string deltaLabel = (mean >= 0.0f ? "AHEAD " : "BEHIND ") + Text::Format("%+.2f", mean * 0.8f) + " S AVG";
        vec4 deltaColor = mean >= 0.0f ? GainColor() : LossColor();
        vec2 deltaSize = UI::MeasureString(deltaLabel);
        vec2 plateMin = vec2((pos.x + max.x) * 0.5f - deltaSize.x * 0.5f - 14.0f, max.y - 40.0f);
        dl.AddRectFilled(vec4(plateMin, vec2(deltaSize.x + 28.0f, deltaSize.y + 12.0f)), vec4(deltaColor.x, deltaColor.y, deltaColor.z, 0.14f), (deltaSize.y + 12.0f) * 0.5f);
        dl.AddText(plateMin + vec2(14.0f, 6.0f), deltaColor, deltaLabel);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · delta phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned gain/loss field · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
