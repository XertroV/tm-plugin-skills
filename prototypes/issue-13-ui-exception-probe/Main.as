bool g_ThrowInlineOnce = false;
bool g_ThrowIsolatedOnce = false;
uint g_RenderInterfaceCalls = 0;
uint g_RenderCalls = 0;
uint g_LastReportedFrame = 0;

void ThrowProbe(const string &in route) {
    throw("Skillpack UI exception probe via " + route);
}

void ThrowProbeIsolated() {
    ThrowProbe("isolated coroutine");
}

void DrawProbeWindow() {
    UI::SetNextWindowSize(560, 0, UI::Cond::FirstUseEver);
    if (!UI::Begin("UI Exception Probe###skillpack-ui-exception-probe")) {
        UI::End();
        return;
    }

    UI::TextWrapped("DEV-only live probe. Use the isolated button first. The inline button intentionally lets an exception escape the active render callback.");
    UI::Text("RenderInterface calls: " + g_RenderInterfaceCalls);
    UI::Text("Render calls: " + g_RenderCalls);
    UI::Text("Frame: " + Time::FrameCount);

    if (UI::Button("Throw in isolated coroutine###throw-isolated")) {
        g_ThrowIsolatedOnce = true;
    }
    UI::SameLine();
    if (UI::Button("Throw inline in render###throw-inline")) {
        g_ThrowInlineOnce = true;
    }

    if (g_ThrowIsolatedOnce) {
        g_ThrowIsolatedOnce = false;
        startnew(CoroutineFunc(ThrowProbeIsolated));
    }

    if (Time::FrameCount - g_LastReportedFrame >= 120) {
        g_LastReportedFrame = Time::FrameCount;
        trace("SkillpackUiExceptionProbe heartbeat frame=" + Time::FrameCount + " ri=" + g_RenderInterfaceCalls + " r=" + g_RenderCalls);
    }

    if (g_ThrowInlineOnce) {
        g_ThrowInlineOnce = false;
        ThrowProbe("inline render callback");
    }

    UI::End();
}

void RenderInterface() {
    g_RenderInterfaceCalls++;
    DrawProbeWindow();
}

void Render() {
    g_RenderCalls++;
}
