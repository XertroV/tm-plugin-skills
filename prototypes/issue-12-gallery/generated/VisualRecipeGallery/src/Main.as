// GENERATED prototype shell; do not edit. Canonical implementations live in recipes/*.as.
bool g_windowOpen = true;
int g_selectedRecipe = 0;
int g_captureFrame = 0;
uint64 g_lastInterfaceFrame = uint64(-1);

void RenderMenu() {
    if (UI::MenuItem("Visual Recipe Gallery PROTOTYPE", "", g_windowOpen)) g_windowOpen = !g_windowOpen;
}

void RenderInterface() {
    // Openplanet can invoke UI rendering through more than one callback path. Drawing the
    // same ImGui window ID twice in one frame can append a copy of its interior to itself.
    if (g_lastInterfaceFrame == Time::FrameCount) return;
    g_lastInterfaceFrame = Time::FrameCount;
    if (!g_windowOpen) return;
    UI::SetNextWindowSize(780, 560, UI::Cond::FirstUseEver);
    if (UI::Begin("Visual Recipe Gallery PROTOTYPE###skillpack-demo-gallery", g_windowOpen)) DrawGallery();
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
    GalleryTier lastTier = GalleryTier::Advanced;
    bool first = true;
    for (uint i = 0; i < g_recipes.Length; i++) {
        auto recipe = g_recipes[i];
        if (first || recipe.Tier != lastTier) {
            UI::SeparatorText(TierName(recipe.Tier));
            lastTier = recipe.Tier; first = false;
        }
        if (UI::Selectable(recipe.Title + "###recipe-" + recipe.Id, int(i) == g_selectedRecipe)) g_selectedRecipe = int(i);
    }
}

void DrawSelectedRecipe() {
    auto recipe = g_recipes[g_selectedRecipe];
    UI::Text(recipe.Title);
    UI::TextDisabled(recipe.Id + " · " + recipe.Maturity);
    UI::TextWrapped("Expected: " + recipe.Expected);
    UI::TextWrapped("Provenance: " + recipe.Provenance);
    UI::SetNextItemWidth(260);
    g_captureFrame = UI::SliderInt("Deterministic capture frame", g_captureFrame, 0, 120);
    UI::Text("Matrix frames:"); UI::SameLine();
    for (uint i = 0; i < recipe.CaptureFrames.Length; i++) {
        if (i > 0) UI::SameLine();
        int frame = recipe.CaptureFrames[i];
        if (UI::Button(tostring(frame) + "###capture-frame-" + recipe.Id + "-" + i)) g_captureFrame = frame;
    }
    UI::SameLine();
    if (UI::Button("Reset state###reset-state-" + recipe.Id)) g_captureFrame = recipe.CaptureFrames[0];
    UI::Separator();
    DrawRecipeByIndex(g_selectedRecipe, g_captureFrame);
}

string TierName(GalleryTier tier) {
    if (tier == GalleryTier::DefaultImgui) return "1 · Theme-respecting default ImGui";
    if (tier == GalleryTier::Nvg) return "2 · NVG recipes";
    return "3 · Advanced composition (opt-in)";
}
