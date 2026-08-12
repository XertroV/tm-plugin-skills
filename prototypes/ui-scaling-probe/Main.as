#if SKILLPACK_SCALING_PROBE
bool g_ScalingProbeOpen = true;
bool g_LogNextFrame = true;

string V2(const vec2 &in value) {
    return "(" + Text::Format("%.2f", value.x) + ", " + Text::Format("%.2f", value.y) + ")";
}

string V4(const vec4 &in value) {
    return "(" + Text::Format("%.2f", value.x) + ", " + Text::Format("%.2f", value.y)
        + ", " + Text::Format("%.2f", value.z) + ", " + Text::Format("%.2f", value.w) + ")";
}

bool ScalingProbeMenuIsOpen() { return g_ScalingProbeOpen; }
void ToggleScalingProbeMenu() { g_ScalingProbeOpen = !g_ScalingProbeOpen; }
void Main() { SkillpackDemoLib::RegisterMenuItem("ui-scaling-probe", "UI Scaling Probe", ScalingProbeMenuIsOpen, ToggleScalingProbeMenu); }
void OnDestroyed() { SkillpackDemoLib::UnregisterMenuItem("ui-scaling-probe"); }

void RenderInterface() {
    if (!g_ScalingProbeOpen) return;

    float scale = UI::GetScale();
    UI::SetNextWindowSize(760, 700, UI::Cond::FirstUseEver);
    if (!UI::Begin("UI Scaling Probe###skillpack-ui-scaling-probe", g_ScalingProbeOpen)) {
        UI::End();
        return;
    }

    vec2 windowPos = UI::GetWindowPos();
    vec2 windowSize = UI::GetWindowSize();
    vec2 cursorLocal = UI::GetCursorPos();
    vec2 cursorScreen = UI::GetCursorScreenPos();
    vec2 contentAvail = UI::GetContentRegionAvail();
    vec2 mousePos = UI::GetMousePos();
    float frameHeight = UI::GetFrameHeight();
    vec2 measured100 = UI::MeasureString("MMMMMMMMMM");

    UI::Text("Change Openplanet UI scale, then compare this window without reloading.");
    UI::Text("UI::GetScale = " + Text::Format("%.3f", scale));
    UI::Text("Display = " + Display::GetWidth() + " x " + Display::GetHeight());
    UI::Text("window pos = " + V2(windowPos) + " size = " + V2(windowSize));
    UI::Text("cursor local = " + V2(cursorLocal) + " absolute = " + V2(cursorScreen));
    UI::Text("content avail = " + V2(contentAvail));
    UI::Text("mouse = " + V2(mousePos));
    UI::Text("frame height = " + Text::Format("%.2f", frameHeight) + " measured text = " + V2(measured100));

    if (UI::Button("Log current measurements###log-scale-probe")) g_LogNextFrame = true;

    UI::SeparatorText("100-unit item boundary");
    UI::Text("SetNextItemWidth(100)");
    UI::SetNextItemWidth(100);
    UI::InputText("###logical-100", "");
    vec4 logicalRect = UI::GetItemRect();
    UI::Text("item rect = " + V4(logicalRect));

    UI::Text("SetNextItemWidth(100 / scale)");
    UI::SetNextItemWidth(100.0f / scale);
    UI::InputText("###physical-100", "");
    vec4 physicalRect = UI::GetItemRect();
    UI::Text("item rect = " + V4(physicalRect));

    UI::SeparatorText("Content width round trip");
    float measuredAvail = UI::GetContentRegionAvail().x;
    UI::SetNextItemWidth(measuredAvail / scale);
    UI::InputText("###avail-roundtrip", "");
    vec4 availRect = UI::GetItemRect();
    UI::Text("measured avail = " + Text::Format("%.2f", measuredAvail) + " result width = " + Text::Format("%.2f", availRect.z));

    UI::SeparatorText("Draw-list alignment");
    vec2 drawOrigin = UI::GetCursorScreenPos();
    vec2 designSize = vec2(100.0f, 28.0f);
    UI::Dummy(designSize);
    vec4 dummyRect = UI::GetItemRect();
    UI::DrawList@ dl = UI::GetWindowDrawList();
    dl.AddRect(dummyRect, vec4(0.20f, 0.85f, 1.0f, 1.0f), 3.0f, 2.0f);
    dl.AddRect(vec4(drawOrigin, designSize * scale), vec4(1.0f, 0.25f, 0.55f, 0.80f), 3.0f, 1.0f);
    UI::Text("cyan = measured Dummy rect; magenta = cursor origin + logical size * scale");

    UI::SeparatorText("Table fixed-width boundary");
    if (UI::BeginTable("scale-probe-table", 3, UI::TableFlags::Borders)) {
        UI::TableSetupColumn("raw 100", UI::TableColumnFlags::WidthFixed, 100.0f);
        UI::TableSetupColumn("100 * scale", UI::TableColumnFlags::WidthFixed, 100.0f * scale);
        UI::TableSetupColumn("stretch", UI::TableColumnFlags::WidthStretch);
        UI::TableHeadersRow();
        UI::TableNextRow();
        UI::TableNextColumn(); UI::Text("A");
        UI::TableNextColumn(); UI::Text("B");
        UI::TableNextColumn(); UI::Text("C");
        UI::EndTable();
    }

    if (g_LogNextFrame) {
        g_LogNextFrame = false;
        trace("SCALE_PROBE scale=" + Text::Format("%.3f", scale)
            + " display=" + Display::GetWidth() + "x" + Display::GetHeight()
            + " windowPos=" + V2(windowPos) + " windowSize=" + V2(windowSize)
            + " cursorLocal=" + V2(cursorLocal) + " cursorScreen=" + V2(cursorScreen)
            + " contentAvail=" + V2(contentAvail) + " mouse=" + V2(mousePos)
            + " frameHeight=" + Text::Format("%.2f", frameHeight)
            + " logical100Rect=" + V4(logicalRect)
            + " physical100Rect=" + V4(physicalRect)
            + " availRect=" + V4(availRect)
            + " dummyRect=" + V4(dummyRect));
    }

    UI::End();
}
#endif
