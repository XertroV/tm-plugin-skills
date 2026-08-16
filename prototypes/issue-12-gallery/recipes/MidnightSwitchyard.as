namespace RecipeMidnightSwitchyard {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    int NodeCount() { return 7; }

    // Branching rail: node positions in normalized space (x right, y down).
    vec2 NodePos(int node) {
        if (node == 0) return vec2(0.08f, 0.50f); // yard throat
        if (node == 1) return vec2(0.30f, 0.26f); // north branch
        if (node == 2) return vec2(0.30f, 0.74f); // south branch
        if (node == 3) return vec2(0.55f, 0.18f); // north siding
        if (node == 4) return vec2(0.55f, 0.50f); // central junction
        if (node == 5) return vec2(0.55f, 0.82f); // south siding
        return vec2(0.86f, 0.50f);                // terminus
    }

    int EdgeCount() { return 7; }

    void EdgeEnds(int edge, int &out from, int &out to) {
        if (edge == 0) { from = 0; to = 1; }
        else if (edge == 1) { from = 0; to = 2; }
        else if (edge == 2) { from = 1; to = 3; }
        else if (edge == 3) { from = 1; to = 4; }
        else if (edge == 4) { from = 2; to = 4; }
        else if (edge == 5) { from = 2; to = 5; }
        else { from = 4; to = 6; }
    }

    // Signal propagation: a wave departs the throat and travels the yard;
    // each node energizes when the wave crosses its distance. Wraps at 120.
    float NodeDistance(int node) {
        // Hand-tuned graph distances from the throat for wave timing.
        if (node == 0) return 0.00f;
        if (node == 1) return 0.25f;
        if (node == 2) return 0.25f;
        if (node == 3) return 0.52f;
        if (node == 4) return 0.50f;
        if (node == 5) return 0.52f;
        return 0.80f;
    }

    float NodeEnergy(int node, float phase) {
        float wave = phase * 1.0f; // one full crossing per loop
        float arrival = NodeDistance(node);
        float t = wave - arrival;
        if (t < 0.0f) return 0.0f;
        if (t > 0.22f) return Math::Max(0.0f, 1.0f - (t - 0.22f) * 5.0f); // decay after the crest
        return t / 0.22f; // attack
    }

    float EdgeEnergy(int edge, float phase) {
        int from, to;
        EdgeEnds(edge, from, to);
        return Math::Min(NodeEnergy(from, phase), NodeEnergy(to, phase)) + Math::Abs(NodeEnergy(from, phase) - NodeEnergy(to, phase)) * 0.5f;
    }

    bool IsSwitchOpen(int node, float phase) {
        // Junctions physically swing open while energized.
        return NodeEnergy(node, phase) > 0.45f;
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
        vec2 origin = pos + vec2(26.0f, 44.0f);
        vec2 field = vec2(size.x - 52.0f, size.y - 104.0f);
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 midnight = vec4(0.045f, 0.052f, 0.085f, 1.0f);
        vec4 midnightLift = vec4(0.065f, 0.075f, 0.115f, 1.0f);
        vec4 rail = vec4(0.62f, 0.68f, 0.82f, 1.0f);
        vec4 quiet = vec4(0.42f, 0.47f, 0.60f, 1.0f);
        vec4 signal = vec4(0.95f, 0.75f, 0.30f, 1.0f);
        vec4 lantern = vec4(0.55f, 0.85f, 0.70f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), midnight, midnightLift, midnight, midnightLift);

        // Header: yard designation and clock.
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(19);
        dl.AddText(vec2(pos.x + 26.0f, pos.y + 16.0f), rail, "MIDNIGHT SWITCHYARD");
        UI::PopFontSize();
        UI::PopFont();
        string clock = "SIGNAL WAVE " + Text::Format("%03d", captureFrame) + " / 120";
        vec2 clockSize = UI::MeasureString(clock);
        dl.AddText(vec2(max.x - 26.0f - clockSize.x, pos.y + 22.0f), quiet, clock);

        // Ballast grid: faint survey lines ground the diagram.
        for (int gx = 0; gx <= 8; gx++) {
            float x = origin.x + field.x * float(gx) / 8.0f;
            dl.AddLine(vec2(x, origin.y), vec2(x, origin.y + field.y), vec4(rail.x, rail.y, rail.z, 0.05f), 1.0f);
        }
        for (int gy = 0; gy <= 4; gy++) {
            float y = origin.y + field.y * float(gy) / 4.0f;
            dl.AddLine(vec2(origin.x, y), vec2(origin.x + field.x, y), vec4(rail.x, rail.y, rail.z, 0.05f), 1.0f);
        }

        // Rails: base track first, then the energized glow over it.
        for (int pass = 0; pass < 2; pass++) {
            for (int edge = 0; edge < EdgeCount(); edge++) {
                int from, to;
                EdgeEnds(edge, from, to);
                vec2 a = origin + NodePos(from) * field;
                vec2 b = origin + NodePos(to) * field;
                if (pass == 0) {
                    dl.AddLine(a, b, vec4(rail.x, rail.y, rail.z, 0.35f), 2.0f);
                    // Sleepers along the rail sell the rail-yard read.
                    int sleepers = 6;
                    vec2 dir = b - a;
                    float len = dir.Length();
                    if (len > 1.0f) {
                        vec2 norm = vec2(-dir.y, dir.x) / len;
                        for (int s = 1; s < sleepers; s++) {
                            vec2 at = a + dir * (float(s) / float(sleepers));
                            dl.AddLine(at - norm * 4.0f, at + norm * 4.0f, vec4(rail.x, rail.y, rail.z, 0.18f), 1.5f);
                        }
                    }
                } else {
                    float energy = EdgeEnergy(edge, phase);
                    if (energy > 0.03f) {
                        dl.AddLine(a, b, vec4(signal.x, signal.y, signal.z, energy * 0.85f), 1.0f + energy * 3.5f);
                    }
                }
            }
        }

        // Nodes: switches with physical blades; sidings with lantern dots.
        for (int node = 0; node < NodeCount(); node++) {
            vec2 at = origin + NodePos(node) * field;
            float energy = NodeEnergy(node, phase);
            bool open = IsSwitchOpen(node, phase);
            // Lantern halo while energized.
            if (energy > 0.05f) {
                dl.AddCircleFilled(at, 8.0f + energy * 7.0f, vec4(signal.x, signal.y, signal.z, energy * 0.20f), 24);
            }
            dl.AddCircleFilled(at, 4.0f, vec4(rail.x, rail.y, rail.z, 0.85f), 20);
            dl.AddCircleFilled(at, 2.0f, open ? signal : midnight, 16);
            // Switch blade: a short lever that swings toward the open route.
            if (node == 1 || node == 2 || node == 4) {
                float swing = open ? 1.0f : -1.0f;
                vec2 bladeDir = vec2(0.94f, 0.34f * swing);
                vec2 bladeEnd = at + bladeDir * 13.0f;
                dl.AddLine(at, bladeEnd, open ? signal : vec4(rail.x, rail.y, rail.z, 0.6f), 2.5f);
                dl.AddCircleFilled(bladeEnd, 2.5f, open ? signal : quiet, 12);
            }
        }

        // Terminus lantern: a steady harbor light the wave arrives at.
        vec2 terminus = origin + NodePos(6) * field;
        float terminusEnergy = NodeEnergy(6, phase);
        dl.AddCircleFilled(terminus + vec2(20.0f, -18.0f), 3.0f, lantern, 16);
        if (terminusEnergy > 0.2f) {
            dl.AddCircleFilled(terminus + vec2(20.0f, -18.0f), 8.0f, vec4(lantern.x, lantern.y, lantern.z, terminusEnergy * 0.3f), 20);
            dl.AddText(terminus + vec2(28.0f, -24.0f), lantern, "ARRIVED");
        } else {
            dl.AddText(terminus + vec2(28.0f, -24.0f), quiet, "AWAITING");
        }

        // Legend strip.
        string legend = "amber = signal wave · blade = switch state · halo = energized block";
        vec2 legendSize = UI::MeasureString(legend);
        dl.AddText(vec2((pos.x + max.x) * 0.5f - legendSize.x * 0.5f, max.y - 26.0f), vec4(rail.x, rail.y, rail.z, 0.55f), legend);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · wave phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned rail diagram · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
