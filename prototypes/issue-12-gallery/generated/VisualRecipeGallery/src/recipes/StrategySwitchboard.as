// GENERATED COPY sha256=a519af631f6d1d686455f19e6a73508249b98d531cd5de3b3fd98f85cd2f5f84 source=recipes/StrategySwitchboard.as
namespace RecipeStrategySwitchboard {
    int clipDepth = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    // Frame story: push, balanced, conserve, overtake, then the loop returns to push.
    int SelectedRoute(int captureFrame) {
        if (captureFrame < 20) return 0;
        if (captureFrame < 50) return 1;
        if (captureFrame < 80) return 2;
        if (captureFrame < 110) return 3;
        return 0;
    }

    string RouteName(int route) {
        if (route == 0) return "PUSH";
        if (route == 1) return "BALANCED";
        if (route == 2) return "CONSERVE";
        return "OVERTAKE";
    }

    string RouteDirective(int route) {
        if (route == 0) return "full send · accept tire debt";
        if (route == 1) return "hold delta · mirror the leader";
        if (route == 2) return "lift early · bank the rubber";
        return "send the inside · spend it all";
    }

    vec4 RouteAccent(int route) {
        if (route == 0) return vec4(0.78f, 0.36f, 0.24f, 1.0f); // ember
        if (route == 1) return vec4(0.87f, 0.73f, 0.42f, 1.0f); // brass
        if (route == 2) return vec4(0.42f, 0.62f, 0.55f, 1.0f); // verdigris
        return vec4(0.55f, 0.44f, 0.72f, 1.0f);                 // iris
    }

    // Rail stop centers; the lever rests on the live route.
    float StopCenter(int stop, float railLeft, float railRight) {
        return railLeft + (railRight - railLeft) * float(stop) / 3.0f;
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
        int selected = SelectedRoute(captureFrame);
        vec2 pos = UI::GetCursorScreenPos();
        vec2 available = UI::GetContentRegionAvail();
        vec2 size = vec2(Math::Max(460.0f, available.x - 8.0f), 300.0f);
        vec2 max = pos + size;
        UI::Dummy(size);

        UI::DrawList@ dl = UI::GetWindowDrawList();
        PushClip(dl, pos, max);

        vec4 slate = vec4(0.085f, 0.095f, 0.105f, 1.0f);
        vec4 slateLift = vec4(0.115f, 0.125f, 0.135f, 1.0f);
        vec4 bone = vec4(0.88f, 0.86f, 0.80f, 1.0f);
        vec4 quiet = vec4(0.55f, 0.56f, 0.53f, 1.0f);

        dl.AddRectFilledMultiColor(vec4(pos, size), slate, slateLift, slate, slateLift);

        // Header strip: title and pit-window readout.
        UI::PushFont(UI::Font::DefaultBold);
        UI::PushFontSize(20);
        dl.AddText(vec2(pos.x + 30.0f, pos.y + 20.0f), bone, "STRATEGY SWITCHBOARD");
        UI::PopFontSize();
        UI::PopFont();
        string windowLabel = "PIT WINDOW  L14–L17";
        vec2 windowSize = UI::MeasureString(windowLabel);
        dl.AddText(vec2(max.x - 30.0f - windowSize.x, pos.y + 26.0f), quiet, windowLabel);
        dl.AddLine(vec2(pos.x + 30.0f, pos.y + 52.0f), vec2(max.x - 30.0f, pos.y + 52.0f), vec4(bone.x, bone.y, bone.z, 0.16f), 1.0f);

        // Tactical matrix: four route cells with hardware rivets.
        float gridLeft = pos.x + 30.0f;
        float gridTop = pos.y + 72.0f;
        float gridW = size.x - 60.0f;
        float cellGap = 10.0f;
        float cellW = (gridW - cellGap) * 0.5f;
        float cellH = 74.0f;
        for (int route = 0; route < 4; route++) {
            float cx = gridLeft + float(route % 2) * (cellW + cellGap);
            float cy = gridTop + float(route / 2) * (cellH + cellGap);
            bool active = route == selected;
            vec4 accent = RouteAccent(route);
            vec4 fill = active ? vec4(accent.x, accent.y, accent.z, 0.20f) : vec4(bone.x, bone.y, bone.z, 0.045f);
            dl.AddRectFilled(vec4(vec2(cx, cy), vec2(cellW, cellH)), fill, 6.0f);
            if (active) {
                dl.AddRectFilled(vec4(vec2(cx, cy), vec2(4.0f, cellH)), accent, 2.0f);
                dl.AddRect(vec4(vec2(cx, cy), vec2(cellW, cellH)), vec4(accent.x, accent.y, accent.z, 0.85f), 6.0f, 1.5f);
            }
            dl.AddText(vec2(cx + 16.0f, cy + 12.0f), active ? bone : quiet, RouteName(route));
            dl.AddText(vec2(cx + 16.0f, cy + 42.0f), active ? accent : vec4(quiet.x, quiet.y, quiet.z, 0.7f), RouteDirective(route));
            dl.AddCircleFilled(vec2(cx + cellW - 12.0f, cy + 12.0f), 2.0f, active ? accent : vec4(bone.x, bone.y, bone.z, 0.25f), 10);
        }

        // Toggle rail below the matrix: a weighted lever rests on the live route.
        float railY = gridTop + cellH * 2.0f + cellGap + 34.0f;
        float railLeft = gridLeft + 12.0f;
        float railRight = gridLeft + gridW - 12.0f;
        dl.AddLine(vec2(railLeft, railY), vec2(railRight, railY), vec4(bone.x, bone.y, bone.z, 0.22f), 3.0f);
        for (int stop = 0; stop < 4; stop++) {
            float sx = StopCenter(stop, railLeft, railRight);
            bool live = stop == selected;
            vec4 accent = RouteAccent(stop);
            dl.AddLine(vec2(sx, railY - 7.0f), vec2(sx, railY + 7.0f), live ? accent : vec4(bone.x, bone.y, bone.z, 0.35f), live ? 2.5f : 1.0f);
            if (live) {
                dl.AddCircleFilled(vec2(sx, railY), 9.0f, vec4(accent.x, accent.y, accent.z, 0.28f), 24);
                dl.AddCircleFilled(vec2(sx, railY), 5.0f, accent, 24);
                dl.AddCircleFilled(vec2(sx, railY), 2.0f, bone, 16);
            }
        }

        // Directive plate: the selected route read out in measured type.
        float plateY = railY + 26.0f;
        string directive = RouteName(selected) + "  —  " + RouteDirective(selected);
        vec2 directiveSize = UI::MeasureString(directive);
        vec2 plateMin = vec2((pos.x + max.x) * 0.5f - directiveSize.x * 0.5f - 18.0f, plateY - 6.0f);
        vec2 plateSize = vec2(directiveSize.x + 36.0f, directiveSize.y + 12.0f);
        vec4 accent = RouteAccent(selected);
        dl.AddRectFilled(vec4(plateMin, plateSize), vec4(accent.x, accent.y, accent.z, 0.14f), plateSize.y * 0.5f);
        dl.AddRect(vec4(plateMin, plateSize), vec4(accent.x, accent.y, accent.z, 0.6f), plateSize.y * 0.5f, 1.0f);
        dl.AddText(plateMin + vec2(18.0f, 6.0f), bone, directive);

        PopClip(dl);
        UI::Text("animation-state frame = " + captureFrame + " · route phase = " + Text::Format("%.3f", phase));
        UI::Text("capture-owned decision matrix · clip-depth = " + clipDepth + " · no wall-clock state");
    }
}
