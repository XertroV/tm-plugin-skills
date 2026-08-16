// GENERATED prototype shell; do not edit. Canonical implementations live in recipes/*.as.
bool g_windowOpen = true;
int g_selectedRecipe = 7;
int g_captureFrame = 0;
bool g_animationPlaying = true;
uint64 g_lastAnimationTick = 0;
float g_animationFrameCarry = 0.0f;

void RenderMenu() {
    // SkillpackDemoLib is the sole Plugins-menu owner.
}

bool GalleryMenuIsOpen() { return g_windowOpen; }
void ToggleGalleryMenu() { g_windowOpen = !g_windowOpen; }

void Main() {
    SkillpackDemoLib::RegisterMenuItem("visual-recipe-gallery", "Visual Recipe Gallery PROTOTYPE", GalleryMenuIsOpen, ToggleGalleryMenu);
    RegisterGalleryCapturePack();
}

void OnDestroyed() {
    SkillpackDemoLib::UnregisterMenuItem("visual-recipe-gallery");
    UnregisterGalleryCapturePack();
}

void OnEnabled() {
    RegisterGalleryCapturePack();
}

void OnDisabled() {
    UnregisterGalleryCapturePack();
}

// Live-capture bridge: lets the local tm-control-mcp bridge select recipes,
// pin deterministic frames, and report window geometry for screenshot review.
// Registrations are removed on disable/teardown so reloads never go stale.
string g_capturePackId = "";

Json::Value@ GalleryCaptureOk(Json::Value@ output) {
    Json::Value r = Json::Object();
    r["success"] = true;
    r["output"] = output;
    return r;
}

Json::Value@ GalleryCaptureErr(const string &in msg) {
    Json::Value r = Json::Object();
    r["success"] = false;
    r["error"] = msg;
    return r;
}

Json::Value@ GalleryCaptureState() {
    Json::Value o = Json::Object();
    o["windowOpen"] = g_windowOpen;
    o["selectedIndex"] = g_selectedRecipe;
    o["captureFrame"] = g_captureFrame;
    o["animationPlaying"] = g_animationPlaying;
    if (g_selectedRecipe >= 0 && g_selectedRecipe < int(g_recipes.Length)) {
        o["recipe"] = g_recipes[g_selectedRecipe].Id;
    }
    Json::Value ids = Json::Array();
    for (uint i = 0; i < g_recipes.Length; i++) ids.Add(g_recipes[i].Id);
    o["recipes"] = ids;
    o["windowPos"] = g_lastWindowPos.x + "," + g_lastWindowPos.y;
    o["windowSize"] = g_lastWindowSize.x + "," + g_lastWindowSize.y;
    return o;
}

Json::Value@ GalleryCaptureDispatch(const string &in name, Json::Value &in input) {
    if (name == "GetState") return GalleryCaptureOk(GalleryCaptureState());
    if (name == "SelectRecipe") {
        string id = input.HasKey("id") ? string(input["id"]) : "";
        for (uint i = 0; i < g_recipes.Length; i++) {
            if (g_recipes[i].Id == id) {
                g_selectedRecipe = int(i);
                g_animationPlaying = false;
                return GalleryCaptureOk(GalleryCaptureState());
            }
        }
        return GalleryCaptureErr("unknown recipe id: " + id);
    }
    if (name == "SetFrame") {
        if (!input.HasKey("frame")) return GalleryCaptureErr("SetFrame requires {frame}");
        g_captureFrame = int(input["frame"]);
        g_animationPlaying = input.HasKey("playing") ? bool(input["playing"]) : false;
        g_lastAnimationTick = 0;
        return GalleryCaptureOk(GalleryCaptureState());
    }
    if (name == "SetWindowOpen") {
        g_windowOpen = !input.HasKey("open") || bool(input["open"]);
        return GalleryCaptureOk(GalleryCaptureState());
    }
    if (name == "PinWindow") {
        // Move the gallery to a known anchor for deterministic capture. The
        // position is applied next frame via SetNextWindowPos(Always).
        g_pinWindow = true;
        g_pinPos = vec2(
            input.HasKey("x") ? float(input["x"]) : 40.0f,
            input.HasKey("y") ? float(input["y"]) : 60.0f
        );
        return GalleryCaptureOk(GalleryCaptureState());
    }
    return GalleryCaptureErr("unknown gallery capture tool: " + name);
}

void RegisterGalleryCapturePack() {
    auto plugin = Meta::ExecutingPlugin();
    if (plugin is null) return;
    auto tmMcp = Meta::GetPluginFromID("tm-control-mcp");
    if (tmMcp is null || !tmMcp.Enabled) return; // bridge absent: gallery still works by hand
    g_capturePackId = plugin.ID;
    auto b = TmMcp::ToolPackBuilder();
    b.AddTool("GetState", "Gallery capture state: window, selection, frame, geometry.", '{"type":"object","properties":{},"additionalProperties":false}');
    b.AddTool("SelectRecipe", "Select a gallery recipe by id and pause animation.", '{"type":"object","properties":{"id":{"type":"string"}},"required":["id"],"additionalProperties":false}');
    b.AddTool("SetFrame", "Pin the deterministic capture frame; {frame:int, playing?:bool}.", '{"type":"object","properties":{"frame":{"type":"integer"},"playing":{"type":"boolean"}},"required":["frame"],"additionalProperties":false}');
    b.AddTool("SetWindowOpen", "Open or close the gallery window; {open?:bool default true}.", '{"type":"object","properties":{"open":{"type":"boolean"}},"additionalProperties":false}');
    b.AddTool("PinWindow", "Pin the gallery window to a known anchor for deterministic capture; {x?:float, y?:float}.", '{"type":"object","properties":{"x":{"type":"number"},"y":{"type":"number"}},"additionalProperties":false}');
    b.SetDispatch(GalleryCaptureDispatch);
    TmMcp::RegisterToolPack(b);
}

void UnregisterGalleryCapturePack() {
    if (g_capturePackId.Length == 0) return;
    auto tmMcp = Meta::GetPluginFromID("tm-control-mcp");
    if (tmMcp !is null) TmMcp::UnregisterToolPack(g_capturePackId);
    g_capturePackId = "";
}

void RenderInterface() {
    DrawGalleryWindow();
}

void Render() {
    // RenderInterface owns the normal Openplanet-overlay path. Only use Render for the
    // optional HUD-like path while the overlay is hidden; otherwise the same ImGui window
    // ID is submitted twice and its interior can appear duplicated.
    if (UI::IsOverlayShown()) return;
    DrawGalleryWindow();
}

vec2 g_lastWindowPos = vec2(0.0f, 0.0f);
vec2 g_lastWindowSize = vec2(0.0f, 0.0f);
bool g_pinWindow = false;
vec2 g_pinPos = vec2(40.0f, 60.0f);

void DrawGalleryWindow() {
    if (!g_windowOpen) return;
    if (g_pinWindow) {
        UI::SetNextWindowPos(int(g_pinPos.x), int(g_pinPos.y), UI::Cond::Always);
    }
    UI::SetNextWindowSize(1280, 900, UI::Cond::FirstUseEver);
    UI::SetNextWindowSizeConstraints(1000, 650, 1800, 1200);
    if (UI::Begin("Visual Recipe Gallery PROTOTYPE###skillpack-demo-gallery", g_windowOpen)) {
        g_lastWindowPos = UI::GetWindowPos();
        g_lastWindowSize = UI::GetWindowSize();
        DrawGallery();
    }
    UI::End();
}

void DrawGallery() {
    UI::TextWrapped("THROWAWAY / STATIC-ONLY: no recipe shown here is stable until live screenshot gates pass.");
    UI::Separator();
    if (UI::BeginTable("gallery-layout", 2, UI::TableFlags::SizingStretchProp | UI::TableFlags::BordersInnerV)) {
        UI::TableSetupColumn("Navigation", UI::TableColumnFlags::WidthFixed, 230);
        UI::TableSetupColumn("Recipe", UI::TableColumnFlags::WidthStretch);
        UI::TableNextRow();
        UI::TableNextColumn(); DrawNavigation();
        UI::TableNextColumn(); DrawSelectedRecipe();
        UI::EndTable();
    }
}

void DrawNavigation() {
    UI::BeginTabBar("gallery-curation-tabs");
    if (UI::BeginTabItem("Featured")) {
            DrawNavigationForCuration(true);
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Boring")) {
            DrawNavigationForCuration(false);
            UI::EndTabItem();
        }
    UI::EndTabBar();
}

void DrawNavigationForCuration(bool featured) {
    EnsureSelectionMatchesCuration(featured);
    GalleryTier lastTier = GalleryTier::Advanced;
    bool first = true;
    for (uint i = 0; i < g_recipes.Length; i++) {
        auto recipe = g_recipes[i];
        if (recipe.IsFeatured != featured) continue;
        if (first || recipe.Tier != lastTier) {
            UI::SeparatorText(TierName(recipe.Tier));
            lastTier = recipe.Tier; first = false;
        }
        if (UI::Selectable(recipe.Title + "###recipe-" + recipe.Id, int(i) == g_selectedRecipe)) g_selectedRecipe = int(i);
    }
}

void EnsureSelectionMatchesCuration(bool featured) {
    if (g_selectedRecipe >= 0 && g_selectedRecipe < int(g_recipes.Length)
            && g_recipes[g_selectedRecipe].IsFeatured == featured) return;
    for (uint i = 0; i < g_recipes.Length; i++) {
        if (g_recipes[i].IsFeatured == featured) {
            g_selectedRecipe = int(i);
            g_captureFrame = g_recipes[i].CaptureFrames[0];
            g_animationPlaying = true;
            g_lastAnimationTick = 0;
            return;
        }
    }
}

void DrawSelectedRecipe() {
    auto recipe = g_recipes[g_selectedRecipe];
    AdvanceAnimationFrame(recipe);
    UI::Text(recipe.Title);
    UI::TextDisabled(recipe.Id + " · " + recipe.Maturity);
    UI::TextWrapped("Expected: " + recipe.Expected);
    UI::TextWrapped("Provenance: " + recipe.Provenance);
    UI::SetNextItemWidth(260);
    int chosenFrame = UI::SliderInt("Deterministic capture frame", g_captureFrame, 0, 120);
    if (chosenFrame != g_captureFrame) {
        g_captureFrame = chosenFrame;
        g_animationPlaying = false;
    }
    if (recipe.IsAnimated) {
        UI::SameLine();
        if (UI::Button((g_animationPlaying ? "Pause animation" : "Play animation") + "###animation-play-state-" + recipe.Id)) {
            g_animationPlaying = !g_animationPlaying;
            g_lastAnimationTick = 0;
        }
    }
    UI::Text("Matrix frames:"); UI::SameLine();
    for (uint i = 0; i < recipe.CaptureFrames.Length; i++) {
        if (i > 0) UI::SameLine();
        int frame = recipe.CaptureFrames[i];
        if (UI::Button(tostring(frame) + "###capture-frame-" + recipe.Id + "-" + i)) {
            g_captureFrame = frame;
            g_animationPlaying = false;
        }
    }
    UI::SameLine();
    if (UI::Button("Return to frame 0###reset-state-" + recipe.Id)) {
        g_captureFrame = recipe.CaptureFrames[0];
        g_animationPlaying = recipe.IsAnimated;
        g_lastAnimationTick = 0;
    }
    UI::Separator();
    DrawRecipeByIndex(g_selectedRecipe, g_captureFrame);
}

void AdvanceAnimationFrame(RecipeMeta@ recipe) {
    if (!recipe.IsAnimated || !g_animationPlaying) {
        g_lastAnimationTick = 0;
        return;
    }
    uint64 now = Time::Now;
    if (g_lastAnimationTick == 0) {
        g_lastAnimationTick = now;
        return;
    }
    uint64 elapsed = now - g_lastAnimationTick;
    g_lastAnimationTick = now;
    g_animationFrameCarry += float(Math::Min(elapsed, uint64(250))) * 30.0f / 1000.0f;
    int wholeFrames = int(Math::Floor(g_animationFrameCarry));
    if (wholeFrames > 0) {
        g_captureFrame = (g_captureFrame + wholeFrames) % 121;
        g_animationFrameCarry -= float(wholeFrames);
    }
}

string TierName(GalleryTier tier) {
    if (tier == GalleryTier::DefaultImgui) return "1 · Theme-respecting default ImGui";
    if (tier == GalleryTier::Nvg) return "2 · NVG recipes";
    return "3 · Advanced composition (opt-in)";
}
