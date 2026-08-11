#if DEV
[Setting hidden]
bool S_Enabled = false;
[Setting hidden]
uint S_Port = 39021;

Net::Socket@ g_Listener;
bool g_WindowOpen = true;

void Main() {
    SemanticControlFixture::RegisterComponents();
    if (S_Enabled) StartLoopbackListener();
}

void StartLoopbackListener() {
    @g_Listener = Net::Socket();
    // Never replace this explicit loopback bind with a wildcard-only overload.
    g_Listener.Listen("127.0.0.1", S_Port);
}

void RenderInterface() {
    SemanticControl::BeginRenderEpoch();
    if (g_WindowOpen) {
        if (UI::Begin("Semantic Control Fixture DEV", g_WindowOpen)) {
            SemanticControlFixture::RenderSaveButton();
            UI::Text("Semantic callbacks: " + SemanticControlFixture::ClickCount);
        }
        UI::End();
    }
    SemanticControl::SealRenderEpoch();
}

void RenderMenu() {
    if (UI::BeginMenu("Skillpack Demos")) {
        if (UI::MenuItem("Semantic Control Fixture DEV", "", g_WindowOpen))
            g_WindowOpen = !g_WindowOpen;
        UI::EndMenu();
    }
}

void OnDestroyed() {
    SemanticControlFixture::TeardownComponents();
    if (g_Listener !is null) g_Listener.Close();
    @g_Listener = null;
}
#else
void Main() {}
#endif
